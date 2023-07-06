//
//  MKHookAjaxHandler.m
//  webFast
//
//  Created by zhengmiaokai on 2023/4/14.
//

#import "MKHookAjaxHandler.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/runtime.h>
#import "MKWebFastUtils.h"
#import "MKWebBridgeMessage.h"
#import "MKCookieSynchronizer.h"
#import "MKAjaxBodyStorage.h"

static NSString * const MKWebFastJSBridgeName = @"webFast_JSBridge";

@interface MKHookAjaxHandler () {
    BOOL _isAvailable;
}

@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, assign) BOOL bridgeReady;

@end

@implementation MKHookAjaxHandler

- (instancetype)initWithWebView:(WKWebView *)webView {
    self = [super init];
    if (self) {
        self.webView = webView;
        
        [self addUserScript]; // 注入JS脚本
        [self addScriptMessageHandler]; // 注入JSBridge
     }
    return self;
}

- (void)addUserScript {
    WKWebViewConfiguration *webViewConfiguration = self.webView.configuration;
    if (webViewConfiguration && !webViewConfiguration.userContentController) {
        self.webView.configuration.userContentController = [WKUserContentController new];
    }
    
    NSString *javascriptCode = [[NSString alloc] initWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:@"MKWebFastHookAjax" ofType:@"js"] encoding:NSUTF8StringEncoding error:NULL];
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:javascriptCode injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [self.webView.configuration.userContentController addUserScript:userScript];
}

- (void)addScriptMessageHandler {
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:MKWebFastJSBridgeName];
    [self.webView.configuration.userContentController addScriptMessageHandler:self name:MKWebFastJSBridgeName];
}

- (void)startAjaxHook {
    NSString *script = [NSString stringWithFormat:@"window.WFJSBridgeConfig.enableAjaxHook(%@)", [NSNumber numberWithBool:YES]];
    [self evaluateJavaScript:script];
}

#pragma mark - WKScriptMessageHandler -
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:MKWebFastJSBridgeName]) {
        NSDictionary *messageBody = [NSDictionary dictionaryWithDictionary:message.body];
        MKWebBridgeMessage *bridgeMessage = [MKWebBridgeMessage mj_objectWithKeyValues:messageBody];
        if ([bridgeMessage.module isEqualToString:MKWebBridgeLifeCycleModule]) {
            if ([bridgeMessage.method isEqualToString:MKWebBridgeReadyMethod]) {
                // JSBridge准备就绪
                if (!self.bridgeReady) {
                    self.bridgeReady = YES;
                }
            }
        } else if ([bridgeMessage.module isEqualToString:MKWebBridgeCookieModule]) {
            if ([bridgeMessage.method isEqualToString:MKWebBridgeSetCookieMethod]) {
                // 同步cookie数据
                [MKCookieSynchronizer setCookieWithMessageBody:bridgeMessage.data];
            }
        } else if ([bridgeMessage.module isEqualToString:MKWebBridgeAjaxModule]) {
            if ([bridgeMessage.method isEqualToString:MKWebBridgeCacheAjaxBodyMethod]) {
                // 同步ajax数据
                [[MKAjaxBodyStorage sharedInstance] setAjaxBody:bridgeMessage.data];
                
                // 数据同步后通知JS端
                [self executeMessageResponse:bridgeMessage];
            }
        }
    }
}

- (void)executeMessageResponse:(MKWebBridgeMessage *)bridgeMessage {
    MKWebBridgeCallback *bridgeCallback = [[MKWebBridgeCallback alloc] init];
    bridgeCallback.messageType = MKWebBridgeCallbackType;
    bridgeCallback.callbackId = bridgeMessage.callbackId;
    bridgeCallback.data = @{@"requestId": [bridgeMessage.data wfStringForKey:@"requestId"], @"requestUrl": [bridgeMessage.data wfStringForKey:@"requestUrl"]};
    
    NSString *javaScriptCode = [NSString stringWithFormat:@"%@('%@')", @"window.WFJSBridge._handleMessageFromNative", [bridgeCallback mj_JSONString]];
    [self evaluateJavaScript:javaScriptCode];
}

- (void)evaluateJavaScript:(NSString *)javaScriptCode {
    if (self.bridgeReady) {
        [_webView evaluateJavaScript:javaScriptCode completionHandler:^(id result, NSError *error) {
            if (error) {
                NSLog(@"[webFast] evaluateJavaScript error: %@", error.description);
            }
        }];
    } else {
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:javaScriptCode injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [_webView.configuration.userContentController addUserScript:userScript];
    }
}

@end

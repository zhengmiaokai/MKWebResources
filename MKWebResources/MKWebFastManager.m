//
//  MKWebFastManager.m
//  webFast
//
//  Created by zhengmiaokai on 2023/4/14.
//

#import "MKWebFastManager.h"
#import "MKWebFastUtils.h"
#import "MKWebResourceLoader.h"
#import "MKHookAjaxHandler.h"
#import "MKURLSchemeHandler.h"
#import "MKCookieSynchronizer.h"


@interface MKWebFastManager () {
    BOOL _isReady; // 秒开是否启动
}

@end

@implementation MKWebFastManager

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static MKWebFastManager *instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (BOOL)webFastEnabled {
    return YES;
}

- (void)startWebFast {
    _isReady = YES;
    
    if (@available(iOS 11.0, *)) {
        // 加载线上资源包
        [[MKWebResourceLoader sharedInstance] loadWebResource];
    }
}

- (void)closeWebFast {
    _isReady = NO;
}

- (void)startAjaxHookWithWebView:(WKWebView *)webView pageLink:(NSString *)pageLink {
    if (_isReady == NO) return; // 秒开未启动
    
    if (@available(iOS 11.0, *)) {
        if ([self webFastEnabled]) {
            // 同步cookie与HTTPBody信息
            MKHookAjaxHandler *ajaxHandler = [[MKHookAjaxHandler alloc] initWithWebView:webView]; // webView.configuration.userContentController持有该实例
            [ajaxHandler startAjaxHook];
            NSLog(@"[webFast] startAjaxHookWithWebView: %@", pageLink);
        }
    }
}

- (void)setURLSchemeWithConfiguration:(WKWebViewConfiguration *)configuration pageLink:(NSString *)pageLink {
    if (_isReady == NO) return; // 秒开未启动
    
    if (@available(iOS 11.0, *)) {
        if ([self webFastEnabled]) {
            // 设置http、https的URLScheme
            MKURLSchemeHandler *schemeHandler = [[MKURLSchemeHandler alloc] init]; // webView.configuration持有该实例
            if (![configuration urlSchemeHandlerForURLScheme:@"http"] && ![configuration urlSchemeHandlerForURLScheme:@"https"]) {
                [configuration setURLSchemeHandler:schemeHandler forURLScheme:@"http"];
                [configuration setURLSchemeHandler:schemeHandler forURLScheme:@"https"];
            }
            NSLog(@"[webFast] setURLSchemeWithConfiguration: %@", pageLink);
        }
    }
}

- (void)setCookieWithURLResponse:(NSHTTPURLResponse *)URLResponse {
    [MKCookieSynchronizer setCookieWithURLResponse:URLResponse];
}

- (void)setCookieWithMessageBody:(NSDictionary *)messageBody {
    [MKCookieSynchronizer setCookieWithMessageBody:messageBody];
}

@end

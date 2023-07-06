//
//  ViewController.m
//  Demo
//
//  Created by zhengmiaokai on 2023/6/21.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "MKWebFastManager.h"

@interface ViewController () <WKUIDelegate, WKNavigationDelegate>

@property (nonatomic, strong) UIButton *ajaxButton;
@property (nonatomic, strong) UIButton *fetchButton;

@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, copy) NSString *URLString;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 设置cookieStorage的cookie信息
    [[MKWebFastManager sharedInstance] setCookieWithMessageBody:@{@"cookie": @"session=03666a711377460fb9325179c561fd63; expires=Tue, 25 Apr 2027 09:20:33 GMT; path=/; domain=.baidu.com"}];
    [[MKWebFastManager sharedInstance] setCookieWithMessageBody:@{@"cookie": @"uid=59658932; expires=Tue, 25 Apr 2027 09:20:33 GMT; path=/; domain=.baidu.com"}];
    [[MKWebFastManager sharedInstance] setCookieWithMessageBody:@{@"cookie": @"token=326589417460fb93256985693561fd6; expires=Tue, 25 Apr 2027 09:20:33 GMT; path=/; domain=.baidu.com"}];
    
    self.URLString = @"https://m.baidu.com";
    
    [self.view addSubview:self.webView];
    [self.view addSubview:self.ajaxButton];
    [self.view addSubview:self.fetchButton];
    
    [self webViewLoadRequest];
}

- (void)webViewLoadRequest {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:_URLString]];
    [[MKWebFastManager sharedInstance] startAjaxHookWithWebView:_webView pageLink:_URLString];
    
    [_webView loadRequest:request];
}

- (void)sendAjaxRequest:(id)sender {
    NSString *javaScriptCode = [NSString stringWithFormat:@"window.WFJSBridge._sendAjaxRequest()"];
    [_webView evaluateJavaScript:javaScriptCode completionHandler:nil];
}

- (void)sendFetchRequest:(id)sender {
    NSString *javaScriptCode = [NSString stringWithFormat:@"window.WFJSBridge._sendFetchRequest()"];
    [_webView evaluateJavaScript:javaScriptCode completionHandler:nil];
}

#pragma mark - Getter -
- (UIButton *)ajaxButton {
    if (!_ajaxButton) {
        _ajaxButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _ajaxButton.frame = CGRectMake(self.view.frame.size.width/2 - 90, self.view.frame.size.height/2 - 50,  180, 80);
        [_ajaxButton setTitle:@"发送 Ajax 请求" forState:UIControlStateNormal];
        [_ajaxButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
        _ajaxButton.layer.cornerRadius = 8;
        _ajaxButton.layer.masksToBounds = YES;
        [_ajaxButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_ajaxButton setBackgroundColor:[UIColor systemBlueColor]];
        [_ajaxButton addTarget:self action:@selector(sendAjaxRequest:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _ajaxButton;
}

- (UIButton *)fetchButton {
    if (!_fetchButton) {
        _fetchButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _fetchButton.frame = CGRectMake(self.view.frame.size.width/2 - 90, self.view.frame.size.height/2 + 50,  180, 80);
        [_fetchButton setTitle:@"发送 Fetch 请求" forState:UIControlStateNormal];
        [_fetchButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
        _fetchButton.layer.cornerRadius = 8;
        _fetchButton.layer.masksToBounds = YES;
        [_fetchButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_fetchButton setBackgroundColor:[UIColor systemBlueColor]];
        [_fetchButton addTarget:self action:@selector(sendFetchRequest:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fetchButton;
}

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        configuration.allowsInlineMediaPlayback = YES;
        configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
        
        WKUserContentController* userContentController = WKUserContentController.new;
        NSString *documentCookies = @"document.cookie='session=03666a711377460fb9325179c561fd63;path=/;domain=.baidu.com';uid=59658932;path=/;domain=.baidu.com';token=326589417460fb93256985693561fd6;path=/;domain=.baidu.com';";
        WKUserScript * cookieScript = [[WKUserScript alloc] initWithSource:documentCookies injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [userContentController addUserScript:cookieScript];
        configuration.userContentController = userContentController;
        
        [[MKWebFastManager sharedInstance] setURLSchemeWithConfiguration:configuration pageLink:_URLString];
        
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
        _webView.navigationDelegate = self;
        _webView.UIDelegate = self;
        
        _webView.scrollView.showsHorizontalScrollIndicator = NO;
        _webView.scrollView.showsVerticalScrollIndicator = NO;
        _webView.scrollView.bounces = NO;
        _webView.allowsBackForwardNavigationGestures = YES;
        if (@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _webView;
}

#pragma mark WKNavigationDelegate methods
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (decisionHandler) {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}


- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    [webView reload];
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    if (completionHandler) {
        completionHandler();
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    if (completionHandler) {
        completionHandler(YES);
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler {
    completionHandler(prompt);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    [[MKWebFastManager sharedInstance] setCookieWithURLResponse:(NSHTTPURLResponse *)navigationResponse.response];
    
    if (decisionHandler) {
        decisionHandler(WKNavigationResponsePolicyAllow);
    }
}

@end


//
//  MKWebFastManager.h
//  webFast
//
//  Created by zhengmiaokai on 2023/4/14.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface MKWebFastManager : NSObject

+ (instancetype)sharedInstance;

- (void)startWebFast; // 开启秒开
- (void)closeWebFast; // 关闭秒开

- (void)startAjaxHookWithWebView:(WKWebView *)webView pageLink:(NSString *)pageLink;
- (void)setURLSchemeWithConfiguration:(WKWebViewConfiguration *)configuration pageLink:(NSString *)pageLink;

- (void)setCookieWithURLResponse:(NSHTTPURLResponse *)URLResponse;
- (void)setCookieWithMessageBody:(NSDictionary *)messageBody;

@end

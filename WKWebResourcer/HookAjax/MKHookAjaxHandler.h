//
//  MKHookAjaxHandler.h
//  webFast
//
//  Created by zhengmiaokai on 2023/4/14.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface MKHookAjaxHandler : NSObject <WKScriptMessageHandler>

- (instancetype)initWithWebView:(WKWebView *)webView;

- (void)startAjaxHook;

@end

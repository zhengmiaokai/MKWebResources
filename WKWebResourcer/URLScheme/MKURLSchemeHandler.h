//
//  MKURLSchemeHandler.h
//  webFast
//
//  Created by zhengmiaokai on 2023/5/23.
//

/*  URLSchemeHandler必须在 WKWebView 未初始化前注入，否则无法触发协议回调
    URLSchemeHandler不受WK缓存机制影响，有没有缓存都会走协议方法 */

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface MKURLSchemeHandler : NSObject <WKURLSchemeHandler>

@end


@interface WKWebView (URLSchemeHandler)

@end

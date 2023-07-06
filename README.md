# WKWebResourceLoader
通过 "WKURLSchemeHandler + AjaxHook"，实现WKWebview的资源拦截，解决了Ajax/Fetch请求的Cookie与HTTPBody信息同步问题，为H5秒开项目提供基础支持。

### 优缺点

1、使用URLSchemeHandler相比URLProtocol可控性更优，可以具体到单个WebView的资源拦截开关，不会造成全局性的影响。

2、URLSchemeHandler不受WebKit缓存机制的影响，只要设置了相应URLScheme的请求都能拦截。

3、使用系统私有api兼容iOS13的crash以及支持请求重定向，具体接口名已做混淆。

3、对H5页面的侵入性较低，除了CDN资源请求转化为本地资源映射，其他基本无感知。

### 使用示例
APP冷启动后加载web资源
```objective-c
// 开启web秒开
[[MKWebFastManager sharedInstance] startWebFast];
    
// 实现资源加载逻辑
- (void)loadWebResource {
    
}

// 实现资源命中逻辑
- (NSData *)obtainLocalResource:(NSURL *)URL {
    return nil;
}
    
```

WebView注入URLSchemeHandler
```objective-c
// 在WebView初始化之前注入
[[MKWebFastManager sharedInstance] setURLSchemeWithConfiguration:configuration pageLink:_pagUrl];
 _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
```

WebView注入HookAjaxHandler
```objective-c
// 在WebView开始加载之前注入
[[MKWebFastManager sharedInstance] startAjaxHookWithWebView:_webView pageLink:_pagUrl];
[_webView loadRequest:request];
```

**源码参考说明**：HookAjax实现Cookie与HTTPbody的同步逻辑是基于Git开源项目-[KKJSBridge](https://github.com/karosLi/KKJSBridge)的相关代码改造。

//
//  MKURLSchemeHandler.m
//  webFast
//
//  Created by zhengmiaokai on 2023/5/23.
//

#import "MKURLSchemeHandler.h"
#import <objc/runtime.h>
#import "MKWebFastUtils.h"
#import "MKWebResourceLoader.h"
#import "MKCookieSynchronizer.h"
#import "MKAjaxBodyAssembler.h"
#import "MKURLSessionManager.h"

static NSDictionary *MKWebFastURLSchemeContentTypes() {
    NSDictionary *contentTypes = @{@"html": @"text/html",
                                   @"js": @"application/x-javascript",
                                   @"css": @"text/css",
                                   @"jpg": @"image/jpeg",
                                   @"png": @"image/png",
                                   @"gif": @"image/gif",
                                   @"svg": @"image/svg+xml",
                                   @"json": @"application/json",
                                   @"xml": @"text/xml",
                                   @"zip": @"application/zip",
                                   @"txt": @"text/plain",
                                   @"pdf": @"application/pdf",
                                   @"doc": @"application/msword",
                                   @"docx": @"application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                                   @"woff": @"application/font-woff",
                                   @"ttf": @"application/octet-stream",
                                   @"otf": @"application/octet-stream",
                                   @"eot": @"application/vnd.ms-fontobject"};
    return contentTypes;
}

@interface MKURLSchemeHandler ()

@property (nonatomic, strong) NSMutableArray *availableTasks;

@end

@implementation MKURLSchemeHandler

- (instancetype)init {
    self = [super init];
    if (self) {
        self.availableTasks = [NSMutableArray array];
    }
    return self;
}

// 处理重定向、实时回调数据
+ (MKURLSessionManager *)sharedSessionManager {
    static dispatch_once_t once;
    static MKURLSessionManager *sessionManager;
    dispatch_once(&once, ^{
        sessionManager = [[MKURLSessionManager alloc] initWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    });
    return sessionManager;
}

// 不处理重定向、完成后回调数据
+ (NSURLSession *)sharedURLSession {
    static dispatch_once_t once;
    static NSURLSession *URLSession;
    dispatch_once(&once, ^{
        URLSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    });
    return URLSession;
}

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask  API_AVAILABLE(ios(11.0)) {
    // 适配iOS13的特性问题
    [self _compatibilityIfNeed];
    
    NSMutableURLRequest *URLRequest = [urlSchemeTask.request mutableCopy];
    NSURL *URL = urlSchemeTask.request.URL;
    
    [self.availableTasks addObject:urlSchemeTask];
    
    // 异步并行防止频繁的IO操作阻塞主线程
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 匹配本地资源文件
        NSData *fileData = [[MKWebResourceLoader sharedInstance] obtainLocalResource:URL];
        if (fileData) {
            // WKURLSchemeHandler在MainQueue触发，请求响应也在MainQueue回调
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.availableTasks containsObject:urlSchemeTask]) {
                    NSLog(@"[webFast] startURLSchemeTask_localResource: %@", URL);
                    
                    NSMutableDictionary *headerFields = [NSMutableDictionary dictionaryWithDictionary:@{@"Access-Control-Allow-Origin": @"*"}];
                    [headerFields wfSetObject:[MKWebFastURLSchemeContentTypes() wfStringForKey:URL.pathExtension] forKey:@"Content-Type"];
                    
                    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:(__bridge NSString *)kCFHTTPVersion1_1 headerFields:headerFields];
                    [urlSchemeTask didReceiveResponse:response];
                    [urlSchemeTask didReceiveData:fileData];
                    [urlSchemeTask didFinish];
                    
                    [self.availableTasks removeObject:urlSchemeTask];
                }
            });
        } else {
            NSLog(@"[webFast] startURLSchemeTask_remoteResource: %@", URL);
            
            [MKCookieSynchronizer syncRequestCookie:URLRequest];
            [MKAjaxBodyAssembler syncRequestConfiguration:URLRequest];
            
            // WKURLSchemeHandler在MainQueue触发，请求响应也在MainQueue回调
            NSURLSessionTask *task = [[MKURLSchemeHandler sharedSessionManager] dataTaskWithRequest:URLRequest didReceiveResponse:^(NSURLSessionDataTask *dataTask, NSURLResponse *response) {
                if ([self.availableTasks containsObject:urlSchemeTask]) {
                    [urlSchemeTask didReceiveResponse:response];
                }
            } didReceiveData:^(NSURLSessionDataTask *dataTask, NSData *data) {
                if ([self.availableTasks containsObject:urlSchemeTask]) {
                    [urlSchemeTask didReceiveData:data];
                }
            } didComplete:^(NSURLSessionTask *task, NSError *error) {
                if ([self.availableTasks containsObject:urlSchemeTask]) {
                    if (error) {
                        [urlSchemeTask didFailWithError:error];
                    } else {
                        [urlSchemeTask didFinish];
                    }
                    [self.availableTasks removeObject:urlSchemeTask];
                }
            } willPerformHTTPRedirection:^(NSHTTPURLResponse *response, NSURLRequest *request) {
                if ([self.availableTasks containsObject:urlSchemeTask]) {
                    NSData *selectorInfo = [[NSData alloc] initWithBase64EncodedString:@"X2RpZFBlcmZvcm1SZWRpcmVjdGlvbjpuZXdSZXF1ZXN0Og==" options:NSUTF8StringEncoding];
                    NSString *selectorName = [[NSString alloc] initWithData:selectorInfo encoding:NSUTF8StringEncoding];
                    SEL selector = NSSelectorFromString(selectorName);
                    if ([urlSchemeTask respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        [urlSchemeTask performSelector:selector withObject:response withObject:request];
#pragma clang diagnostic pop
                    }
                }
            }];
            [task resume];
        }
    });
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask  API_AVAILABLE(ios(11.0)){
    // stop如果不把urlSchemeTask标记为不可用，start时使用urlSchemeTask回写数据会导致crash 'This task has already been stopped'
    if ([self.availableTasks containsObject:urlSchemeTask]) {
        [self.availableTasks removeObject:urlSchemeTask];
    }
}

#pragma mark - Private -
- (void)_compatibilityIfNeed {
    // 兼容iOS13 xhr upload的crash
    NSString *systemVersion = [UIDevice currentDevice].systemVersion;
    if ([systemVersion containsString:@"13."]) {
        NSData *selectorInfo = [[NSData alloc] initWithBase64EncodedString:@"X3NldExvYWRSZXNvdXJjZXNTZXJpYWxseQ==" options:NSUTF8StringEncoding];
        NSString *selectorName = [[NSString alloc] initWithData:selectorInfo encoding:NSUTF8StringEncoding];
        SEL selector = NSSelectorFromString(selectorName);
        id webViewClass = NSClassFromString(@"WebView");
        if ([webViewClass respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [webViewClass performSelector:selector withObject:@(NO)];
#pragma clang diagnostic pop
        }
    }
}

@end


@implementation WKWebView (URLSchemeHandler)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method originalMethod = class_getClassMethod([self class], @selector(handlesURLScheme:));
        Method swizzledMethod = class_getClassMethod([self class], @selector(wfHandlesURLScheme:));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

+ (BOOL)wfHandlesURLScheme:(NSString *)urlScheme {
    // 兼容URLScheme设置为https/http导致的crash
    if ([urlScheme isEqualToString:@"https"]
        || [urlScheme isEqualToString:@"http"]) {
        return NO;
    } else {
        if (@available(iOS 11.0, *)) {
            return [self wfHandlesURLScheme:urlScheme];
        } else {
            return NO;
        }
    }
}

@end

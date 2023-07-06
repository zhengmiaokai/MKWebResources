//
//  MKWebBridgeMessage.h
//  webFast
//
//  Created by zhengmiaokai on 2023/4/14.
//

#import <Foundation/Foundation.h>

// moduleName
static NSString * const MKWebBridgeLifeCycleModule = @"lifeCycle";   // 生命周期
static NSString * const MKWebBridgeCookieModule = @"cookie";         // cookie配置
static NSString * const MKWebBridgeAjaxModule = @"ajax";             // ajax请求

// methodName
static NSString * const MKWebBridgeReadyMethod = @"bridgeReady";            // JSBridge准备就绪
static NSString * const MKWebBridgeSetCookieMethod = @"setCookie";          // 设置cookie信息
static NSString * const MKWebBridgeCacheAjaxBodyMethod = @"cacheAJAXBody";  // 存储ajaxBody

@interface MKWebBridgeMessage : NSObject

@property (nonatomic, copy) NSString *module;     // 模块
@property (nonatomic, copy) NSString *method;     // 方法
@property (nonatomic, copy) NSString *callbackId; // 回调id
@property (nonatomic, copy) NSDictionary *data;   // 元数据

@end


// messageType
static NSString * const MKWebBridgeCallbackType = @"callback"; // 回调消息

@interface MKWebBridgeCallback : NSObject

@property (nonatomic, copy) NSString *messageType; // 消息类型
@property (nonatomic, copy) NSString *callbackId;  // 回调id
@property (nonatomic, copy) NSDictionary *data;    // 元数据

@end

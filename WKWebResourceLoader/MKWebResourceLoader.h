//
//  MKWebResourceLoader.h
//  webFast
//
//  Created by zhengmiaokai on 2023/4/24.
//

#import <Foundation/Foundation.h>

@interface MKWebResourceLoader : NSObject

+ (instancetype)sharedInstance;

/// APP启动后的资源包更新
- (void)loadWebResource;

/// 获取URLString对应的fileData
- (NSData *)obtainLocalResource:(NSURL *)URL;

@end

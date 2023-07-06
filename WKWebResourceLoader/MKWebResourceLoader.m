//
//  MKWebResourceLoader.m
//  webFast
//
//  Created by zhengmiaokai on 2023/4/24.
//

#import "MKWebResourceLoader.h"


@interface MKWebResourceLoader ()

@end

@implementation MKWebResourceLoader

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static MKWebResourceLoader *instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

// APP启动后的资源包更新
- (void)loadWebResource {
    
}

// 获取URLString对应的fileData
- (NSData *)obtainLocalResource:(NSURL *)URL {
    return nil;
}

@end

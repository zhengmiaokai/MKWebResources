//
//  MKAjaxBodyStorage.m
//  webFast
//
//  Created by zhengmiaokai on 2023/4/14.
//

#import "MKAjaxBodyStorage.h"
#import "MKWebFastUtils.h"

@interface MKAjaxBodyStorage () {
    NSLock *_lock;
}

@property (nonatomic, strong) NSMutableDictionary *bodyCache;

@end

@implementation MKAjaxBodyStorage

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static MKAjaxBodyStorage *instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = [[NSLock alloc] init];
        self.bodyCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setAjaxBody:(NSDictionary *)ajaxBody {
    NSString *requestId = [ajaxBody wfStringForKey:@"requestId"];
    [self setHTTPBody:ajaxBody requestId:requestId];
}

- (void)setHTTPBody:(NSDictionary *)HTTPBody requestId:(NSString *)requestId {
    [_lock lock];
    [self.bodyCache wfSetObject:HTTPBody forKey:requestId];
    [_lock unlock];
}

- (NSDictionary *)HTTPBodyForRequestId:(NSString *)requestId {
    [_lock lock];
    NSDictionary *HTTPBody = [self.bodyCache wfDictionaryForKey:requestId];
    [_lock unlock];
    return HTTPBody;
}

@end

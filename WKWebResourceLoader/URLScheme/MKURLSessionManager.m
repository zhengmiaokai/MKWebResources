//
//  MKURLSessionManager.m
//  webFast
//
//  Created by zhengmiaokai on 2023/5/24.
//

#import "MKURLSessionManager.h"
#import "MKWebFastUtils.h"

#define WFLOCK(...) dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(_lock);

@interface MKURLSessionManager () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *URLSession;

@property (nonatomic, strong) dispatch_semaphore_t lock;
@property (nonatomic, strong) NSMutableDictionary* taskhandlers;

@end

@implementation MKURLSessionManager

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration {
    self = [super init];
    if (self) {
        self.URLSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        self.lock = dispatch_semaphore_create(1);
        self.taskhandlers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSMutableURLRequest *)request
                           didReceiveResponse:(void(^)(NSURLSessionDataTask *dataTask, NSURLResponse *response))receiveResponse
                               didReceiveData:(void(^)(NSURLSessionDataTask *dataTask, NSData *data))receiveData
                                  didComplete:(void(^)(NSURLSessionTask *task, NSError *error))complete
                   willPerformHTTPRedirection:(void(^)(NSHTTPURLResponse *response, NSURLRequest *request))performHTTPRedirection {
    NSURLSessionDataTask *dataTask = [_URLSession dataTaskWithRequest:request];
    
    MKTaskHandler* taskHandler = [[MKTaskHandler alloc] init];
    taskHandler.didReceiveResponse = receiveResponse;
    taskHandler.didReceiveData = receiveData;
    taskHandler.didComplete = complete;
    taskHandler.willPerformHTTPRedirection = performHTTPRedirection;
    WFLOCK([_taskhandlers wfSetObject:taskHandler forKey:[MKWebFastUtils identifyByObject:dataTask]]);
    
    return dataTask;
}

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(__unused NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    WFLOCK(MKTaskHandler *taskHandler = [_taskhandlers wfObjectForKey:[MKWebFastUtils identifyByObject:task]]);
    taskHandler.didComplete(task, error);
    
    WFLOCK([_taskhandlers wfRemoveObjectForKey:[MKWebFastUtils identifyByObject:task]]);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    WFLOCK(MKTaskHandler *taskHandler = [_taskhandlers wfObjectForKey:[MKWebFastUtils identifyByObject:task]]);
    taskHandler.willPerformHTTPRedirection(response, request);
    
    if (completionHandler) {
        completionHandler(request);
    }
}

#pragma mark NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    WFLOCK(MKTaskHandler *taskHandler = [_taskhandlers wfObjectForKey:[MKWebFastUtils identifyByObject:dataTask]]);
    taskHandler.didReceiveData(dataTask, data);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    WFLOCK(MKTaskHandler* taskHandler = [_taskhandlers wfObjectForKey:[MKWebFastUtils identifyByObject:dataTask]]);
    taskHandler.didReceiveResponse(dataTask, response);
    
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

@end


@implementation MKTaskHandler

@end

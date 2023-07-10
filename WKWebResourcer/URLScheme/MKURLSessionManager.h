//
//  MKURLSessionManager.h
//  webFast
//
//  Created by zhengmiaokai on 2023/5/24.
//

#import <Foundation/Foundation.h>

@interface MKURLSessionManager : NSObject

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration;

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSMutableURLRequest *)request
                           didReceiveResponse:(void(^)(NSURLSessionDataTask *dataTask, NSURLResponse *response))receiveResponse
                               didReceiveData:(void(^)(NSURLSessionDataTask *dataTask, NSData *data))receiveData
                                  didComplete:(void(^)(NSURLSessionTask *task, NSError *error))complete
                   willPerformHTTPRedirection:(void(^)(NSHTTPURLResponse *response, NSURLRequest *request))performHTTPRedirection;

@end


@interface MKTaskHandler : NSObject

@property (nonatomic, copy) void(^didReceiveData)(NSURLSessionDataTask *dataTask, NSData *data);
@property (nonatomic, copy) void(^didReceiveResponse)(NSURLSessionDataTask *dataTask, NSURLResponse *response);
@property (nonatomic, copy) void(^didComplete)(NSURLSessionTask *task, NSError *error);
@property (nonatomic, copy) void(^willPerformHTTPRedirection)(NSHTTPURLResponse *response, NSURLRequest *request);

@end

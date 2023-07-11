//
//  MKWebFastURLRequestSerialization.h
//  AFNetworking
//
//  Created by karos li on 2020/6/20.
//
#import <Foundation/Foundation.h>
#import "MKWebFastStreamMultipartFormData.h"

@interface MKWebFastURLRequestSerialization : NSObject

- (void)multipartFormRequestWithRequest:(NSMutableURLRequest *)mutableRequest
                         parameters:(NSDictionary *)parameters
          constructingBodyWithBlock:(void (^)(id <MKWebFastMultipartFormData> formData))block
                              error:(NSError *__autoreleasing *)error;

@end

//
//  MKWebFastStreamMultipartFormData.h
//  AFNetworking
//
//  Created by karos li on 2020/6/20.
//

#import <Foundation/Foundation.h>
#import "MKWebFastMultipartFormData.h"

@interface MKWebFastStreamMultipartFormData : NSObject <MKWebFastMultipartFormData>

- (instancetype)initWithURLRequest:(NSMutableURLRequest *)urlRequest stringEncoding:(NSStringEncoding)encoding;

- (NSMutableURLRequest *)requestByFinalizingMultipartFormData;

@end

//
//  MKAjaxBodyStorage.h
//  webFast
//
//  Created by zhengmiaokai on 2023/4/14.
//

#import <Foundation/Foundation.h>

@interface MKAjaxBodyStorage : NSObject

+ (instancetype)sharedInstance;

- (void)setAjaxBody:(NSDictionary *)ajaxBody;

- (NSDictionary *)HTTPBodyForRequestId:(NSString *)requestId;

@end

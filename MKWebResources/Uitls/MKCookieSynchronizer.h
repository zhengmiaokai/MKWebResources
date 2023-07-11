//
//  MKCookieSynchronizer.h
//  webFast
//
//  Created by zhengmiaokai on 2023/4/6.
//

#import <Foundation/Foundation.h>

@interface MKCookieSynchronizer : NSObject

/* 同步h5-request的cookies */
+ (void)syncRequestCookie:(NSMutableURLRequest *)request;

/* 设置storage的cookies */
+ (void)setCookieWithMessageBody:(NSDictionary *)messageBody;

/* 设置storage的cookies */
+ (void)setCookieWithURLResponse:(NSHTTPURLResponse *)URLResponse;

@end

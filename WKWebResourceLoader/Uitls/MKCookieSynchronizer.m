//
//  MKCookieSynchronizer.m
//  webFast
//
//  Created by zhengmiaokai on 2023/4/6.
//

#import "MKCookieSynchronizer.h"
#import "MKWebFastUtils.h"

@implementation MKCookieSynchronizer

+ (void)syncRequestCookie:(NSMutableURLRequest *)request {
    if ([request valueForHTTPHeaderField:@"Cookie"] || !request.URL) {
        return;
    }
    
    NSArray *availableCookie = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:request.URL];
    if (availableCookie.count > 0) {
        NSDictionary *reqHeader = [NSHTTPCookie requestHeaderFieldsWithCookies:availableCookie];
        NSString *cookieStr = [reqHeader objectForKey:@"Cookie"];
        [request setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    }
}

+ (void)setCookieWithURLResponse:(NSHTTPURLResponse *)URLResponse {
    if ([URLResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        NSArray* cookieArr = [NSHTTPCookie cookiesWithResponseHeaderFields:URLResponse.allHeaderFields forURL:URLResponse.URL];
        for (NSHTTPCookie* cookie in cookieArr) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
}

+ (void)setCookieWithMessageBody:(NSDictionary *)messageBody {
    NSString *cookieString = [messageBody wfStringForKey:@"cookie"];
    if (![cookieString isKindOfClass:NSString.class] || cookieString.length == 0) return;
    
    NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:6];
    NSArray<NSString *> *segements = [cookieString componentsSeparatedByString:@";"];
    for (NSInteger i = 0; i < segements.count; i++) {
        NSString *seg = segements[i];
        NSString *trimSeg = [seg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray<NSString *> *keyWithValues = [trimSeg componentsSeparatedByString:@"="];
        if (keyWithValues.count == 2 && keyWithValues[0].length > 0) {
            NSString *trimKey = [keyWithValues[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *trimValue = [keyWithValues[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            if (i == 0) {
                properties[NSHTTPCookieName] = trimKey;
                properties[NSHTTPCookieValue] = trimValue;
            } else if ([trimKey isEqualToString:@"domain"]) {
                properties[NSHTTPCookieDomain] = trimValue;
            } else if ([trimKey isEqualToString:@"path"]) {
                properties[NSHTTPCookiePath] = trimValue;
            } else if ([trimKey isEqualToString:@"expires"] && trimValue.length > 0) {
                properties[NSHTTPCookieExpires] = [[self expiresFormatter] dateFromString:trimValue];;
            } else {
                properties[trimKey] = trimValue;
            }
        } else if (keyWithValues.count == 1 && keyWithValues[0].length > 0) {// 说明是单个 key 的属性
            NSString *trimKey = [keyWithValues[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([trimKey isEqualToString:@"Secure"]) {
                properties[NSHTTPCookieSecure] = @(YES);
            } else {
                properties[trimKey] = @(YES);
            }
        }
    }
    
    if (properties.count > 0) {
        NSHTTPCookie *cookieObject = [NSHTTPCookie cookieWithProperties:properties];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookieObject];
    }
}

+ (NSDateFormatter *)expiresFormatter {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // expires=Mon, 01 Aug 2050 06:44:35 GMT
        formatter = [NSDateFormatter new];
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        formatter.dateFormat = @"EEE, d MMM yyyy HH:mm:ss zzz";
    });
    
    return formatter;
}

@end

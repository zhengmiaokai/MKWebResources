//
//  MKWebFastUtils.m
//  webFast
//
//  Created by zhengmiaokai on 2023/4/24.
//

#import "MKWebFastUtils.h"

@implementation MKWebFastUtils

+ (NSString *)identifyByObject:(id)object {
    return [NSString stringWithFormat:@"WebFast-%p", object];
}

@end


@implementation NSDictionary (WebFast)

- (id)wfObjectForKey:(NSString *)key {
    if (key) {
        return [self objectForKey:key];
    }
    return nil;
}

- (NSString *)wfStringForKey:(NSString *)key {
    id value = [self objectForKey:key];
    if (value == nil || value == [NSNull null]) {
        return nil;
    }
    if ([value isKindOfClass:[NSString class]]) {
        return (NSString *)value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }
    return nil;
}

- (NSDictionary *)wfDictionaryForKey:(NSString *)key {
    id value = [self objectForKey:key];
    if (value == nil || value == [NSNull null]) {
        return nil;
    }
    if ([value isKindOfClass:[NSDictionary class]]) {
        return value;
    }
    return nil;
}

@end


@implementation NSMutableDictionary (WebFast)

- (void)wfSetObject:(id)object forKey:(NSString *)key {
    if (object && key) {
        [self setObject:object forKey:key];
    }
}

- (void)wfRemoveObjectForKey:(NSString *)key {
    if (key) {
        [self removeObjectForKey:key];
    }
}

@end

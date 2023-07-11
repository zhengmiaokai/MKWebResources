//
//  MKWebFastUtils.h
//  webFast
//
//  Created by zhengmiaokai on 2023/4/24.
//

#import <Foundation/Foundation.h>
#import <MJExtension/MJExtension.h>

@interface MKWebFastUtils : NSObject

+ (NSString *)identifyByObject:(id)object;

@end


@interface NSDictionary (WebFast)

- (id)wfObjectForKey:(NSString *)key;

- (NSString *)wfStringForKey:(NSString *)key;

- (NSDictionary *)wfDictionaryForKey:(NSString *)key;

@end


@interface NSMutableDictionary (WebFast)

- (void)wfSetObject:(id)object forKey:(NSString *)key;

- (void)wfRemoveObjectForKey:(NSString *)key;

@end

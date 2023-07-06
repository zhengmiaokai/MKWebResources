//
//  MKWebFastFormDataFile.h
//  AFNetworking
//
//  Created by karos li on 2020/6/20.
//

#import <Foundation/Foundation.h>

@interface MKWebFastFormDataFile : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, assign) NSUInteger lastModified;
@property (nonatomic, assign) NSUInteger size;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSData *data;

@end

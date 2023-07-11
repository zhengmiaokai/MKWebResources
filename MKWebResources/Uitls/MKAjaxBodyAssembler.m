//
//  MKAjaxBodyAssembler.m
//  webFast
//
//  Created by zhengmiaokai on 2023/4/14.
//

#import "MKAjaxBodyAssembler.h"
#import "MKAjaxBodyStorage.h"
#import "MKWebFastFormDataFile.h"
#import "MKWebFastURLRequestSerialization.h"

static NSString * const kWFJSBridgeRequestId = @"WFJSBridge-RequestId";
static NSString * const kWFJSBridgeUrlRequestIdRegex = @"^.*?[&|\\?|%3f]?WFJSBridge-RequestId[=|%3d](\\d+).*?$";
static NSString * const kWFJSBridgeUrlRequestIdPairRegex = @"^.*?([&|\\?|%3f]?WFJSBridge-RequestId[=|%3d]\\d+).*?$";

@implementation MKAjaxBodyAssembler

+ (void)syncRequestConfiguration:(NSMutableURLRequest *)request {
    NSString *requestId = nil;
    if ([request.URL.absoluteString containsString:kWFJSBridgeRequestId]) {
        requestId = [self fetchRequestId:request.URL.absoluteString];
        
        // 移除临时的WFJSBridge-RequestId
        NSString *reqeustPair = [self fetchRequestIdPair:request.URL.absoluteString];
        if (reqeustPair) {
            NSString *absString = [request.URL.absoluteString stringByReplacingOccurrencesOfString:reqeustPair withString:@""];
            request.URL = [NSURL URLWithString:absString];
        }
    }
    
    if (![request.HTTPMethod isEqualToString:@"GET"] && requestId) {
        [MKAjaxBodyAssembler syncHTTPBody:request requestId:requestId];
    }
}

#pragma mark - Private -
+ (void)syncHTTPBody:(NSMutableURLRequest *)request requestId:(NSString *)requestId {
    NSDictionary *HTTPBody = [[MKAjaxBodyStorage sharedInstance] HTTPBodyForRequestId:requestId];
    
    NSData *data = nil;
    NSString *bodyType = HTTPBody[@"bodyType"];
    NSString *formEnctype = HTTPBody[@"formEnctype"];
    id value = HTTPBody[@"value"];
    if (!value) {
        return;
    }
    
    if ([bodyType isEqualToString:@"Blob"]) {
        data = [self dataFromBase64:value];
    } else if ([bodyType isEqualToString:@"ArrayBuffer"]) {
        data = [self dataFromBase64:value];
    } else if ([bodyType isEqualToString:@"FormData"]) {
        [self setFormData:value formEnctype:formEnctype toRequest:request];
        return;
    } else {
        if ([value isKindOfClass:NSDictionary.class]) {
            // application/json
            data = [NSJSONSerialization dataWithJSONObject:value options:0 error:nil];
        } else if ([value isKindOfClass:NSString.class]) {
            // application/x-www-form-urlencoded
            data = [value dataUsingEncoding:NSUTF8StringEncoding];
        } else {
            data = value;
        }
    }
    
    request.HTTPBody = data;
}

+ (NSString *)fetchRequestId:(NSString *)url {
    return [self fetchMatchedTextFromUrl:url withRegex:kWFJSBridgeUrlRequestIdRegex];
}

+ (NSString *)fetchRequestIdPair:(NSString *)url {
    return [self fetchMatchedTextFromUrl:url withRegex:kWFJSBridgeUrlRequestIdPairRegex];
}

+ (NSString *)fetchMatchedTextFromUrl:(NSString *)url withRegex:(NSString *)regexString {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:NULL];
    NSArray *matches = [regex matchesInString:url options:0 range:NSMakeRange(0, url.length)];
    NSString *content;
    for (NSTextCheckingResult *match in matches) {
        for (int i = 0; i < [match numberOfRanges]; i++) {
            //以正则中的(),划分成不同的匹配部分
            content = [url substringWithRange:[match rangeAtIndex:i]];
            if (i == 1) {
                return content;
            }
        }
    }
    return content;
}

+ (NSData *)dataFromBase64:(NSString *)base64 {
    if (!base64) {
        return [NSData data];
    }
    
    NSArray<NSString *> *components = [base64 componentsSeparatedByString:@","];
    
    NSString *splitBase64;
    if (components.count == 2) {
        splitBase64 = components.lastObject;
    } else {
        splitBase64 = base64;
    }
    
    NSUInteger paddedLength = splitBase64.length + (splitBase64.length % 4);
    NSString *fixBase64 = [splitBase64 stringByPaddingToLength:paddedLength withString:@"=" startingAtIndex:0];
    NSData *data = [[NSData alloc] initWithBase64EncodedString:fixBase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    return data;
}

+ (void)setFormData:(NSDictionary *)formDataJson formEnctype:(NSString *)formEnctype toRequest:(NSMutableURLRequest *)request {
    NSArray<NSString *> *fileKeys = formDataJson[@"fileKeys"];
    NSArray<NSArray *> *formData = formDataJson[@"formData"];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSMutableArray<MKWebFastFormDataFile *> *fileDatas = [NSMutableArray array];
    
    for (NSArray *pair in formData) {
        if (pair.count < 2) {
            continue;
        }
        
        NSString *key = pair[0];
        if ([fileKeys containsObject:key]) {// 说明存储的是个文件数据
            NSDictionary *fileJson = pair[1];
            MKWebFastFormDataFile *fileData = [MKWebFastFormDataFile new];
            fileData.key = key;
            fileData.size = [fileJson[@"size"] unsignedIntegerValue];
            fileData.type = fileJson[@"type"];
            
            if (fileJson[@"name"] && [fileJson[@"name"] length] > 0) {
                fileData.fileName = fileJson[@"name"];
            } else {
                fileData.fileName = fileData.key;
            }
            if (fileJson[@"lastModified"] && [fileJson[@"lastModified"] unsignedIntegerValue] > 0) {
                fileData.lastModified = [fileJson[@"lastModified"] unsignedIntegerValue];
            }
            
            if ([formEnctype isEqualToString:@"multipart/form-data"]) {
                if ([fileJson[@"data"] isKindOfClass:NSString.class]) {
                    NSString *base64 = (NSString *)fileJson[@"data"];
                    NSData *byteData = [self dataFromBase64:base64];
                    fileData.data = byteData;
                }
                
                [fileDatas addObject:fileData];
            } else {
                params[key] = fileData.fileName;
            }
        } else {
            params[key] = pair[1];
        }
    }
    
    if ([formEnctype isEqualToString:@"multipart/form-data"]) {
        MKWebFastURLRequestSerialization *serializer = [self urlRequestSerialization];
        [serializer multipartFormRequestWithRequest:request parameters:params constructingBodyWithBlock:^(id<MKWebFastMultipartFormData>  _Nonnull formData) {
            for (MKWebFastFormDataFile *fileData in fileDatas) {
                [formData appendPartWithFileData:fileData.data name:fileData.key fileName:fileData.fileName mimeType:fileData.type];
            }
        } error:nil];
    } else if ([formEnctype isEqualToString:@"text/plain"]) {
        NSMutableString *string = [NSMutableString new];
        NSString *lastKey = params.allKeys.lastObject;
        for (NSString *key in params.allKeys) {
            [string appendFormat:@"%@=%@", [self percentEscapedStringFromString:key], [self percentEscapedStringFromString:params[key]]];
            if (![key isEqualToString:lastKey]) {
                [string appendString:@"\r\n"];
            }
        }
        
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        request.HTTPBody = data;
    } else {// application/x-www-form-urlencoded
        NSMutableString *string = [NSMutableString new];
        NSString *lastKey = params.allKeys.lastObject;
        for (NSString *key in params.allKeys) {
            [string appendFormat:@"%@=%@", [self percentEscapedStringFromString:key], [self percentEscapedStringFromString:params[key]]];
            if (![key isEqualToString:lastKey]) {
                [string appendString:@"&"];
            }
        }
        
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        request.HTTPBody = data;
    }
}

+ (NSString *)percentEscapedStringFromString:(NSString *)string {
    static NSString * const kAFCharactersGeneralDelimitersToEncode = @":#[]@";
    static NSString * const kAFCharactersSubDelimitersToEncode = @"!$&'()*+,;=";

    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kAFCharactersGeneralDelimitersToEncode stringByAppendingString:kAFCharactersSubDelimitersToEncode]];
    
    static NSUInteger const batchSize = 50;

    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;

    while (index < string.length) {
        NSUInteger length = MIN(string.length - index, batchSize);
        NSRange range = NSMakeRange(index, length);
        
        range = [string rangeOfComposedCharacterSequencesForRange:range];

        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];

        index += range.length;
    }
    return escaped;
}

#pragma mark - Getter
+ (MKWebFastURLRequestSerialization *)urlRequestSerialization {
    static MKWebFastURLRequestSerialization *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [MKWebFastURLRequestSerialization new];
    });
    return instance;
}

@end

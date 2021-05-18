//
//  SJNetworkUtils.m
//  SJNetwork
//
//  Created by Sun Shijie on 2017/8/17.
//  Copyright © 2017年 Shijie. All rights reserved.
//

#import "SJNetworkUtils.h"
#import <CommonCrypto/CommonDigest.h>


#define CC_MD5_DIGEST_LENGTH    16          /* digest length in bytes */
#define CC_MD5_BLOCK_BYTES      64          /* block size in bytes */
#define CC_MD5_BLOCK_LONG       (CC_MD5_BLOCK_BYTES / sizeof(CC_LONG))

NSString * const SJNetworkCacheBaseFolderName = @"SJNetworkCache";
NSString * const SJNetworkCacheFileSuffix = @"cacheData";
NSString * const SJNetworkCacheInfoFileSuffix = @"cacheInfo";
NSString * const SJNetworkDownloadResumeDataInfoFileSuffix = @"resumeInfo";

@implementation SJNetworkUtils

#pragma mark- ============== Public Methods ==============
+ (NSString * _Nullable)appVersionStr{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}


/// md5
/// @param urlString NSString
+ (NSString *)md5WithURLString:(NSString *)urlString{
    const char *cStr = [urlString UTF8String];//OC -> C
    if (cStr == NULL) { //空值处理
        return @"";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];//初始化16位长度数组用于存值
    CC_MD5(cStr, (CC_LONG)strlen(cStr), r);//MD5加密后赋值
    NSString *MD5Str = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];//C -> OC
    return MD5Str;
}

///网络请求的url 及参数进行签名处理
/// @param url NSString
/// @param paramsDict NSDictionary
+ (NSString *_Nullable)appendAllUrlPostfix:(NSString *_Nullable)url
                                    params:(NSDictionary*_Nullable)paramsDict{
    if (url == nil || url.length == 0){
        return url;
    }
    NSString *urlString = url;
    NSArray *tmpArray = [urlString componentsSeparatedByString:@"?"];
    NSMutableDictionary *paraDict = [NSMutableDictionary dictionary];
    if (tmpArray.count > 1){
        NSString *paraString = [tmpArray lastObject];
        NSArray *tmpArray2 = [paraString componentsSeparatedByString:@"&"];
        for (NSString *each in tmpArray2){
            NSArray *keyValue = [each componentsSeparatedByString:@"="];
            if (keyValue.count == 2 ){
                [paraDict setObject:[keyValue lastObject] forKey:[keyValue firstObject]];
            }
        }
    }
    
    NSMutableDictionary *tempParameters = [NSMutableDictionary dictionaryWithDictionary:paraDict];
    if (paramsDict && paramsDict.count > 0){
        NSArray* allKey = paramsDict.allKeys;
        for (int i = 0 ; i < allKey.count; ++i){
            [tempParameters setObject:[paramsDict valueForKey:allKey[i]] forKey:allKey[i]];
        }
    }
    
    NSString *sign = [self signFor:tempParameters];
    [tempParameters setObject:sign forKey:@"sign"];
    if ([url rangeOfString:@"?"].location == NSNotFound) {
        url = [NSString stringWithFormat:@"%@?", url];
    }
    
    //把url自带的参数remove了，避免重复拼接
    if (paraDict && paraDict.count > 0) {
        for (NSString *key in paraDict.allKeys) {
            [tempParameters removeObjectForKey:key];
        }
    }
    
    int index = 0;
    for (id key in tempParameters) {
        id obj = [tempParameters objectForKey:key];
        if (index == 0 && ([url hasSuffix:@"?"] || [url hasSuffix:@"?"])) {
            url = [NSString stringWithFormat:@"%@%@=%@",url, key, obj];
        }else{
            url = [NSString stringWithFormat:@"%@&%@=%@",url, key, obj];
        }
        ++index;
    }
    return url;
}

+ (NSString *)signFor:(NSDictionary *)dict{
    NSArray *sortedKeys = [[dict allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    NSMutableString *tmpString = [[NSMutableString alloc] init];
    for (NSString *key in sortedKeys){
        [tmpString appendString:[NSString stringWithFormat:@"%@=%@&", key, dict[key]]];
    }
    NSString *result = [self signForWithURL:tmpString];
    return result;
}

+ (NSString *)signForWithURL:(NSString *)url{
    if (url.length == 0)
        return @"";
    url = [SJNetworkUtils URLDecoding:url];
    NSString *sand = @"321iklnklcnvanzpiorq90974hcnxnzbvouerqzajxczkljkldjaflija";
    NSString *tmp = [NSString stringWithFormat:@"%@%@",[url substringWithRange:NSMakeRange(0, url.length - 1)], sand];
    NSString *result = [self md5WithURLString:[tmp uppercaseString]];
    return result;
}

+ (NSString * _Nonnull)generateMD5StringFromString:(NSString * _Nonnull)string {
    NSParameterAssert(string != nil && [string length] > 0);
    const char *value = [string UTF8String];
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    }
    return outputString;
}


/**
 *  This method is used to generate unique identifier of a specific request
 *
 *  @param UrlStr                           request url
 *  @param methodStr                    request method
 *  @param parameters                  parameters (can be nil)
 *
 *  @return the unique identifier  of a specific request
 */
+ (NSString * _Nonnull)generateRequestIdentiferWithUrlStr:(NSString * _Nullable)UrlStr
                                                methodStr:(NSString * _Nullable)methodStr
                                               parameters:(id _Nullable)parameters{
    NSString *paramsStr = @"";
    NSString *parameters_md5 = @"";
    NSString *method_md5 = @"Method:";
    NSString *url_md5       = [self generateMD5StringFromString:[NSString stringWithFormat:@"Url:%@",UrlStr]];
    if (parameters) {
        paramsStr =        [self p_convertJsonStringFromDictionaryOrArray:parameters];
        parameters_md5 =   [self generateMD5StringFromString: [NSString stringWithFormat:@"Parameters:%@",paramsStr]];
    }
    if (methodStr.length) {
        method_md5    = [self generateMD5StringFromString: [NSString stringWithFormat:@"Method:%@",methodStr]];
    }
    NSString *requestIdentifer = [NSString stringWithFormat:@"%@_%@_%@",url_md5,method_md5,parameters_md5];
    return requestIdentifer;
}

+ (NSString * _Nonnull)createBasePathWithFolderName:(NSString * _Nonnull)folderName{
    NSString *pathOfCache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [pathOfCache stringByAppendingPathComponent:folderName];
    [self p_createDirectoryIfNeeded:path];
    return path;
}

+ (NSString * _Nonnull)createCacheBasePath{
    return [self createBasePathWithFolderName:SJNetworkCacheBaseFolderName];
}

+ (NSString * _Nonnull)cacheDataFilePathWithRequestIdentifer:(NSString * _Nonnull)requestIdentifer{
    if (requestIdentifer.length > 0) {
        NSString *cacheFileName = [NSString stringWithFormat:@"%@.%@", requestIdentifer,SJNetworkCacheFileSuffix];
        NSString *cacheFilePath = [[self createCacheBasePath] stringByAppendingPathComponent:cacheFileName];
        return cacheFilePath;
        
    }else{
        return nil;
    }
}

+ (NSString * _Nonnull)cacheDataInfoFilePathWithRequestIdentifer:(NSString * _Nonnull)requestIdentifer{
    if (requestIdentifer.length > 0) {
        NSString *cacheInfoFileName = [NSString stringWithFormat:@"%@.%@", requestIdentifer,SJNetworkCacheInfoFileSuffix];
        NSString *cacheInfoFilePath = [[self createCacheBasePath] stringByAppendingPathComponent:cacheInfoFileName];
        return cacheInfoFilePath;
    }else{
        return nil;
    }
}

+ (NSString * _Nonnull)resumeDataFilePathWithRequestIdentifer:(NSString * _Nonnull)requestIdentifer downloadFileName:(NSString * _Nonnull)downloadFileName{
    
    NSString *dataFileName = [NSString stringWithFormat:@"%@.%@", requestIdentifer, downloadFileName];
    NSString * resumeDataFilePath = [[self createCacheBasePath] stringByAppendingPathComponent:dataFileName];
    return resumeDataFilePath;
}

+ (NSString * _Nonnull)resumeDataInfoFilePathWithRequestIdentifer:(NSString * _Nonnull)requestIdentifer{
    
    NSString * dataInfoFileName = [NSString stringWithFormat:@"%@.%@", requestIdentifer,SJNetworkDownloadResumeDataInfoFileSuffix];
    NSString * resumeDataInfoFilePath = [[self createCacheBasePath] stringByAppendingPathComponent:dataInfoFileName];
    return resumeDataInfoFilePath;
}

+ (BOOL)availabilityOfData:(NSData * _Nonnull)data{
    
    if (!data || [data length] < 1) return NO;
    
    NSError *error;
    NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
    
    if (!resumeDictionary || error) return NO;
    
    // Before iOS 9 & Mac OS X 10.11
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < 90000)\
|| (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED < 101100)
    NSString *localFilePath = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoLocalPath"];
    if ([localFilePath length] < 1) return NO;
    return [[NSFileManager defaultManager] fileExistsAtPath:localFilePath];
#endif
    return YES;
}


+ (NSString * _Nullable)imageFileTypeForImageData:(NSData * _Nonnull)imageData{
    
    uint8_t c;
    [imageData getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return @"jpeg";
        case 0x89:
            return @"png";
        case 0x47:
            return @"gif";
        case 0x49:
        case 0x4D:
            return @"tiff";
        case 0x52:
            if ([imageData length] < 12) {
                return nil;
            }
            NSString *testString = [[NSString alloc] initWithData:[imageData subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                return @"webp";
            }
            return nil;
    }
    return nil;
}

#pragma mark- ============== Private Methods ==============

+ (NSString *)p_convertJsonStringFromDictionaryOrArray:(id)parameter {
    NSData *data = [NSJSONSerialization dataWithJSONObject:parameter
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:nil];
    
    NSString *jsonStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    return jsonStr;
}

+ (void)p_createDirectoryIfNeeded:(NSString *)path {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    
    if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        
        [self p_createBaseDirectoryAtPath:path];
        
    } else {
        
        if (!isDir) {
            
            NSError *error = nil;
            [fileManager removeItemAtPath:path error:&error];
            [self p_createBaseDirectoryAtPath:path];
        }
    }
}

+ (void)p_createBaseDirectoryAtPath:(NSString *)path {
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
}


/// URL Encoding
/// @param urlString NSString
+ (NSString *)URLEncoding:(NSString *)urlString {
    NSMutableCharacterSet *CharacterSet = [NSMutableCharacterSet new];
    [CharacterSet addCharactersInString:@"!$&'()*+,-./:;=?@_~%#[]"];
    NSString *encodedString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:CharacterSet];
    return encodedString;
}


/// URL Decoding
/// @param urlString NSString
+ (NSString *)URLDecoding:(NSString *)urlString {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault,(CFStringRef) urlString, CFSTR("")));
}

@end

//
//  SJNetworkUtils.h
//  SJNetwork
//
//  Created by Sun Shijie on 2017/8/17.
//  Copyright © 2017年 Shijie. All rights reserved.
//

#import <Foundation/Foundation.h>


/* =============================
 *
 * SJNetworkUtils
 *
 * SJNetworkUtils is in charge of some operation of string or generate information
 *
 * =============================
 */

extern NSString * _Nonnull const SJNetworkCacheBaseFolderName;
extern NSString * _Nonnull const SJNetworkCacheFileSuffix;
extern NSString * _Nonnull const SJNetworkCacheInfoFileSuffix;
extern NSString * _Nonnull const SJNetworkDownloadResumeDataInfoFileSuffix;


@interface SJNetworkUtils : NSObject


/**
 *  This method is used to return app version
 *
 *  @return app version string
 */
+ (NSString * _Nullable)appVersionStr;

/**
 *  This method is used to generate the md5 string of given string
 *
 *  @param string                       original string
 *
 *  @return the transformed md5 string
 */
+ (NSString * _Nonnull)generateMD5StringFromString:(NSString *_Nonnull)string;


/**
 *  This method is used to generate unique identifier of a specific request
 *
 *  @param UrlStr                           request url
 *  @param methodStr                    request method
 *  @param parameters                   parameters (can be nil)
 *
 *  @return the unique identifier  of a specific request
 */
+ (NSString * _Nonnull)generateRequestIdentiferWithUrlStr:(NSString * _Nullable)UrlStr
                                                methodStr:(NSString * _Nullable)methodStr
                                               parameters:(id _Nullable)parameters;


/**
 *  This method is used to create a folder of a given folder name
 *
 *  @param folderName                   folder name
 *
 *  @return the full path of the new folder
 */
+ (NSString * _Nonnull)createBasePathWithFolderName:(NSString * _Nonnull)folderName;





/**
 *  This method is used to create cache base folder path
 *
 *
 *  @return the base cache  folder path
 */
+ (NSString * _Nonnull)createCacheBasePath;




/**
 *  This method is used to return the cache data file path of the given requestIdentifer
 *
 *  @param requestIdentifer     the unique identier of a specific  network request
 *
 *  @return the cache data file path
 */
+ (NSString * _Nonnull)cacheDataFilePathWithRequestIdentifer:(NSString * _Nonnull)requestIdentifer;





/**
 *  This method is used to return the cache data file path of the given requestIdentifer
 *
 *  @param requestIdentifer     the unique identier of a specific  network request
 *
 *  @return the cache data file path
 */
+ (NSString * _Nonnull)cacheDataInfoFilePathWithRequestIdentifer:(NSString * _Nonnull)requestIdentifer;





/**
 *  This method is used to return resume data file path of the given requestIdentifer
 *
 *  @param requestIdentifer     the unique identier of a specific  network request
 *  @param downloadFileName     the download file name (the last path component of a complete download request url)
 *
 *  @return resume data file path
 */
+ (NSString * _Nonnull)resumeDataFilePathWithRequestIdentifer:(NSString * _Nonnull)requestIdentifer downloadFileName:(NSString * _Nonnull)downloadFileName;

/**
 *  This method is used to return the resume data info file path of the given requestIdentifer
 *
 *  @param requestIdentifer     the unique identier of a specific  network request
 *
 *  @return the resume data info file path
 */
+ (NSString * _Nonnull)resumeDataInfoFilePathWithRequestIdentifer:(NSString * _Nonnull)requestIdentifer;

/**
 *  This method is used to check the availability of given data
 *
 *  @param data                 NSData object (can be a cache data of cache info data etc.)
 *
 *  @return the availability of a given data
 */
+ (BOOL)availabilityOfData:(NSData * _Nonnull)data;

/**
 *  This method is used to generate image file type string of a certain image data
 *
 *  @param imageData            image data
 *
 *  @return image file type
 */
+ (NSString * _Nullable)imageFileTypeForImageData:(NSData * _Nonnull)imageData;


///网络请求的url 及参数进行处理
/// @param url NSString
/// @param paramsDict NSDictionary
+ (NSString *_Nullable)appendAllUrlPostfix:(NSString *_Nullable)url
                                    params:(NSDictionary*_Nullable)paramsDict;

/// URL Decoding
/// @param urlString NSString
+ (NSString *_Nonnull)URLDecoding:(NSString *_Nonnull)urlString;

/// URL Encoding
/// @param urlString NSString
+ (NSString *_Nonnull)URLEncoding:(NSString *_Nonnull)urlString;

@end

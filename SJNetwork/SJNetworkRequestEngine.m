//
//  SJNetworkRequestManager.m
//  SJNetworkingDemo
//
//  Created by Sun Shijie on 2017/11/26.
//  Copyright © 2017年 Shijie. All rights reserved.
//

#import "SJNetworkRequestEngine.h"
#import "SJNetworkCacheManager.h"
#import "SJNetworkRequestPool.h"
#import "SJNetworkUtils.h"
#import "SJNetworkProtocol.h"

@interface SJNetworkRequestEngine()<SJNetworkProtocol>

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@property (nonatomic, strong) SJNetworkCacheManager *cacheManager;

@property (nonatomic, assign) BOOL isDebugMode;

@end


@implementation SJNetworkRequestEngine{
    NSFileManager *_fileManager;
}


#pragma mark- ============== Life Cycle Methods ==============

-(void) enableJsonRequest:(BOOL) enableJson{
    if(enableJson){
        self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    }else{
        self.sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    }
}


- (instancetype)init{
    
    self = [super init];
    if (self) {
        
        //file  manager
        _fileManager = [NSFileManager defaultManager];                
        //AFSessionManager config
        _sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        
        //RequestSerializer
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        _sessionManager.requestSerializer.allowsCellularAccess = YES;
        _sessionManager.requestSerializer.timeoutInterval = [self timeoutInterval];
        //securityPolicy
        _sessionManager.securityPolicy = [AFSecurityPolicy defaultPolicy];
        [_sessionManager.securityPolicy setAllowInvalidCertificates:YES];
        _sessionManager.securityPolicy.validatesDomainName = NO;
        
        //ResponseSerializer
        _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        _sessionManager.responseSerializer.acceptableContentTypes=[[NSSet alloc] initWithObjects:@"application/xml", @"text/xml",@"text/html", @"application/json",@"text/plain",nil];
        
        //Queue
        _sessionManager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _sessionManager.operationQueue.maxConcurrentOperationCount = 5;
        
    }
    return self;
}

#pragma mark- ============== Public Methods ==============
- (NSString *)baseURL{
    return @"https://app.yotu.cn/";
}


- (void)sendRequest:(NSString *)url
             method:(SJRequestMethod)method
         parameters:(id)parameters
            success:(SJSuccessBlock)successBlock
            failure:(SJFailureBlock)failureBlock{
    NSString *subUrlString = url;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if ([self defaultParameters].count) {
        [dict addEntriesFromDictionary:[self defaultParameters]];
    }
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];//获取当前时间0秒后的时间
    NSTimeInterval time = [date timeIntervalSince1970];
    [dict setValue:[NSNumber numberWithInteger:time] forKey:@"time"];
    if (method == SJRequestMethodGET){
        if (parameters && [parameters isKindOfClass:[NSDictionary class]]){
            [dict addEntriesFromDictionary:parameters];
        }
    }
    if ([self isAutoSignURL]) {
        subUrlString = [self signURL:url parameters:dict];
    }
    if (method == SJRequestMethodPOST){
        if (parameters && [parameters isKindOfClass:[NSDictionary class]]){
            [dict addEntriesFromDictionary:parameters];
        }
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@",[self baseURL],subUrlString];
    NSString *methodStr = [self p_methodStringFromRequestMethod:method];
    //generate a unique identifer of a certain request
    NSString *requestIdentifer = [SJNetworkUtils generateRequestIdentiferWithUrlStr:subUrlString methodStr:methodStr parameters:parameters];
    [self p_sendRequestWithCompleteUrlStr:urlString
                                   method:methodStr
                               parameters:parameters
                         requestIdentifer:requestIdentifer
                                  success:successBlock
                                  failure:failureBlock];
}


/// URL地址+参数 生成带有签名的新的地址
/// @param urlString NSString
/// @param parameters NSDictionary
- (NSString *)signURL:(NSString *)urlString
           parameters:(NSDictionary *)parameters{
    return [SJNetworkUtils URLEncoding:[SJNetworkUtils appendAllUrlPostfix:urlString params:parameters]];;
}

- (NSDictionary *)defaultParameters{
    NSDictionary *dict = @{@"vc":@"1.1.10",
                                   @"platform":@"iOS", @"appid":@"yotu", @"os_type":@"Ios", @"ch":@"appstore", @"brand":@"iPhone10,3", @"mf":@"apple", @"m2":@"A3AD912C-5F56-4E3C-BE8E-3C840C231E5A", @"re":@"1000", @"jsvc":@"1", @"svc": @"1", @"sys":@"iPhone10,3", @"os_name":@"14.2"};
    return dict;
}


- (NSTimeInterval)timeoutInterval{
    return 30;
}

#pragma mark- ============== Private Methods ==============

- (void)p_sendRequestWithCompleteUrlStr:(NSString *)completeUrlStr
                                 method:(NSString *)methodStr
                             parameters:(id)parameters
                       requestIdentifer:(NSString *)requestIdentifer
                                success:(SJSuccessBlock)successBlock
                                failure:(SJFailureBlock)failureBlock{
    
    //add customed headers
    [self addCustomHeaders];
    //add default parameters
    NSDictionary * completeParameters = [self addDefaultParametersWithCustomParameters:parameters];
    //create corresponding request model
    SJNetworkRequestModel *requestModel = [[SJNetworkRequestModel alloc] init];
    requestModel.requestUrl = completeUrlStr;
    requestModel.requestIdentifer = requestIdentifer;
    requestModel.method = methodStr;
    requestModel.parameters = completeParameters;
    requestModel.successBlock = successBlock;
    requestModel.failureBlock = failureBlock;
    //create a session task corresponding to a request model
    NSError * __autoreleasing requestSerializationError = nil;
    NSURLSessionDataTask *dataTask = [self p_dataTaskWithRequestModel:requestModel
                                                    requestSerializer:_sessionManager.requestSerializer
                                                                error:&requestSerializationError];
    
    
    //save task info request model
    requestModel.task = dataTask;
    //save this request model into request set
    [[SJNetworkRequestPool sharedPool] addRequestModel:requestModel];
    if (_isDebugMode) {
        SJLog(@"=========== Start requesting...\n =========== url:%@\n =========== method:%@\n =========== parameters:%@",completeUrlStr,methodStr,completeParameters);
    }
    //start request
    [dataTask resume];
}


- (NSURLSessionDataTask *)p_dataTaskWithRequestModel:(SJNetworkRequestModel *)requestModel
                                 requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                             error:(NSError * _Nullable __autoreleasing *)error{
    
    //create request
    NSMutableURLRequest *request = [requestSerializer requestWithMethod:requestModel.method
                                                              URLString:requestModel.requestUrl
                                                             parameters:requestModel.parameters
                                                                  error:error];
    
    //create data task
    __weak __typeof(self) weakSelf = self;
    NSURLSessionDataTask * dataTask = [_sessionManager dataTaskWithRequest:request
                                                            uploadProgress:nil
                                                          downloadProgress:nil
                                                         completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error){
        if (self->_isDebugMode) {
            SJLog(@"response url : %@\r\n responseObject: %@",response.URL,responseObject);
        }
        [weakSelf p_handleRequestModel:requestModel responseObject:responseObject error:error];
                                  }];
    
    return dataTask;
    
}

- (void)p_handleRequestModel:(SJNetworkRequestModel *)requestModel
              responseObject:(id)responseObject
                       error:(NSError *)error{
    
    NSError *requestError = nil;
    BOOL requestSucceed = YES;
    
    //check request state
    if (error) {
        requestSucceed = NO;
        requestError = error;
    }
    
    if (requestSucceed) {
        requestModel.responseObject = responseObject;
        [self requestDidSucceedWithRequestModel:requestModel];
        
    } else {
        [self requestDidFailedWithRequestModel:requestModel error:requestError];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self handleRequesFinished:requestModel];
    });
    
}

- (NSString *)p_methodStringFromRequestMethod:(SJRequestMethod)method{
    switch (method) {
        case SJRequestMethodGET:{
            return @"GET";
        }
            break;
        case SJRequestMethodPOST:{
            return  @"POST";
        }
            break;
        case SJRequestMethodPUT:{
            return  @"PUT";
        }
            break;
        case SJRequestMethodDELETE:{
            return  @"DELETE";
        }
            break;
    }
}


#pragma mark- ============== Override Methods ==============

- (void)requestDidSucceedWithRequestModel:(SJNetworkRequestModel *)requestModel{
    //write cache
    if (requestModel.cacheDuration > 0) {
        requestModel.responseData = [NSJSONSerialization dataWithJSONObject:requestModel.responseObject options:NSJSONWritingPrettyPrinted error:nil];
        if (requestModel.responseData) {
            [_cacheManager writeCacheWithReqeustModel:requestModel asynchronously:YES];
        }else{
            if (_isDebugMode) {
                SJLog(@"=========== Failded to write cache, since something was wrong when transfering response data");
            }
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->_isDebugMode) {
            SJLog(@"=========== Request succeed! \n =========== Request url:%@\n =========== Response object:%@", requestModel.requestUrl,requestModel.responseObject);
        }
        
        if (requestModel.successBlock) {
            requestModel.successBlock(requestModel.responseObject);
        }
    });
    
}


- (void)requestDidFailedWithRequestModel:(SJNetworkRequestModel *)requestModel error:(NSError *)error{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->_isDebugMode) {
            SJLog(@"=========== Request failded! \n =========== Request model:%@ \n =========== NSError object:%@ \n =========== Status code:%ld",requestModel,error,(long)error.code);
        }
        if (requestModel.failureBlock){
            requestModel.failureBlock(requestModel.task, error, error.code);
        }
    });
}


- (id)addDefaultParametersWithCustomParameters:(id)parameters{
    //if there is default parameters, then add them into custom parameters
    id parameters_spliced = nil;
    if (parameters && [parameters isKindOfClass:[NSDictionary class]]) {
        if ([[self.defaultParameters allKeys] count] > 0) {
            NSMutableDictionary *defaultParameters_m = [self.defaultParameters mutableCopy];
            [defaultParameters_m addEntriesFromDictionary:parameters];
            parameters_spliced = [defaultParameters_m copy];
            
        }else{
            parameters_spliced = parameters;
        }
    }else if(parameters && [parameters isKindOfClass:[NSArray class]]) {
        parameters_spliced = parameters;
    }else{
        parameters_spliced = self.defaultParameters;
    }
    return parameters_spliced;
}


- (void)addCustomHeaders{
    
    //add custom header
    NSDictionary *customHeaders = [self customHeader];
    if ([customHeaders allKeys] > 0) {
        NSArray *allKeys = [customHeaders allKeys];
        if ([allKeys count] >0) {
            [customHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL * _Nonnull stop) {
                [_sessionManager.requestSerializer setValue:value forHTTPHeaderField:key];
                if (_isDebugMode) {
                    SJLog(@"=========== added header:key:%@ value:%@",key,value);
                }
            }];
        }
    }
}



#pragma mark- ============== SJNetworkProtocol ==============

- (void)handleRequesFinished:(SJNetworkRequestModel *)requestModel{
    
    //clear all blocks
    [requestModel clearAllBlocks];
    //remove this requst model from request queue
    [[SJNetworkRequestPool sharedPool] removeRequestModel:requestModel];
    
}




@end

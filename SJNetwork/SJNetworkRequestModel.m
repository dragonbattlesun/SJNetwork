//
//  SJNetworkRequestModel.m
//  SJNetwork
//
//  Created by Sun Shijie on 2017/8/17.
//  Copyright © 2017年 Shijie. All rights reserved.
//

#import "SJNetworkRequestModel.h"
#import "SJNetworkUtils.h"

@interface SJNetworkRequestModel()

@property (nonatomic, readwrite, copy) NSString *cacheDataFilePath;
@property (nonatomic, readwrite, copy) NSString *cacheDataInfoFilePath;

@property (nonatomic, readwrite, copy) NSString *resumeDataFilePath;
@property (nonatomic, readwrite, copy) NSString *resumeDataInfoFilePath;

@end


@implementation SJNetworkRequestModel

#pragma mark- ============== Public Methods ==============


- (SJRequestType)requestType{
    return SJRequestTypeOrdinary;
}


- (void)clearAllBlocks{
    _successBlock = nil;
    _failureBlock = nil;
}


#pragma mark- ============== Override Methods ==============

- (NSString *)description{
    if (self.debugMode) {
        switch (self.requestType) {
            case SJRequestTypeOrdinary:
                return [NSString stringWithFormat:@"\n{\n   <%@: %p>\n   type:            oridnary request\n   method:          %@\n   url:             %@\n   parameters:      %@\n   loadCache:       %@\n   cacheDuration:   %@ seconds\n   requestIdentifer:%@\n   task:            %@\n}" ,NSStringFromClass([self class]),self,_method,_requestUrl,_parameters,_loadCache?@"YES":@"NO",[NSNumber numberWithInteger:_cacheDuration],_requestIdentifer,_task];
                break;
            default:
                return [NSString stringWithFormat:@"\n  request type:unkown request type\n  request object:%@",self];
                break;
        }
    }else{

         return [NSString stringWithFormat:@"<%@: %p>" ,NSStringFromClass([self class]),self];
    }
}

@end

//
//  SJNetworkBaseEngine.m
//  SJNetworkingDemo
//
//  Created by Sun Shijie on 2017/12/26.
//  Copyright © 2017年 Shijie. All rights reserved.
//

#import "SJNetworkBaseEngine.h"

@implementation SJNetworkBaseEngine

- (NSString *)baseURL{
    return @"";
}

- (BOOL)isAutoSignURL{
    return YES;
}


- (NSDictionary *)customHeader{
    return @{};
}

- (NSDictionary *)defaultParameters{
    return @{};
}

- (void)addCustomHeaders{
    
}

- (id)addDefaultParametersWithCustomParameters:(id)parameters{
    return nil;
}


- (void)requestDidSucceedWithRequestModel:(SJNetworkRequestModel *)requestModel{
        
}

- (void)requestDidFailedWithRequestModel:(SJNetworkRequestModel *)requestModel error:(NSError *)error{
        
}

@end

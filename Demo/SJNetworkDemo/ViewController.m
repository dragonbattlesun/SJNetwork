//
//  ViewController.m
//  SJNetworkDemo
//
//  Created by sunxuzhu on 2021/5/18.
//

#import "ViewController.h"
#import "SJNetwork.h"
#define kURL_HomeNavigatelist  @"home/navigate/list"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self allChannelResult:nil failBlock:^{
        
    }];
}

/// 首页编辑 获取全部分类接口
/// @param successBlock 获取数据接口
/// @param failBlock 失败
-(void)allChannelResult:(void (^)(NSArray *data))successBlock
              failBlock:(void(^)(void))failBlock{
    SJNetworkRequestEngine *requestEngine = [[SJNetworkRequestEngine alloc] init];
    [requestEngine sendRequest:kURL_HomeNavigatelist
                        method:SJRequestMethodGET
                    parameters:nil success:^(id responseObject) {
            
        
    } failure:^(NSURLSessionTask *task, NSError *error, NSInteger statusCode) {
            
        
    }];
}

@end

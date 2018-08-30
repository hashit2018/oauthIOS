//
//  ViewController.m
//  CwtchAuth
//
//  Created by 林域 on 2018/8/22.
//  Copyright © 2018年 林域. All rights reserved.
//

#import "ViewController.h"
#import "CwtchSDK.h"
#import "AFNetworking.h"
#import "LoginTestViewController.h"


@interface ViewController ()

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)authLogin:(id)sender {
    
    CwtchAuthorizeRequest *request = [CwtchAuthorizeRequest new];
    request.state = @"Verification";
    request.redirectURI = @"http://your_callback_uri";
    [CwtchSDK sendRequest:request];
}

- (void)loginByAuthCode:(NSDictionary *)params {
    if (![params isKindOfClass:[NSDictionary class]] && params!=nil) return;
    
    NSString *path = @"loginByAuthCode";
    NSString *baseUrlStr = @"http://192.168.254.141:1112";
    [self requestWithBaseURL:baseUrlStr path:path params:params];
}

- (void)requestWithBaseURL:(NSString *)baseUrlStr
                      path:(NSString *)path
                    params:(NSDictionary *)params
{
    NSURL *baseUrl = [NSURL URLWithString:baseUrlStr];
    NSMutableDictionary *dict = params.mutableCopy;
    [dict setObject:Appkey forKey:@"ClientId"];
    [dict setObject:Appkey forKey:@"ClientSecret"];
    params = dict;
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseUrl];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/json",@"text/javascript",@"text/html",@"text/plain",nil];
    
    [manager POST:path parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == 20000) {
            
            LoginTestViewController *loginVC = [LoginTestViewController new];
            loginVC.responseObject = responseObject;
            [self presentViewController:loginVC animated:YES completion:nil];
            NSLog(@" ------------ login susscess! ------------ ");
        }
        else {
            NSString *message = [NSString stringWithFormat:@"%@",responseObject[@"desc"]];
            [self showFailResponseAlert:message];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSString *message = [NSString stringWithFormat:@"%@",error];
        [self showFailResponseAlert:message];
    }];
}
- (void)showFailResponseAlert:(NSString *)error {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"请求失败" message:error preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"确定"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alertController addAction:actionCancel];
    [self presentViewController:alertController animated:YES completion:nil];
}



@end

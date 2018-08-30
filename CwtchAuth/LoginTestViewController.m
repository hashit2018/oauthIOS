//
//  LoginTestViewController.m
//  CwtchAuth
//
//  Created by 林域 on 2018/8/29.
//  Copyright © 2018年 林域. All rights reserved.
//

#import "LoginTestViewController.h"
#import "AFNetworking.h"

@interface LoginTestViewController ()
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (nonatomic, copy) NSString *content;
@end

@implementation LoginTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.logoutButton];
    [self.view addSubview:self.infoLabel];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.infoLabel.text = _content;
}

-(void)setResponseObject:(NSDictionary *)responseObject{
    _responseObject = responseObject;
    
    NSDictionary *data = responseObject[@"data"];
    if (data == nil) {
        return;
    }
    NSString *tipStr = @"登录成功";
    NSString *infoStr = [NSString stringWithFormat:@"%@\n用户信息：\n昵称 = %@\n帐号 = %@\n区号 = %@\n手机号 = %@\nuuid = %@\n ",tipStr,data[@"nickname"],data[@"name"],data[@"nationCode"],data[@"mobile"],data[@"uuid"]];
    NSLog(@"infoStr = %@",infoStr);
    _content = infoStr;
    self.infoLabel.text = infoStr;
}

- (IBAction)logout:(id)sender {
    
    NSString *path = @"logout";
    NSString *baseUrlStr = @"http://192.168.254.141:1112";
    [self requestWithBaseURL:baseUrlStr path:path params:nil];
}

- (void)requestWithBaseURL:(NSString *)baseUrlStr
                      path:(NSString *)path
                    params:(NSDictionary *)params
{
    NSURL *baseUrl = [NSURL URLWithString:baseUrlStr];
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseUrl];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/json",@"text/javascript",@"text/html",@"text/plain",nil];
    [manager POST:path parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == 20000) {
            NSLog(@" ------------ logout success! ------------");
            [self dismissViewControllerAnimated:YES completion:nil];
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

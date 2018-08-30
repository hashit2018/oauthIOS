//
//  AppDelegate.m
//  CwtchAuth
//
//  Created by 林域 on 2018/8/22.
//  Copyright © 2018年 林域. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "CwtchSDK.h"
@interface AppDelegate ()<CwtchSDKDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [CwtchSDK registerApp:Appkey];
    [CwtchSDK setLanguageType:CwtchSDKLanguageTypeChinese];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark -
- (void)didReceiveCwtchResponse:(CwtchBaseResponse *)response responseStatusCode:(CwtchSDKResponseStatusCode)responseStatusCode {
    
    if (responseStatusCode == CwtchSDKResponseStatusCodeSuccess) {
        CwtchSuccessedResponse *authorizeResponse = (CwtchSuccessedResponse *)response;
        NSString *requestState = authorizeResponse.requestState;
        NSString *accessToken = authorizeResponse.accessToken;
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        int num = (arc4random() % 10000000000);
        
        NSString *randomNumber = [NSString stringWithFormat:@"%.10d", num];
        parameters[@"state"] = requestState;
        parameters[@"redirectUri"] = kRedirectURI;
        parameters[@"code"] = accessToken;
        parameters[@"nonce"] = randomNumber;
        
        UINavigationController *rootNav = (UINavigationController *)self.window.rootViewController;
        ViewController *rootVC = rootNav.viewControllers.firstObject;
        [rootVC loginByAuthCode:parameters];
    }
    else if (responseStatusCode == CwtchSDKResponseStatusCodeAuthDeny) {
        CwtchFailedResponse *authorizeResponse = (CwtchFailedResponse *)response;
        NSString *errorCode = authorizeResponse.errorCode;
        NSString *errorCodeDescription = authorizeResponse.errorCodeDescription;
        NSString *message = [NSString stringWithFormat:@"response.errorCode:%@\nresponse.errorCodeDescription:%@",errorCode,errorCodeDescription];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"授权失败" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"确定"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        [alertController addAction:actionCancel];
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
    }
    else if (responseStatusCode == CwtchSDKResponseStatusCodeUserCancel) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"用户点击取消" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"确定"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        [alertController addAction:actionCancel];
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
    }
    else if (responseStatusCode == CwtchSDKResponseStatusCodeUserCancelInstall) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"用户取消下载" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"确定"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        [alertController addAction:actionCancel];
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
    }
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    return [CwtchSDK handleOpenURL:url delegate:self];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [CwtchSDK handleOpenURL:url delegate:self];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [CwtchSDK handleOpenURL:url delegate:self ];
}

@end

//
//  CwtchSDK.h
//  CwtchSDK
//
//  Created by dn4 on 2018/5/25.
//  Copyright © 2018年 zml. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CwtchSDKDelegate;
@class    CwtchBaseRequest;
@class    CwtchBaseResponse;
@class    CwtchAuthorizeRequest;

typedef NS_ENUM(NSInteger, CwtchSDKResponseStatusCode)
{
    CwtchSDKResponseStatusCodeSuccess               =  0,//授权成功
    CwtchSDKResponseStatusCodeUserCancel            = -1,//用户取消
    CwtchSDKResponseStatusCodeAuthDeny              = -2,//授权失败
    CwtchSDKResponseStatusCodeUserCancelInstall     = -3,//用户取消安装Cwtch客户端
};

typedef NS_ENUM(NSInteger, CwtchSDKLanguageType)
{
    CwtchSDKLanguageTypeChinese               = -1,//中文
    CwtchSDKLanguageTypeEnglish               = -2,//英文
};

@interface CwtchSDK : NSObject

/**
 检查用户是否安装了Cwtch客户端程序
 @return 已安装返回YES，未安装返回NO
 */
+ (BOOL)isCwtchAppInstalled;

/**
 获取当前CwtchSDK的版本号
 @return 当前CwtchSDK的版本号
 */
+ (NSString *)getSDKVersion;

/**
 设置语言
 @param languageType 设置语言，默认跟随系统，若系统语言为中文，则为简体中文，否则，为英文
 @return 语言设置成功返回YES，失败返回NO
 */
+ (BOOL)setLanguageType:(CwtchSDKLanguageType)languageType;

/**
 向Cwtch客户端程序注册第三方应用
 @param appKey Cwtch开放平台第三方应用appKey
 @return 注册成功返回YES，失败返回NO
 */
+ (BOOL)registerApp:(NSString *)appKey;

/**
 处理Cwtch客户端程序通过URL启动第三方应用时传递的数据
 
 需要在 application:openURL:sourceApplication:annotation:、application:handleOpenURL或者application:openURL:options:中调用
 @param url 启动第三方应用的URL
 @param delegate CwtchSDKDelegate对象，用于接收Cwtch触发的消息
 @see CwtchSDKDelegate
 */
+ (BOOL)handleOpenURL:(NSURL *)url delegate:(id<CwtchSDKDelegate>)delegate;

/**
 发送请求给Cwtch客户端程序，并切换到Cwtch
 
 请求发送给Cwtch客户端程序之后，Cwtch客户端程序会进行相关的处理，处理完成之后一定会调用 [CwtchSDKDelegate didReceiveCwtchResponse:responseStatusCode:] 方法将处理结果返回给第三方应用
 
 @param request 具体的发送请求
 
 @see [CwtchSDKDelegate didReceiveCwtchResponse:responseStatusCode:]
 @see CwtchBaseRequest
 */
+ (BOOL)sendRequest:(CwtchBaseRequest *)request;

@end

/**
 接收并处理来至Cwtch客户端程序的事件消息
 */
@protocol CwtchSDKDelegate <NSObject>

/**
 收到一个来自Cwtch客户端程序的响应
 
 收到Cwtch的响应后，第三方应用可以通过响应类型、响应的数据完成自己的功能
 @param response 具体的响应对象
 */
- (void)didReceiveCwtchResponse:(CwtchBaseResponse *)response responseStatusCode:(CwtchSDKResponseStatusCode)responseStatusCode;

@end

#pragma mark - Base Request/Response
/**
 Cwtch客户端程序和第三方应用之间传输数据信息的基类
 */
@interface CwtchBaseRequest : NSObject

/**
 自定义信息字符串，用于数据传输过程中校验相关的上下文环境数据
 
 如果未填写，则response.requestState为空；若填写，响应成功时，则 response.requestState 和原 request.state 中的数据保持一致
 */
@property (nonatomic, strong) NSString *state;

/**
 返回一个 CwtchBaseRequest 对象
 
 @return 返回一个*自动释放的*CwtchBaseRequest对象
 */
+ (id)request;

@end

/**
 CwtchSDK所有响应类的基类
 */
@interface CwtchBaseResponse : NSObject

/**
 返回一个 CwtchBaseResponse 对象
 
 @return 返回一个*自动释放的*CwtchBaseResponse对象
 */
+ (id)response;

@end

#pragma mark - Authorize Request/Response
/**
 第三方应用向Cwtch客户端请求认证的消息结构
 
 第三方应用向Cwtch客户端申请认证时，需要调用 [CwtchSDK sendRequest:] 函数， 向Cwtch客户端发送一个 CwtchAuthorizeRequest 的消息结构。
 Cwtch客户端处理完后会向第三方应用发送一个结构为 CwtchBaseResponse 的处理结果。
 */
@interface CwtchAuthorizeRequest : CwtchBaseRequest

/**
 Cwtch开放平台第三方应用授权回调页地址
 
 @warning 必须保证和在Cwtch开放平台应用管理界面配置的“授权回调页”地址一致
 @warning 不能为空，长度小于1K
 */
@property (nonatomic, strong) NSString *redirectURI;

/**
 以空格分隔的权限列表，若不传递此参数，代表请求用户的默认权限
 参考开放平台权限列表
 @warning 长度小于1K
 */
@property (nonatomic, strong) NSString *scope;
@end

/**
 CwtchSDK处理完第三方应用的认证申请后向第三方应用回送的处理结果
 
 CwtchSuccessedResponse 结构中包含常用的 requestState、accessToken
 */
@interface CwtchSuccessedResponse : CwtchBaseResponse

/**
 对应的 request 中的state
 
 如果当前 response 是由CwtchSDK响应给第三方应用的，则 requestState 和原 request.state 中的数据保持一致
 
 @see CwtchBaseRequest.state
 */
@property (nonatomic, strong) NSString *requestState;

/**
 认证口令
 */
@property (nonatomic, strong) NSString *accessToken;

@end

@interface CwtchFailedResponse : CwtchBaseResponse
/**
 响应状态码
 
 参考：访问开发文档->OAuth2.0->开发相关资源->返回状态码说明
 
 第三方应用可以通过errorCode判断请求的处理结果
 */
@property (nonatomic, strong) NSString *errorCode;

/**
 响应状态码描述
 
 参考：访问开发文档->OAuth2.0->开发相关资源->返回状态码说明
 
 第三方应用可以通过errorCodeDescription判断请求的显示结果
 */
@property (nonatomic, strong) NSString *errorCodeDescription;

@end


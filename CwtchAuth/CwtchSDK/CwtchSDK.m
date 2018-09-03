//
//  CwtchSDK.m
//  CwtchAuth
//
//  Created by 林域 on 2018/8/22.
//  Copyright © 2018年 林域. All rights reserved.

#import "CwtchSDK.h"
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonCrypto.h>

static NSString *LMAESSecretKey = @"lmAESSecretKey";
size_t const LMAESKeySize = kCCKeySizeAES128;
NSString *const LMAESInitVector = @"16-Bytes--String";

@interface BGLStringUtils:NSObject
@end
@implementation BGLStringUtils
+(BOOL)isEmpty:(id)instance{
    
    return instance == nil || [instance isKindOfClass:[NSNull class]];
}

+(BOOL)isNotEmpty:(id)instance{
    
    return instance != nil && [instance isKindOfClass:[NSNull class]];
}

@end

@interface BGLUrlUtils:NSObject
@end
@implementation BGLUrlUtils
+ (NSString*)setValue:(NSString *)val forKey:(NSString *)key withURL:(NSString *)url{
    if (url==nil) {
        return nil;
    }
    NSScanner *scanner = [NSScanner scannerWithString:url];
    //先带上&查，如果查不到再用？号来查，两者都查不到则使用追加参数
    NSString *stopStr = [NSString stringWithFormat:@"&%@=",key];
    NSString *tmp;
    [scanner scanUpToString:stopStr intoString:&tmp];
    if ([scanner isAtEnd]) { //找不到，使用？找
        stopStr = [NSString stringWithFormat:@"?%@=",key];
        [scanner setScanLocation:0];
        tmp = nil;
        [scanner scanUpToString:stopStr intoString:&tmp];
        if ([scanner isAtEnd]) {
            if ([url rangeOfString:@"?"].length>0) {
                if (val==nil) {
                    return url;
                }else {
                    url = [url stringByAppendingFormat:@"&%@=%@", key, val];
                }
            }else {
                if (val==nil) {
                    return url;
                }else {
                    url = [url stringByAppendingFormat:@"?%@=%@", key, val];
                }
            }
            return url;
        }else { //找到？好开始的 如 ？p=
            [scanner scanString:stopStr intoString:nil];
            
            NSString *tailStr;
            [scanner scanUpToString:@"&" intoString:nil];
            if ([scanner isAtEnd]) {
                if (val==nil) {
                    return tmp;
                }
                return [NSString stringWithFormat:@"%@?%@=%@", tmp, key, val];
            }
            [scanner scanUpToString:@"!!!" intoString:&tailStr];
            if (val==nil) {
                return [NSString stringWithFormat:@"%@?%@", tmp, tailStr];
            }
            return [NSString stringWithFormat:@"%@?%@=%@%@", tmp, key, val, tailStr];
            
        }
        
        
    }else { //找到了&号开始的，替换并返回
        [scanner scanString:stopStr intoString:nil];
        
        NSString *tailStr;
        [scanner scanUpToString:@"&" intoString:nil];
        if ([scanner isAtEnd]) {
            if (val==nil) { //赋予的值是空的话,清空字段
                return tmp;
            }else {
                return [NSString stringWithFormat:@"%@&%@=%@", tmp, key, val];
            }
        }
        [scanner scanUpToString:@"!!!" intoString:&tailStr];
        if (val==nil) {
            return [NSString stringWithFormat:@"%@%@", tmp, tailStr];
        }else {
            return [NSString stringWithFormat:@"%@&%@=%@%@", tmp, key, val, tailStr];
        }
    }
}

+ (NSString*)setDictionary:(NSDictionary *)dict forURL:(NSString *)url{
    if(dict && dict.allKeys.count > 0){
        [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]]) {
                [self setValue:obj forKey:key];
            }
        }];
    }
    return url;
}


//解析出url地址的参数,比如传进 viewthread.php?tid=xxx&abc
+ (NSString*)getValueForKey:(NSString *)Key withURL:(NSString *)url{
    if (url==nil || Key==nil) {
        return nil;
    }
    NSString *res = [self getUrlParamCore:url forParam:[@"&" stringByAppendingString:Key]];
    if ([res length]==0) {
        res = [self getUrlParamCore:url forParam:[@"?" stringByAppendingString:Key]];
    }
    return res;
}

+(NSString *)getUrlParamCore:(NSString *)url forParam:(NSString *)paramName {
    if (url==nil) {
        return nil;
    }
    NSScanner *scanner = [NSScanner scannerWithString:url];
    NSString *stopStr = [paramName stringByAppendingString:@"="];
    
    [scanner scanUpToString:stopStr intoString:nil];
    if ([scanner isAtEnd]) {
        return @"";
    }
    
    [scanner scanString:stopStr intoString:nil];
    NSString *result;
    [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"&"] intoString:&result];
    return result;
}
/**
 *  截取URL中的参数
 *  urlStr 原始链接
 *  allowValueEmpty 值为empty的是否返回
 *  @return NSMutableDictionary parameters
 */
+ (NSMutableDictionary *)getURL:(NSString *)urlStr allowValueEmpty:(BOOL)allowValueEmpty{
    // 以字典形式将参数返回
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    @try {
        // 查找参数
        NSRange range = [urlStr rangeOfString:@"?"];
        if (range.location == NSNotFound) {
            return params;
        }
        
        // 截取参数
        NSString *parametersString = [urlStr substringFromIndex:range.location + 1];
        // 判断参数是单个参数还是多个参数
        if ([parametersString containsString:@"&"]) {
            
            // 多个参数，分割参数
            NSArray *urlComponents = [parametersString componentsSeparatedByString:@"&"];
            
            for (NSString *keyValuePair in urlComponents) {
                // 生成Key/Value
                NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
                NSString *key = nil;
                NSString *value = nil;
                
                if (pairComponents.count >= 2) {
                    key = [pairComponents.firstObject stringByRemovingPercentEncoding];
                    value = [pairComponents.lastObject stringByRemovingPercentEncoding];
                }else if(pairComponents.count == 1){
                    key = [pairComponents.firstObject stringByRemovingPercentEncoding];
                    value = @"";
                }
                
                // key 不能为nil和空  value不能为nil
                if (key == nil || [BGLStringUtils isEmpty:key] || value == nil) {
                    continue;
                }
                //value不允许空时，跳过
                if (!allowValueEmpty && [BGLStringUtils isEmpty:value]) {
                    continue;
                }
                
                id existValue = [params valueForKey:key];
                
                if (existValue != nil) {
                    
                    // 已存在的值，生成数组
                    if ([existValue isKindOfClass:[NSArray class]]) {
                        // 已存在的值生成数组
                        NSMutableArray *items = [NSMutableArray arrayWithArray:existValue];
                        [items addObject:value];
                        
                        [params setValue:items forKey:key];
                    } else {
                        
                        // 非数组
                        [params setValue:@[existValue, value] forKey:key];
                    }
                    
                } else {
                    
                    // 设置值
                    [params setValue:value forKey:key];
                }
            }
        } else {
            // 单个参数
            // 生成Key/Value
            NSArray *pairComponents = [parametersString componentsSeparatedByString:@"="];
            NSString *key = nil;
            NSString *value = nil;
            if (pairComponents.count >= 2) {
                key = [pairComponents.firstObject stringByRemovingPercentEncoding];
                value = [pairComponents.lastObject stringByRemovingPercentEncoding];
            }else if(pairComponents.count == 1){
                key = [pairComponents.firstObject stringByRemovingPercentEncoding];
                value = @"";
            }
            // Key不能为nil
            if (key == nil || [BGLStringUtils isEmpty:key] || value == nil) {
                return params;
            }
            //value不允许空时，跳过
            if (!allowValueEmpty && [BGLStringUtils isEmpty:value]) {
                return params;;
            }
            
            // 设置值
            [params setValue:value forKey:key];
        }
        
    } @catch (NSException *exception) {
        NSLog(@"‼️‼️‼️%@",[exception description]);
        return params;
    }
    
    return params;
}

//获取URL的参数值，兼容key相同 如：?key=1&key=2&p=2&key=3&key=4&key=5&p=2
+ (NSArray *)getValuesFromURL:(NSString *)url toSameKey:(NSString *)key{
    
    NSMutableArray *valueArray = [NSMutableArray array];
    NSString *str = url;
    NSString *patton = [NSString stringWithFormat:@"[?|&]%@=(\\w+)",key];
    NSArray *array =    nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:patton options:NSRegularExpressionCaseInsensitive error:nil];
    array = [regex matchesInString:str options:0 range:NSMakeRange(0, [str length])];
    
    NSString *value = nil;
    for (NSTextCheckingResult* b in array){
        for(int i=0;i<b.numberOfRanges;i++){
            value = [str substringWithRange:[b rangeAtIndex:i]];
            if(i == 1&& [BGLStringUtils isNotEmpty:value]){
                [valueArray addObject:value];
            }
        }
    }
    return valueArray;
}
@end

@interface CwtchSDKAES :NSObject
@end

@implementation CwtchSDKAES
#pragma mark - Public Methods
+ (NSString *)parameterEncryption:(NSDictionary *)parameter secretKey:(NSString *)aesSecretKey {
    
    NSString *secretKey =aesSecretKey?:@"";
    if (secretKey.length == 0) {
        return nil;
    }
    
    NSArray *keyArray = [parameter allKeys];
    NSArray *sortArray = [keyArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    
    NSMutableArray *valueArray = [NSMutableArray array];
    for (NSString *sortString in sortArray) {
        [valueArray addObject:[parameter objectForKey:sortString]];
    }
    
    NSMutableArray *signArray = [NSMutableArray array];
    for (int i = 0; i < sortArray.count; i++) {
        NSString *keyValueStr = [NSString stringWithFormat:@"%@=%@",sortArray[i],valueArray[i]];
        [signArray addObject:keyValueStr];
    }
    NSString *plainString = [signArray componentsJoinedByString:@"&"];
    NSData *contentData = [plainString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = contentData.length;
    // 为结束符'\\0' +1
    char keyPtr[LMAESKeySize + 1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [secretKey getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    // 密文长度 <= 明文长度 + BlockSize
    size_t encryptSize = dataLength + kCCBlockSizeAES128;
    void *encryptedBytes = malloc(encryptSize);
    size_t actualOutSize = 0;
    NSData *initVector = [LMAESInitVector dataUsingEncoding:NSUTF8StringEncoding];
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES,
                                          kCCOptionPKCS7Padding,  // 系统默认使用 CBC，然后指明使用 PKCS7Padding
                                          keyPtr,
                                          LMAESKeySize,
                                          initVector.bytes,
                                          contentData.bytes,
                                          dataLength,
                                          encryptedBytes,
                                          encryptSize,
                                          &actualOutSize);
    if (cryptStatus == kCCSuccess) {
        // 对加密后的数据进行 base64 编码
        NSString *result = [[NSData dataWithBytesNoCopy:encryptedBytes length:actualOutSize] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
        return result;
    }
    free(encryptedBytes);
    return nil;
}


+ (NSString *)parameterDecrypt:(NSString *)plainString secretKey:(NSString *)aesSecretKey {
    
    NSString *secretKey = aesSecretKey?:@"";
    if (secretKey.length == 0) {
        return nil;
    }
    
    // 把 base64 String 转换成 Data
    NSData *contentData = [[NSData alloc] initWithBase64EncodedString:plainString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSUInteger dataLength = contentData.length;
    char keyPtr[LMAESKeySize + 1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [secretKey getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    size_t decryptSize = dataLength + kCCBlockSizeAES128;
    void *decryptedBytes = malloc(decryptSize);
    size_t actualOutSize = 0;
    NSData *initVector = [LMAESInitVector dataUsingEncoding:NSUTF8StringEncoding];
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES,
                                          kCCOptionPKCS7Padding,
                                          keyPtr,
                                          LMAESKeySize,
                                          initVector.bytes,
                                          contentData.bytes,
                                          dataLength,
                                          decryptedBytes,
                                          decryptSize,
                                          &actualOutSize);
    if (cryptStatus == kCCSuccess) {
        NSString *result = [[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:decryptedBytes length:actualOutSize] encoding:NSUTF8StringEncoding];
        return result;
    }
    free(decryptedBytes);
    return nil;
}

//32位随机字符串
+ (NSString *)getAESRandomString {
    char data[32];
    for (int x = 0; x < 32; data[x++] = (char)('A' + (arc4random_uniform(26))));
    NSString *randomStr = [[NSString alloc] initWithBytes:data length:32 encoding:NSUTF8StringEncoding];
    return randomStr;
}

//AES 密钥
+ (NSString *)getAESSecretKey:(NSString *)randomString {
    
    randomString = randomString?:@"";
    if (randomString.length == 0) {
        return nil;
    }
    NSArray *SecretKeyCoordinateArr = @[@4,@0,@6,@10,@31,@5,@22,@7,@30,@1,@10,@10,@25,@17,@8,@19];
    
    NSString *secretKey = @"";
    for (NSNumber *tempIndex in SecretKeyCoordinateArr) {
        NSUInteger index = [tempIndex integerValue];
        if (index < randomString.length) {
            NSRange range = NSMakeRange(index, 1);
            NSString *str = [randomString substringWithRange:range];
            secretKey = [secretKey stringByAppendingString:str];
        }
    }
    return secretKey;
}
@end

@interface NSString (Extension)
@end

@implementation NSString (Extension)
+ (NSString*)toNotNullString:(NSString *)string{
    return string?:@"";
}

///将字典中的键值对加入到URL的参数部分(url.query)，并返回新的URL字符串
+ (NSString*)webURL:(NSURL*)url appendParams:(NSDictionary*)paramDic
{
    __block NSString *_urlAbsStr = url.absoluteString;
    
    NSString *_urlQuery = url.query?:@"";
    if (_urlQuery.length == 0) {
        _urlAbsStr = [_urlAbsStr stringByAppendingString:@"?"];
    }
    
    [paramDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (key) {
            NSString *_paramStr = [NSString stringWithFormat:@"&%@=%@", key, obj];
            _urlAbsStr = [_urlAbsStr stringByAppendingString:_paramStr];
        }
    }];
    
    _urlAbsStr = [_urlAbsStr stringByReplacingOccurrencesOfString:@"?&" withString:@"?"];
    _urlAbsStr = [_urlAbsStr stringByReplacingOccurrencesOfString:@"??" withString:@"?"];
    
    return _urlAbsStr;
}

- (NSDictionary *)parametersWithSeparator:(NSString *)separator delimiter:(NSString *)delimiter {
    NSArray *parameterPairs = [self componentsSeparatedByString:delimiter];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:[parameterPairs count]];
    for (NSString *currentPair in parameterPairs) {
        NSRange range = [currentPair rangeOfString:separator];
        if(range.location == NSNotFound)
            continue;
        NSString *key = [currentPair substringToIndex:range.location];
        NSString *value =[currentPair substringFromIndex:range.location + 1];
        [parameters setObject:value forKey:key];
    }
    return parameters;
}
@end

@interface NSMutableDictionary(Extension)

@end
@implementation NSMutableDictionary(Extension)

-(void)notNll_setObject:(id)obj forKey:(NSString *)key{
    [self setObject:obj?:@"" forKey:key];
}

@end

@implementation CwtchBaseRequest
+ (id)request{
    return [CwtchBaseRequest new];
}
@end

@implementation CwtchBaseResponse
+ (id)response{
    return [CwtchBaseResponse new];
}

@end

@implementation CwtchAuthorizeRequest
@end

@implementation CwtchSuccessedResponse
@end

@implementation CwtchFailedResponse
@end

@interface CwtchSDK ()
@property (nonatomic, weak)   id<CwtchSDKDelegate> delegate;
@property (nonatomic, assign) CwtchSDKLanguageType languageType;
@property (nonatomic, copy)   NSString *appKey;
@end

@implementation CwtchSDK
+(instancetype)shareInstance{
    static CwtchSDK *sdk;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sdk = [CwtchSDK new];
        [sdk initLanguage];
    });
    return sdk;
}

+ (BOOL)registerApp:(NSString *)appKey{
    [CwtchSDK shareInstance].appKey = appKey;
    return NO;
}

/**
 *  根据本机语言初始化
 */
- (void)initLanguage{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
    NSString *currentLanguage = [languages objectAtIndex:0];
    NSLog(@"currentLanguage  ==  %@", currentLanguage);
    self.languageType = [currentLanguage isEqualToString:@"en-CN"] ? CwtchSDKLanguageTypeEnglish : CwtchSDKLanguageTypeChinese;
}

+ (BOOL)isCwtchAppInstalled {
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cwtch://"]];
}

+ (NSString *)getSDKVersion{
    return @"1.0.0";
}

+ (BOOL)setLanguageType:(CwtchSDKLanguageType)languageType{
    [CwtchSDK shareInstance].languageType = languageType;
    return YES;
}

/**
 处理Cwtch客户端程序通过URL启动第三方应用时传递的数据
 
 需要在 application:openURL:sourceApplication:annotation:、application:handleOpenURL或者application:openURL:options:中调用
 @param url 启动第三方应用的URL
 @param delegate CwtchSDKDelegate对象，用于接收Cwtch触发的消息
 @see CwtchSDKDelegate
 */
+ (BOOL)handleOpenURL:(NSURL *)url delegate:(id<CwtchSDKDelegate>)delegate{
    
    NSString *query = [NSString toNotNullString:url.query];
    NSDictionary *dic = [query parametersWithSeparator:@"=" delimiter:@"&"];
    
    if (dic == nil) {
        return NO;
    }
    
    CwtchBaseResponse *response;
    CwtchSDKResponseStatusCode code;
    NSString *signData      = [NSString toNotNullString:dic[@"id"]];
    NSString *randomString  = [NSString toNotNullString:dic[@"tk"]];
    NSDictionary *plainData = nil;
        
    if (signData.length && randomString.length) {
        NSString *aesSecretKey = [CwtchSDKAES getAESSecretKey:randomString];
        NSString *plainString  = [CwtchSDKAES parameterDecrypt:signData secretKey:aesSecretKey];
        plainData = [plainString parametersWithSeparator:@"=" delimiter:@"&"];
        
        if (plainData) {
            response = [CwtchSDK createResponseWithCode:plainData];
            code = [plainData[@"statusCode"] integerValue];
            
            if (delegate != nil && [delegate respondsToSelector:@selector(didReceiveCwtchResponse:responseStatusCode:)]) {
                [delegate didReceiveCwtchResponse:response responseStatusCode:code];
            }else{
                NSLog(@"didReceiveCwtchResponse 方法没有实现！！！");
                return NO;
            }
        }
        
    }else{ // 返回结果不符合规范 或者解析出来不正确
        if (delegate != nil && [delegate respondsToSelector:@selector(didReceiveCwtchResponse:responseStatusCode:)]) {
            CwtchFailedResponse *failResponse = [CwtchFailedResponse new];
            failResponse.errorCode = @"";
            failResponse.errorCodeDescription = [CwtchSDK shareInstance].languageType == CwtchSDKLanguageTypeChinese ? @"数据不正确" : @"Data error";
            [delegate didReceiveCwtchResponse:failResponse responseStatusCode:CwtchSDKResponseStatusCodeAuthDeny];
            
        }else{
            NSLog(@"didReceiveCwtchResponse 方法没有实现！！！");
            return NO;
        }
    }
    return YES;
}

/**
 根据statusCode返回一个合适的BaseResponse对象
 */
+(CwtchBaseResponse *)createResponseWithCode:(NSDictionary *)dict{
    CwtchBaseResponse *baseResponse;
    NSInteger code = [dict[@"statusCode"] integerValue];
    switch (code) {
        case 0:{//授权成功
            CwtchSuccessedResponse *response = [CwtchSuccessedResponse new];
            response.requestState = dict[@"state"];
            response.accessToken  = dict[@"code"];
            baseResponse = response;
        }
            break;
        case -2:{//授权失败
            CwtchFailedResponse *respnse = [CwtchFailedResponse new];
            respnse.errorCode = dict[@"error"]?:@"error";
            respnse.errorCodeDescription = dict[@"error_description"]?:@"error_description";
            baseResponse = baseResponse;
        }
        default:{
            // -1 用户取消
            // -3 用户取消安装Cwtch客户端
//            baseResponse = [CwtchBaseResponse new];
        }
    }
    return baseResponse;
}



/**
 发送请求给Cwtch客户端程序，并切换到Cwtch
 
 请求发送给Cwtch客户端程序之后，Cwtch客户端程序会进行相关的处理，处理完成之后一定会调用 [CwtchSDKDelegate didReceiveCwtchResponse:responseStatusCode:] 方法将处理结果返回给第三方应用
 
 @param request 具体的发送请求
 
 @see [CwtchSDKDelegate didReceiveCwtchResponse:responseStatusCode:]
 @see CwtchBaseRequest
 */
+ (BOOL)sendRequest:(CwtchBaseRequest *)request{
    
    CwtchAuthorizeRequest *authorizeRequest = (CwtchAuthorizeRequest*)request;
    NSMutableString *url = [@"cwtch://" stringByAppendingString:@"platformapi/authorize"].mutableCopy;
    [url appendString:@"?"];
    
    NSMutableDictionary *dict = @{}.mutableCopy;
    [dict notNll_setObject:[CwtchSDK shareInstance].appKey forKey:@"appKey"];
    [dict notNll_setObject:[CwtchSDK shareInstance].appKey forKey:@"displayName"];
    [dict notNll_setObject:authorizeRequest.redirectURI    forKey:@"redirectURI"];
    [dict notNll_setObject:authorizeRequest.state          forKey:@"state"];
    [dict notNll_setObject:authorizeRequest.scope          forKey:@"scope"];
    
    NSString *encrypt_aesKey = [CwtchSDKAES getAESRandomString];
    NSLog(@"encrypt_aesKey == %@",encrypt_aesKey);
    
    NSString *decrypt_aesKey = [CwtchSDKAES getAESSecretKey:encrypt_aesKey];
//    NSLog(@"decrypt_aesKey == %@",decrypt_aesKey);
    
    NSString *encrypt_json = [CwtchSDKAES parameterEncryption:dict secretKey:decrypt_aesKey];
    NSLog(@"encrypt_json == %@",encrypt_json);
    
//    NSString *decrypt_json = [CwtchSDKAES parameterDecrypt:encrypt_json secretKey:decrypt_aesKey];
//    NSLog(@"decrypt_json == %@",decrypt_json);
    
    [url appendString:@"id="];
    [url appendString:encrypt_json];
    [url appendString:@"&"];
    [url appendString:@"tk="];
    [url appendString:encrypt_aesKey];
    NSLog(@"url - %@ ",url);
    
    if ([CwtchSDK isCwtchAppInstalled]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:^(BOOL success) {
            if (!success) {
                NSLog(@"// ======================== \n %@ \n ========================= //",@"链接打开失败,请检查");
            }
        }];
    }else{
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"是否前往商店下载cwtch" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [alertVC addAction:[UIAlertAction actionWithTitle:@"下载" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *urlAppStore = [NSString stringWithFormat:@"https://itunes.apple.com/app/id%@", @"1423050073"];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlAppStore] options:@{} completionHandler:nil];
            
        }]];
        [alertVC addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertVC animated:YES completion:nil];
    }

    return [CwtchSDK isCwtchAppInstalled];
}
@end



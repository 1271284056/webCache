//
//  NetworkTool.m
//  WebCacheDemo
//
//  Created by 张江东 on 16/12/15.
//  Copyright © 2016年 YM. All rights reserved.
//

#import "NetworkTool.h"

@implementation NetworkTool


+ (void)getWithUrl:(NSString *)url andParams:(NSDictionary *)dict success:(void(^)(id json))success failure:(void(^)(NSError *error))failure{
    
    //处理中文和空格问题
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    //拼接
    NSString * cacheUrl = [[self class] urlDictToStringWithUrlStr:url WithDict:dict] ;
    NSURL *urll = [NSURL URLWithString:cacheUrl];
    
    // 1. 实例化一个网络会话
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task = [session dataTaskWithURL:urll completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // data :服务器返回给我们的数据
        // response :服务器的响应信息
        // error :连接错误信息
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
//        NSLog(@"%@,%@",error,response);
        if (error == nil) {
            success(dict);
        }else{
            failure(error);
        }
    }];
    
    // 3.开启任务
    [task resume];
}


/**
 *  拼接请求的网址
 *
 *  @param urlStr     基础网址
 *  @param parameters 拼接参数
 *
 *  @return 拼接完成的网址
 */
+ (NSString *)urlDictToStringWithUrlStr:(NSString *)urlStr WithDict:(NSDictionary *)parameters
{
    if (!parameters) {
        return urlStr;
    }
    
    NSMutableArray *parts = [NSMutableArray array];
    [parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        //接收key
        NSString *finalKey = [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        //接收值
        NSString *finalValue = [obj stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSString *part =[NSString stringWithFormat:@"%@=%@",finalKey,finalValue];
        [parts addObject:part];
    }];
    
    NSString *queryString = [parts componentsJoinedByString:@"&"];
    queryString = queryString ? [NSString stringWithFormat:@"?%@",queryString] : @"";
    NSString *pathStr = [NSString stringWithFormat:@"%@?%@",urlStr,queryString];
    
    return pathStr;
}




@end

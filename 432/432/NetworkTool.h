//
//  NetworkTool.h
//  WebCacheDemo
//
//  Created by 张江东 on 16/12/15.
//  Copyright © 2016年 YM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkTool : NSObject
+ (void)getWithUrl:(NSString *)url andParams:(NSDictionary *)dict success:(void(^)(id json))success failure:(void(^)(NSError *error))failure;

//+ (void)postWithUrl:(NSString *)url andParams:(NSDictionary *)dict success:(void(^)(id json))success failure:(void(^)(NSError *error))failure;
@end

//
//  AllCacheTool.h
//  HttpCache
//
//  Created by 张江东 on 16/12/16.
//  Copyright © 2016年 58kuaipai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AllCacheTool : NSURLProtocol


+ (void)start;

/** *
 *  控制缓存内容大小
 *
 *  @param countLimit         缓存应该保留的对象的最大数量。(对象数量也就是能存多少个)
 *  @param costLimit          缓存在开始逐出对象之前可以保持的最大总成本。(也就是最大可以存字节)
 *  @param ageLimit           缓存中对象的最大到期时间。(单个对象的到期时间)
 */
+ (void)changeCacheCountLimit:(NSInteger)countLimit costLimit:(NSInteger)costLimit ageLimit:(NSTimeInterval)ageLimit;

@end

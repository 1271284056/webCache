//
//  AllCacheTool.m
//  HttpCache
//
//  Created by 张江东 on 16/12/16.
//  Copyright © 2016年 58kuaipai. All rights reserved.
//

#import "AllCacheTool.h"
#import "AFNetworking.h"
#import <YYCache/YYCache.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface NSURLRequest(MutableCopyWorkaround)

- (id) mutableCopyWorkaround;

@end

@interface YMCachedData : NSObject <NSCoding>

@property (nonatomic, readwrite, strong) NSData *data;
@property (nonatomic, readwrite, strong) NSURLResponse *response;
@property (nonatomic, readwrite, strong) NSURLRequest *redirectRequest;

@end



@interface AllCacheTool ()
{
    BOOL useCache;
    NSString *cacheKey;
}

@property (nonatomic, readwrite, strong) NSURLConnection *connection;
@property (nonatomic, readwrite, strong) NSMutableData *data;
@property (nonatomic, readwrite, strong) NSURLResponse *response;
- (void)appendData:(NSData *)newData;
@property (nonatomic, strong) YYCache *cache;
@end

@implementation AllCacheTool


//注册协议
+ (void)start {
    [NSURLProtocol registerClass:self];
    [self changeCacheCountLimit:INT_MAX costLimit:1024 * 1024 * 10000 ageLimit:DBL_MAX ];
}
+ (void)changeCacheCountLimit:(NSInteger)countLimit costLimit:(NSInteger)costLimit ageLimit:(NSTimeInterval)ageLimit  {
    
    YYCache *cache = [[YYCache alloc] initWithName:@"YYCacheDB"];
    cache.diskCache.countLimit = countLimit;
    cache.diskCache.costLimit = costLimit;
    cache.diskCache.ageLimit = ageLimit;
}

//用来标记这次请求是否是我们拦截的如果是 则不进行处理
static NSString * kOurRecursiveRequestFlagProperty = @"com.MY.Des.HTTPProtocol";
//以下这个链接为host的网址不做处理
static NSString * kHostFlag = @"www.baidu.com";

//这个方法主要是说明你是否打算处理对应的request，如果不打算处理，返回NO，URL Loading System会使用系统默认的行为去处理；如果打算处理，返回YES
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    BOOL        shouldAccept;
    NSURL *     url;
    NSString *  scheme;
    shouldAccept = (request != nil);
    if (shouldAccept) {
        url = [request URL];
        shouldAccept = (url != nil);
        //没请求过这个url的话请求
        shouldAccept = ([self propertyForKey:kOurRecursiveRequestFlagProperty inRequest:request] == nil);
    }
    
    
    //不做缓存的
    //    if (shouldAccept) {
    //        scheme = [[url scheme] lowercaseString];
    //        shouldAccept = (scheme != nil);
    //        shouldAccept = (![scheme  isEqual: @"https"]);//https不处理
    //    }
    
    //    if (shouldAccept) {
    //        shouldAccept = ![[url host] isEqualToString:kHostFlag];
    //    }
    
    return shouldAccept;
}

//通常该方法你可以简单的直接返回request，但也可以在这里修改request，比如添加header，修改host等，并返回一个新的request，这是一个抽象方法，子类必须实现。
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}
//这两个方法主要是开始和取消相应的request，而且需要标示那些已经处理过的request。
- (void)startLoading
{
    self.cache = [[YYCache alloc] initWithName:@"YYCacheDB"];
    [self.cache removeAllObjects];
    
    //将URL转换成名字
    cacheKey = [NSString stringWithFormat:@"%lx", [[[self.request URL] absoluteString] hash]];
    //如果存在缓存 并且没有网络
    if ([self.cache.diskCache containsObjectForKey:cacheKey]  && ![self requestBeforeJudgeConnect]) {
        YMCachedData *cacheData = (YMCachedData *)[self.cache.diskCache objectForKey:cacheKey];
        
        if (cacheData) {
            NSData *data = [cacheData data];
            NSURLResponse *response = [cacheData response];
            //网页重定向
            NSURLRequest *redirectRequest = [cacheData redirectRequest];
            if (redirectRequest) {//有重定向 进入第二次请求
                [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
            } else {
                [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed]; //我们处理缓存自己。
                [[self client] URLProtocol:self didLoadData:data];
                [[self client] URLProtocolDidFinishLoading:self];
            }
        }
        else {
            [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil]];
        }
    }else {//没有缓存 请求
        NSMutableURLRequest *connectionRequest = [[self request] mutableCopyWorkaround];
        
        [[self class] setProperty:@YES forKey:kOurRecursiveRequestFlagProperty inRequest:connectionRequest];
        //开始请求
        NSURLConnection *connection = [NSURLConnection connectionWithRequest:connectionRequest delegate:self];
        [self setConnection:connection];
    }
}

- (void)stopLoading
{
    [[self connection] cancel];
}

// NSURLConnection的代理（一般我们通过这个到我们的客户端）
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if (response != nil) {//有重定向 第二次请求
        NSMutableURLRequest *redirectableRequest =[request mutableCopyWorkaround];
        //如果重新定向则移除请求的标记 重定向
        [[self class] removePropertyForKey:kOurRecursiveRequestFlagProperty inRequest:redirectableRequest];
        
        
        
        [[self client] URLProtocol:self wasRedirectedToRequest:redirectableRequest redirectResponse:response];
        return redirectableRequest;
    } else {
        return request;
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self setResponse:response];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed]; //我们自己缓存。
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[self client] URLProtocol:self didLoadData:data];
    [self appendData:data];//把得到的data放到[self data]
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[self client] URLProtocol:self didFailWithError:error];
    [self setConnection:nil];
    [self setData:nil];
    [self setResponse:nil];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[self client] URLProtocolDidFinishLoading:self];
    
    //保存数据
    YMCachedData *cacheDate = [[YMCachedData alloc] init];
    [cacheDate setResponse:[self response]];
    [cacheDate setData:[self data]];
    [self.cache.diskCache setObject:cacheDate forKey:cacheKey];
    
    [self setConnection:nil];
    [self setData:nil];
    [self setResponse:nil];
}

//根据网页内容拼接数据
- (void)appendData:(NSData *)newData
{
    if ([self data] == nil) {
        [self setData:[newData mutableCopy]];
    }
    else {
        [[self data] appendData:newData];
    }
}

#pragma mark  网络判断
-(BOOL)requestBeforeJudgeConnect
{
    struct sockaddr zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sa_len = sizeof(zeroAddress);
    zeroAddress.sa_family = AF_INET;
    SCNetworkReachabilityRef defaultRouteReachability =
    SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    BOOL didRetrieveFlags =
    SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    if (!didRetrieveFlags) {
        printf("Error. Count not recover network reachability flags\n");
        return NO;
    }
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    BOOL isNetworkEnable  =(isReachable && !needsConnection) ? YES : NO;

    return isNetworkEnable;
}

@end
//将属性归档
@implementation YMCachedData

- (void)encodeWithCoder:(NSCoder *)aCoder {
    NSArray *propertyList = [[self class] propertyList];
    for (NSString *propertyName in propertyList) {
        [aCoder encodeObject:[self valueForKey:propertyName] forKey:propertyName];
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (self) {
        NSArray *properNames = [[self class] propertyList];
        for (NSString *propertyName in properNames) {
            [self setValue:[aDecoder decodeObjectForKey:propertyName] forKey:propertyName];
        }
    }
    return self;
}

+ (NSArray *)propertyList {
    
    NSMutableArray *array = [NSMutableArray array];
    unsigned int propertyListCount = 0;
    objc_property_t *propertyList = class_copyPropertyList([self class], &propertyListCount);
    for (int i = 0; i < propertyListCount; i++) {
        NSString *property = [NSString stringWithUTF8String:property_getName(propertyList[i])];
        [array addObject:property];
    }
    
    return [array copy];
}

@end



//重新复制Request
@implementation NSURLRequest(MutableCopyWorkaround)

- (id) mutableCopyWorkaround {
    NSMutableURLRequest *mutableURLRequest = [[NSMutableURLRequest alloc] initWithURL:[self URL]
                                                                          cachePolicy:[self cachePolicy]
                                                                      timeoutInterval:[self timeoutInterval]];
    [mutableURLRequest setAllHTTPHeaderFields:[self allHTTPHeaderFields]];
    return mutableURLRequest;
}
@end





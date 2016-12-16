//
//  ViewController.m
//  WebCacheDemo
//
//  Created by apple on 16/10/21.
//  Copyright © 2016年 YM. All rights reserved.
//

#import "ViewController.h"
#import "WebViewController.h"
#import "AllCacheTool.h"
#import "AFNetworking.h"
#import "NetworkTool.h"



@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [AllCacheTool start];
    NSArray *arr = @[@"http://www.baidu.com", @"http://www.163.com", @"http://www.tianya.cn", @"http://www.youku.com", @"http://v.baidu.com"];
    for (int i = 0; i < 5; i++) {
        NSString *str = arr[i];
        
        UIButton* button =[UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:str forState:UIControlStateNormal];
        button.frame = CGRectMake(10, 100 * (i + 1), 300, 50);
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }
    
    
//    自己写的网络请求方法
    [NetworkTool getWithUrl:@"http://carprice.58.com/comm/brand.json" andParams:nil success:^(id json) {
        NSLog(@"%@",json);
    } failure:^(NSError *error) {
        
    }];
    
    
    
    
    
//    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
//
//    [manager GET:@"http://carprice.58.com/comm/brand.json" parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
//        
//    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        NSLog(@"%@",responseObject);
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//       
//    }];
//    
    
}

-(void)click:(UIButton *)button
{
    WebViewController *web = [[WebViewController alloc] init];
    web.url = button.titleLabel.text;
    [self.navigationController pushViewController:web animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

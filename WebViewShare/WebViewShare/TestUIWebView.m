//
//  TestUIWebView.m
//  WebViewShare
//
//  Created by cyan color on 16/4/25.
//  Copyright © 2016年 com.mobile. All rights reserved.
//

#import "TestUIWebView.h"
#import "WebViewTracker.h"
#import <WebViewMonitor/WebViewMonitor.h>
@interface TestUIWebView ()<UIWebViewDelegate>

@end

@implementation TestUIWebView

- (void)viewDidLoad {
    [super viewDidLoad];
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    NSString *str = @"http://www.baidu.com";
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:str]];
    [webView loadRequest:request];
    webView.delegate = self;
    [self.view addSubview:webView];
    
    
}
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    [WebViewTracker webView:webView withUrl:request.URL];
    return YES;
}
- (void)webViewDidStartLoad:(UIWebView *)webView;
{
    
}
- (void)webViewDidFinishLoad:(UIWebView *)webView;
{
    //使用NSURLProtocol注入获取ajax代码，因为ajax必须头部注入，不然会丢失数据，而行为和性能数据在头部注入的话也会丢失数据，所以结合着用
    
    NSString *jsStr = WebViewOnclickAndResource_js();
    jsStr = [jsStr substringWithRange:NSMakeRange(2, jsStr.length-3)];
    [webView stringByEvaluatingJavaScriptFromString:jsStr];
    [webView stringByEvaluatingJavaScriptFromString:@"CloudwiseAddEvent()"];
    [webView stringByEvaluatingJavaScriptFromString:@"cloudwiseStartPageMonitor()"];
   
   
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(nullable NSError *)error;
{
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

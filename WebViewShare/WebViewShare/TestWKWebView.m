//
//  TestWKWebView.m
//  WebViewShare
//
//  Created by cyan color on 16/4/25.
//  Copyright © 2016年 com.mobile. All rights reserved.
//

#import "TestWKWebView.h"
#import <WebKit/WebKit.h>
#import <WebViewMonitor/WebViewMonitor.h>
#import "WKWebViewTracker.h"
@interface TestWKWebView ()<WKNavigationDelegate>
@property (nonatomic,strong)WKWebView   *wkWebView;
@end

@implementation TestWKWebView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _wkWebView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    _wkWebView.navigationDelegate = self;
    NSString *str = @"http://www.baidu.com";
    [_wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:str]]];
    
    [self.view addSubview:_wkWebView];
}
#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSLog(@"decidePolicyForNavigationAction");
    
    [WKWebViewTracker wkWebView:webView withUrl:navigationAction.request.URL];
    //    NSLog(@"url=%@",navigationAction.request.URL);
    decisionHandler(WKNavigationActionPolicyAllow);
    
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"didStartProvisionalNavigation");
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
    NSString *jsStr = WKWebViewJavaScript_js();
    jsStr = [jsStr substringWithRange:NSMakeRange(2, jsStr.length-3)];
    [webView evaluateJavaScript:jsStr completionHandler:nil];
    [webView evaluateJavaScript:@"CloudwiseAddEvent()" completionHandler:^(id object, NSError * _Nullable error) {
        
    }];
    [webView evaluateJavaScript:@"cloudwiseStartPageMonitor()" completionHandler:nil];
    [webView evaluateJavaScript:@"cloudwisePreMonitor()" completionHandler:nil];
    NSLog(@"didFinishNavigation");
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

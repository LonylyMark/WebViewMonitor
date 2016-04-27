//
//  WKWebViewTracker.h
//  WebViewShare
//
//  Created by cyan color on 16/4/25.
//  Copyright © 2016年 com.mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
typedef void(^ WKWebViewTrackerMonitor)(NSDictionary *payload);
typedef void (^ WKWebViewTrackerAsyncMonitor)(WKWebView *webView, NSDictionary *payload);
@interface WKWebViewTracker : NSObject
+ (id)shareInstance;
+ (BOOL)wkWebView:(WKWebView *)webView withUrl:(NSURL*)url;
@end

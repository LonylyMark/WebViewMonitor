//
//  WebViewTracker.h
//  WebViewShare
//
//  Created by cyan color on 16/4/25.
//  Copyright © 2016年 com.mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^WebViewTrackerMonitor)(NSDictionary *payload);
typedef void (^ WebViewTrackerAsyncMonitor)(UIWebView *webView, NSDictionary *payload);

@interface WebViewTracker : NSObject
+ (id)shareInstance;
+ (BOOL)webView:(UIWebView*)webView withUrl:(NSURL*)url;
@end

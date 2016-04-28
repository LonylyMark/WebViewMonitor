//
//  WebViewTracker.m
//  WebViewShare
//
//  Created by cyan color on 16/4/25.
//  Copyright © 2016年 com.mobile. All rights reserved.
//

#import "WebViewTracker.h"
#import <objc/runtime.h>
@interface WebViewTracker()
@property (strong, nonatomic) NSMutableDictionary *listeners;
@end
@implementation WebViewTracker
+ (id)shareInstance;
{
    static dispatch_once_t once;
    static WebViewTracker *instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
        instance.listeners = [[NSMutableDictionary alloc] init];
    });
    return instance;
}
void WebViewSwizzle(Class c, SEL orig, SEL newS) {
    
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, newS);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(c, newS, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}
+ (void)sendType:(NSString *)type perform:(WebViewTrackerMonitor)monitor
{
    void (^ extend)(UIWebView *webView,NSDictionary *payload) = ^(UIWebView *webView,NSDictionary *payload){
        monitor(payload);
        
    };
    [self sendType:type addType:extend];
}
+ (void)sendType:(NSString *)type addType:(WebViewTrackerAsyncMonitor)monitor
{
    WebViewTracker *instance = [WebViewTracker shareInstance];
    
    NSDictionary *listeners = [instance listeners];
    
    NSMutableArray *listenerList = [listeners objectForKey:type];
    
    if (listenerList == nil) {
        listenerList = [[NSMutableArray alloc] init];
        
        [instance.listeners setValue:listenerList forKey:type];
        [listenerList addObject:monitor];
    }
}

+ (BOOL)webView:(UIWebView*)webView withUrl:(NSURL*)url
{
    if ([[url scheme] isEqualToString:@"cloudwise-agent"]) {
        
        NSString *eventType = [url host];
        NSString *query = [url query];
        NSString *jsonString = [query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error;
        NSDictionary *JSON = [NSJSONSerialization
                              JSONObjectWithData: [jsonString dataUsingEncoding:NSUTF8StringEncoding]
                              options: NSJSONReadingAllowFragments
                              error: &error];
        //时间响应数据
        if ([eventType isEqualToString:@"timing"])
        {
            [[self shareInstance] triggerEventFromWebView:webView withData:JSON];
            
        }else if ([eventType isEqualToString:@"ajax"])//ajax请求数据
        {
            [[self shareInstance] triggerEventFromWebView:webView withData:JSON];
        }
        
        return NO;
    }
    
    
    if ([[url scheme] isEqualToString:@"cloudwise"] )
    {
        NSString *eventType = [url host];
//        NSString *messageId = [[url path] substringFromIndex:1];
        NSString *query = [url query];
        NSString *jsonString = [query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error;
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:
                              [jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                        options: NSJSONReadingMutableContainers
                                          error: &error];
        
        if ([eventType isEqualToString:@"event"]) {
            [[self shareInstance] triggerEventFromWebView:webView withData:JSON];
        }
        
        return NO;
    }
    
    return YES;
}

- (void)triggerEventFromWebView:(UIWebView*)webView withData:(NSDictionary*)envelope
{
    
    NSDictionary *listeners = [[WebViewTracker shareInstance] listeners];

    NSString *type = [envelope objectForKey:@"type"];
    
    NSDictionary *payload = [envelope objectForKey:@"payload"];
    NSArray *listenerList = (NSArray*)[listeners objectForKey:type];

    for (WebViewTrackerAsyncMonitor handler in listenerList)
    {
        handler(webView, payload);
    }
    
}


@end

@interface UIWebView (Monitor)

@end
@implementation UIWebView (Monitor)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class webViewCls = [UIWebView class];
        WebViewSwizzle(webViewCls, @selector(loadRequest:), sel_registerName("webViewMonitor_loadRequest:"));
        
        WebViewSwizzle(webViewCls, @selector(loadHTMLString:baseURL:), sel_registerName("webViewMonitor_loadHTMLString:baseURL:"));
        
        WebViewSwizzle(webViewCls, @selector(loadData:MIMEType:textEncodingName:baseURL:), sel_registerName("webViewMonitor_loadData:MIMEType:textEncodingName:baseURL:"));
    });
}
- (void)webViewMonitor_loadRequest:(NSURLRequest *)request
{
    [self webViewMonitor_loadRequest:request];
    webViewMonitor(self);
}
- (void)webViewMonitor_loadHTMLString:(NSString *)string baseURL:(nullable NSURL *)baseURL
{
    [self webViewMonitor_loadHTMLString:string baseURL:baseURL];
    webViewMonitor(self);
}
- (void)webViewMonitor_loadData:(NSData *)data MIMEType:(NSString *)MIMEType textEncodingName:(NSString *)textEncodingName baseURL:(NSURL *)baseURL
{
    [self webViewMonitor_loadData:data MIMEType:MIMEType textEncodingName:textEncodingName baseURL:baseURL];
    webViewMonitor(self);
    
}

static void webViewMonitor(UIWebView *ui_self)
{
    //行为事件数据
    [WebViewTracker sendType:@"onclick" perform:^(NSDictionary *payload) {
        NSLog(@"payload=%@",payload);
    }];
    //响应事件数据和js错误
    [WebViewTracker sendType:@"cloudwise_monitor" perform:^(NSDictionary *payload) {
        NSLog(@"timing=%@",payload);
    }];
    //ajax数据
    [WebViewTracker sendType:@"cloudwise_monitor_ajax" perform:^(NSDictionary *payload) {
        NSLog(@"ajax=%@",payload);
    }];
}
@end

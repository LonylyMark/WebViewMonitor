//
//  WKWebViewTracker.m
//  WebViewShare
//
//  Created by cyan color on 16/4/25.
//  Copyright © 2016年 com.mobile. All rights reserved.
//

#import "WKWebViewTracker.h"
#import <objc/runtime.h>

@interface WKWebViewTracker()
@property (strong, nonatomic) NSMutableDictionary *listeners;
@end
@implementation WKWebViewTracker
+ (id)shareInstance;
{
    static dispatch_once_t once;
    static WKWebViewTracker *instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
        instance.listeners = [[NSMutableDictionary alloc] init];
    });
    return instance;
}
void WKWebViewSwizzle(Class c, SEL orig, SEL newS) {
    
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, newS);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(c, newS, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

+ (void)sendType:(NSString *)type perform:(WKWebViewTrackerMonitor)monitor
{
    void (^ extend)(WKWebView *webView,NSDictionary *payload) = ^(WKWebView *webView,NSDictionary *payload){
        monitor(payload);
        
    };
    [self sendType:type addType:extend];
}
+ (void)sendType:(NSString *)type addType:(WKWebViewTrackerAsyncMonitor)monitor
{
    WKWebViewTracker *instance = [WKWebViewTracker shareInstance];
    
    NSDictionary *listeners = [instance listeners];
    
    NSMutableArray *listenerList = [listeners objectForKey:type];
    
    if (listenerList == nil) {
        listenerList = [[NSMutableArray alloc] init];
        
        [instance.listeners setValue:listenerList forKey:type];
        [listenerList addObject:monitor];
    }
}

+ (BOOL)wkWebView:(WKWebView*)webView withUrl:(NSURL*)url
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
        
        if ([eventType isEqualToString:@"timing"])
        {
            
            [[self shareInstance] triggerEventFromWebView:webView withData:JSON];
            
        }else if ([eventType isEqualToString:@"ajax"])
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
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData: [jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                             options: NSJSONReadingMutableContainers
                                                               error: &error];
        
        if ([eventType isEqualToString:@"event"]) {
            [[self shareInstance] triggerEventFromWebView:webView withData:JSON];
        }
        
        return NO;
    }
    
    return YES;
}

- (void)triggerEventFromWebView:(WKWebView*)webView withData:(NSDictionary*)envelope
{
    
    NSDictionary *listeners = [[WKWebViewTracker shareInstance] listeners];
    
    NSString *type = [envelope objectForKey:@"type"];
    
    NSDictionary *payload = [envelope objectForKey:@"payload"];
    NSArray *listenerList = (NSArray*)[listeners objectForKey:type];
    
    for (WKWebViewTrackerAsyncMonitor handler in listenerList)
    {
        handler(webView, payload);
    }
    
}
@end

@interface WKWebView (monitor)


@end
@implementation WKWebView (monitor)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Class   webViewCls = [WKWebView class];
        WKWebViewSwizzle(webViewCls, @selector(loadRequest:), sel_registerName("WKwebViewMonitor_loadRequest:"));
        WKWebViewSwizzle(webViewCls, @selector(loadFileURL:allowingReadAccessToURL:), sel_registerName("WKwebViewMonitor_loadFile:allowingReadAccessToURL:"));
        WKWebViewSwizzle(webViewCls, @selector(loadHTMLString:baseURL:), sel_registerName("WKwebViewMonitor_loadHTMLString:baseURL:"));
        WKWebViewSwizzle(webViewCls, @selector(loadData:MIMEType:characterEncodingName:baseURL:), sel_registerName("WKwebViewMonitor_loadData:MIMEType:characterEncodingName:baseURL:"));
    });
    
}
- (WKNavigation *)WKwebViewMonitor_loadRequest:(NSURLRequest *)request
{
    
    wkWebViewMonitor(self);
    
    
    return [self WKwebViewMonitor_loadRequest:request];
    
}
- (WKNavigation *)WKwebViewMonitor_loadFile:(NSURL *)url allowingReadAccessToURL:(NSURL *)readAccessToURL
{
  
    wkWebViewMonitor(self);
   
    return [self WKwebViewMonitor_loadFile:url allowingReadAccessToURL:readAccessToURL];
}

- (WKNavigation *)WKwebViewMonitor_loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL
{
    
    wkWebViewMonitor(self);
    
    return [self WKwebViewMonitor_loadHTMLString:string baseURL:baseURL];
}
- (WKNavigation *)WKwebViewMonitor_loadData:(NSData *)data MIMEType:(NSString *)type characterEncodingName:(NSString *)characterEncodingName baseURL:(NSURL *)baseURL
{
   
    wkWebViewMonitor(self);
    
    return [self WKwebViewMonitor_loadData:data MIMEType:type characterEncodingName:characterEncodingName baseURL:baseURL];
}

static void wkWebViewMonitor(WKWebView *wk_self)
{
    [WKWebViewTracker sendType:@"onclick" perform:^(NSDictionary *payload) {
        NSLog(@"click-wk=%@",payload);
    }];
    
    [WKWebViewTracker sendType:@"cloudwise_monitor" perform:^(NSDictionary *payload) {
        NSLog(@"timing=wk=%@",payload);
    }];
    
    [WKWebViewTracker sendType:@"cloudwise_monitor_ajax" perform:^(NSDictionary *payload) {
        NSLog(@"ajax-wk=%@",payload);
    }];
}

@end
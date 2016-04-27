//
//  MonitorURLProtocol.m
//  WebViewShare
//
//  Created by cyan color on 16/4/26.
//  Copyright © 2016年 com.mobile. All rights reserved.
//

#import "MonitorURLProtocol.h"
#import <WebViewMonitor/WebViewMonitor.h>
//调试输出打印的日志 1是输出 0 不输出
#define WebView_DEBUG 0
#if  WebView_DEBUG
#define LOG(...)         NSLog(__VA_ARGS__);
#else
#define LOG(...);
#endif

@interface MonitorURLProtocol() <NSURLConnectionDelegate>
@property (nonatomic,strong)NSURLConnection *connection;
@end
@implementation MonitorURLProtocol
static NSString *HandledKey = @"WebViewMonitor";
static NSOperationQueue* _queue;

+(void)initialize {
    _queue = [NSOperationQueue new];
    [_queue setMaxConcurrentOperationCount:20];
}
#pragma mark -- NSURLProtocol
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    
    if ([NSURLProtocol propertyForKey:HandledKey inRequest:request] != nil) {
        return NO;
    }
   
    return YES;
}

-(instancetype)initWithRequest:(NSURLRequest *)request
                cachedResponse:(NSCachedURLResponse *)cachedResponse
                        client:(id<NSURLProtocolClient>)client {
    
    return [super initWithRequest:request
                   cachedResponse:cachedResponse
                           client:client];
}



+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a
                       toRequest:(NSURLRequest *)b
{
    return [super requestIsCacheEquivalent:a toRequest:b];
}


+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    // init property variable
  

    
    NSMutableURLRequest *newRequest = [self.request mutableCopy];

    [NSURLProtocol setProperty:@YES forKey:HandledKey inRequest:newRequest];
    
    _connection = [[NSURLConnection alloc] initWithRequest:newRequest
                                                  delegate:self
                                          startImmediately:NO];
    // comment out for sure stalling
    [_connection setDelegateQueue:_queue];
    [_connection start];
    
    
}

- (void)stopLoading
{
    [self.connection cancel];
    self.connection = nil;
}

#pragma mark -- NSURLProtocolClient

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {

    [self.client URLProtocol:self didFailWithError:error];
    self.connection = nil;
    
    
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response{
    if (response != nil)
    {
        NSMutableURLRequest *redirectableRequest = [request mutableCopy];
        
        [self.client URLProtocol:self wasRedirectedToRequest:redirectableRequest redirectResponse:response];
        return redirectableRequest;
    }
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    
        NSString *htmlStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //自由关闭日志输出
        LOG(@"html=%@",htmlStr);
        if (htmlStr) {
            NSMutableString *multiStr = [NSMutableString stringWithString:htmlStr];
            NSRange range = [multiStr rangeOfString:@"<head>"];//<script src=   <head>
            if(range.location != NSNotFound){
               //注入监控ajax请求的js代码
                NSString *jsStr = WebViewAjax_js();
                jsStr = [jsStr substringWithRange:NSMakeRange(2, jsStr.length-3)];
                NSString *injectJSStr = [NSString stringWithFormat:@"<script>%@</script>\n",jsStr];
                [multiStr insertString:injectJSStr atIndex:(range.location + range.length)];
                NSData *mutilData = [multiStr dataUsingEncoding:NSUTF8StringEncoding];
                [self.client URLProtocol:self didLoadData:mutilData];
               
                
            }else{
              
                [self.client URLProtocol:self didLoadData:data];
            }
        }else{
           
            [self.client URLProtocol:self didLoadData:data];
        }
        
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
 
    [self.client URLProtocolDidFinishLoading:self];
    
    self.connection = nil;
    
    
}



@end

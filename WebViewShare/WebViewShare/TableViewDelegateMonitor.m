//
//  TableViewDelegateMonitor.m
//  WebViewShare
//
//  Created by cyan color on 16/4/25.
//  Copyright © 2016年 com.mobile. All rights reserved.
//

#import "TableViewDelegateMonitor.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <mach-o/ldsyms.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "WebViewTracker.h"
#import "WKWebViewTracker.h"
#import <WebViewMonitor/WebViewMonitor.h>
#import "WKWebViewTracker.h"
@implementation TableViewDelegateMonitor
+ (TableViewDelegateMonitor *)shareInstance
{
    static TableViewDelegateMonitor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TableViewDelegateMonitor alloc] init];
    });
    return instance;
}
+ (void)startMonitor
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        [self swizzleDelegateMethod];
        
    });
}

/*************************/
unsigned int numClasses;
const char **classes;
Dl_info info;
/*************************/


+ (void)swizzleDelegateMethod{
    static BOOL swizzled = NO;
    if (swizzled) {
        return;
    }
    
    swizzled = YES;
    
    const SEL selectors[] = {
        @selector(webView:shouldStartLoadWithRequest:navigationType:),
        @selector(webViewDidFinishLoad:),
        @selector(webView:decidePolicyForNavigationAction:decisionHandler:),
        @selector(webView:didFinishNavigation:)
    };
    
    const int numSelectors = sizeof(selectors) / sizeof(SEL);
    /*************************///遍历当前工程文件（包括静态库部分）
    dladdr(&_mh_execute_header, &info);
    classes = objc_copyClassNamesForImage(info.dli_fname, &numClasses);
    /*************************/
    /*---------遍历所有文件（包括静态库）--------------*/

    for (int classesIndex= 0; classesIndex < numClasses; classesIndex++) {
        /*-----------------------*/
        //        Class class = classes[classesIndex];
        /*-----------------------*/
        /*************************/
        NSString *clsStr = [NSString stringWithCString:classes[classesIndex] encoding:NSUTF8StringEncoding];
        
        Class class = NSClassFromString (clsStr);
        //        NSLog(@"====== %@ ======",clsStr);
        /*************************/
        
        if (class_getClassMethod(class, @selector(isSubclassOfClass:)) == NULL) {
            continue;
        }
        
        if (![class isSubclassOfClass:[NSObject class]]) {
            continue;
        }
        
        if ([class isSubclassOfClass:[self class]]) {
            continue;
        }
        
        for (int selectorIndex = 0; selectorIndex < numSelectors; ++selectorIndex) {
            if ([class instancesRespondToSelector:selectors[selectorIndex]]) {
                [self injectIntoDelegateClass:class withSelectorIndex:selectorIndex];
            }
        }
    }
}
+ (void)injectIntoDelegateClass:(Class)cls withSelectorIndex:(int)selectorIndex{
    
    switch (selectorIndex) {
        case 0:
        {
            [self injectWebviewShouldStartLoadWithRequest:cls];
            
        }
            break;
        case 1:
        {
            [self injectWebViewDidFinishLoad:cls];
        }
            break;
        case 2:
        {
            //WKWebView8.0以后才出来  加个判断
            if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0)
            {
                [self injectWkWebViewDecidePolicyNavigationAction:cls];
            }
            
        }
            break;
        case 3:
        {
            if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0)
            {
                [self injectWkWebViewFinishNavigation:cls];
            }
            
        }
            break;
        default:
            break;
    }
    
    
}
+ (void)injectWebviewShouldStartLoadWithRequest:(Class)cls{
    SEL selector = @selector(webView:shouldStartLoadWithRequest:navigationType:);
    SEL swizzleSelector = [self swizzledSelectorForSelector:selector];
    Protocol *protocol = @protocol(UIWebViewDelegate);
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    typedef void (^UIWebViewShouldStartLoadWithRequestBlock)(id<UIWebViewDelegate> slf, UIWebView *webView,NSURLRequest *request, UIWebViewNavigationType navigationType);
    UIWebViewShouldStartLoadWithRequestBlock undefinedBlock = ^(id<UIWebViewDelegate> slf, UIWebView *webView,NSURLRequest *request, UIWebViewNavigationType navigationType){
        //加入代码
        [WebViewTracker webView:webView withUrl:[request URL]];
    };
    
    UIWebViewShouldStartLoadWithRequestBlock implementationBlock = ^(id<UIWebViewDelegate> slf, UIWebView *webView,NSURLRequest *request, UIWebViewNavigationType navigationType){
        undefinedBlock(slf,webView,request,navigationType);
        ((void(*)(id, SEL, id, id,UIWebViewNavigationType))objc_msgSend)(slf, swizzleSelector, webView, request,navigationType);
        
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzleSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectWebViewDidStartLoad:(Class)cls{
    SEL selector = @selector(webViewDidStartLoad:);
    SEL swizzleSelector = [self swizzledSelectorForSelector:selector];
    Protocol *protocol = @protocol(UIWebViewDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    typedef void (^UIWebViewDidStartLoadBlock)(id<UIWebViewDelegate> slf, UIWebView *webView);
    UIWebViewDidStartLoadBlock undefinedBlock = ^(id<UIWebViewDelegate> slf, UIWebView *webView){
      
        
    };
    
    UIWebViewDidStartLoadBlock implementationBlock = ^(id<UIWebViewDelegate> slf, UIWebView *webView){
        undefinedBlock(slf,webView);
        ((void(*)(id, SEL, id))objc_msgSend)(slf, swizzleSelector, webView);
        
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzleSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectWebViewDidFinishLoad:(Class)cls{
    SEL selector = @selector(webViewDidFinishLoad:);
    SEL swizzleSelector = [self swizzledSelectorForSelector:selector];
    Protocol *protocol = @protocol(UIWebViewDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    typedef void (^UIWebViewDidFinishLoadBlock)(id<UIWebViewDelegate> slf, UIWebView *webView);
    UIWebViewDidFinishLoadBlock undefinedBlock = ^(id<UIWebViewDelegate> slf, UIWebView *webView){
        
        
        NSString *jsStr = WebViewOnclickAndResource_js();
        jsStr = [jsStr substringWithRange:NSMakeRange(2, jsStr.length-3)];
        [webView stringByEvaluatingJavaScriptFromString:jsStr];
        [webView stringByEvaluatingJavaScriptFromString:@"CloudwiseAddEvent()"];
        [webView stringByEvaluatingJavaScriptFromString:@"cloudwiseStartPageMonitor()"];
        
    };
    
    UIWebViewDidFinishLoadBlock implementationBlock = ^(id<UIWebViewDelegate> slf, UIWebView *webView){
        undefinedBlock(slf,webView);
        ((void(*)(id, SEL, id))objc_msgSend)(slf, swizzleSelector, webView);
        
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzleSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectWkWebViewDecidePolicyNavigationAction:(Class)cls
{
    SEL selector = @selector(webView:decidePolicyForNavigationAction:decisionHandler:);
    SEL swizzleSelector = [self swizzledSelectorForSelector:selector];
    Protocol *protocol = @protocol(WKNavigationDelegate);
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    typedef void (^WKWebViewDecidePolicyBlock)(id<WKNavigationDelegate> slf, WKWebView *webView, WKNavigationAction *navigationAction,WKNavigationActionPolicy navigationActionPolicy);
    WKWebViewDecidePolicyBlock undefinedBlock = ^(id<WKNavigationDelegate> slf, WKWebView *webView, WKNavigationAction *navigationAction,WKNavigationActionPolicy navigationActionPolicy){
        //加入代码
        //        NSLog(@"webview click");
        [WKWebViewTracker wkWebView:webView withUrl:navigationAction.request.URL];
    };
    
    WKWebViewDecidePolicyBlock implementationBlock = ^(id<WKNavigationDelegate> slf, WKWebView *webView,WKNavigationAction *navigationAction,WKNavigationActionPolicy navigationActionPolicy){
        undefinedBlock(slf,webView,navigationAction,navigationActionPolicy);
        ((void(*)(id, SEL,id,id,WKNavigationActionPolicy))objc_msgSend)(slf, swizzleSelector, webView,navigationAction,navigationActionPolicy);
        
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzleSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
}

+ (void)injectWkWebViewFinishNavigation:(Class)cls
{
    SEL selector = @selector(webView:didFinishNavigation:);
    SEL swizzleSelector = [self swizzledSelectorForSelector:selector];
    Protocol *protocol = @protocol(WKNavigationDelegate);
    
    struct objc_method_description methodDescription = protocol_getMethodDescription(protocol, selector, NO, YES);
    typedef void (^WKWebViewFinishNavigationBlock)(id<WKNavigationDelegate> slf, WKWebView *webView,WKNavigation *navigation);
    WKWebViewFinishNavigationBlock undefinedBlock = ^(id<WKNavigationDelegate> slf, WKWebView *webView,WKNavigation *navigation){

        NSString *jsStr = WKWebViewJavaScript_js();
        jsStr = [jsStr substringWithRange:NSMakeRange(2, jsStr.length-3)];
        [webView evaluateJavaScript:jsStr completionHandler:nil];
        [webView evaluateJavaScript:@"CloudwiseAddEvent()" completionHandler:^(id object, NSError * _Nullable error) {
            
        }];
        [webView evaluateJavaScript:@"cloudwiseStartPageMonitor()" completionHandler:nil];
        [webView evaluateJavaScript:@"cloudwisePreMonitor()" completionHandler:nil];
        
        
    };
    
    WKWebViewFinishNavigationBlock implementationBlock = ^(id<WKNavigationDelegate> slf, WKWebView *webView,WKNavigation *navigation){
        undefinedBlock(slf,webView,navigation);
        ((void(*)(id, SEL, id,id))objc_msgSend)(slf, swizzleSelector, webView,navigation);
        
    };
    
    [self replaceImplementationOfSelector:selector withSelector:swizzleSelector forClass:cls withMethodDescription:methodDescription implementationBlock:implementationBlock undefinedBlock:undefinedBlock];
    
}




+ (SEL)swizzledSelectorForSelector:(SEL)selector;
{
    return NSSelectorFromString([NSString stringWithFormat:@"_pd_swizzle_%x_%@", arc4random(), NSStringFromSelector(selector)]);
}

+ (void)replaceImplementationOfSelector:(SEL)selector withSelector:(SEL)swizzledSelector forClass:(Class)cls withMethodDescription:(struct objc_method_description)methodDescription implementationBlock:(id)implementationBlock undefinedBlock:(id)undefinedBlock{
    if ([self instanceRespondsButDoesNotImplementSelector:selector class:cls]) {
        return;
    }
    
#ifdef __IPHONE_6_0
    IMP implementation = imp_implementationWithBlock((id)([cls instancesRespondToSelector:selector] ? implementationBlock : undefinedBlock));
#else
    IMP implementation = imp_implementationWithBlock((__bridge void *)([cls instancesRespondToSelector:selector] ? implementationBlock : undefinedBlock));
#endif
    
    Method oldMethod = class_getInstanceMethod(cls, selector);
    if (oldMethod) {
        class_addMethod(cls, swizzledSelector, implementation, methodDescription.types);
        
        Method newMethod = class_getInstanceMethod(cls, swizzledSelector);
        
        method_exchangeImplementations(oldMethod, newMethod);
    } else {
        class_addMethod(cls, selector, implementation, methodDescription.types);
    }
}

+ (BOOL)instanceRespondsButDoesNotImplementSelector:(SEL)selector class:(Class)cls;
{
    if ([cls instancesRespondToSelector:selector]) {
        unsigned int numMethods = 0;
        Method *methods = class_copyMethodList(cls, &numMethods);
        
        BOOL implementsSelector = NO;
        for (int index = 0; index < numMethods; index++) {
            SEL methodSelector = method_getName(methods[index]);
            if (selector == methodSelector) {
                implementsSelector = YES;
                break;
            }
        }
        
        free(methods);
        
        if (!implementsSelector) {
            return YES;
        }
    }
    
    return NO;
}
@end

//
//  TableViewDelegateMonitor.h
//  WebViewShare
//
//  Created by cyan color on 16/4/25.
//  Copyright © 2016年 com.mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TableViewDelegateMonitor : NSObject
+ (TableViewDelegateMonitor *)shareInstance;

+ (void)startMonitor;
@end

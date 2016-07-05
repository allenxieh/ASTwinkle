//
//  ASApplicationContext.h
//
//  Created by allen on 16/1/8.
//  Copyright © 2016年 Allen All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ASApplicationContext : NSObject

+ (instancetype)sharedApplicationContext;

- (id)getBeanByClass:(NSString *)className;
- (id)getBeanByProtocol:(NSString *)protocolName;

@end

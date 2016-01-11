//
//  ASApplicationContext.m
//
//  Created by allen on 16/1/8.
//  Copyright © 2016年 Allen All rights reserved.
//

#import "ASApplicationContext.h"
#import "ASXMLManager.h"

@interface ASApplicationContext()

@property (nonatomic,strong) ASXMLManager *XMLManager;

@end

@implementation ASApplicationContext

static id _sharedInstance;
+ (instancetype)sharedApplicationContet{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[[self class] alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.XMLManager = [ASXMLManager sharedXMLManager];
    }
    return self;
}

- (id)getBeanByClass:(NSString *)className{
    return [self.XMLManager getBeanByClass:className];
}
- (id)getBeanByProtocol:(NSString *)protocolName{
    return [self.XMLManager getBeanByProtocol:protocolName];
}
@end

//
//  ASXMLManager.m
//
//  Created by allen on 16/1/8.
//  Copyright © 2016年 Allen All rights reserved.
//

#import "ASXMLManager.h"
#import "GDataXMLNode.h"
#import "RNDecryptor.h"
#import "ASTwinkleConfig.h"

#define __kPropertyKey__ @"property"
#define __kBeanKey__ @"bean"
#define __kProtocolNameKey__ @"protocolName"
#define __kClassNameKey__ @"className"
#define __kIdKey__ @"id"
#define __kRefKey__ @"ref"
#define __kNameKey__ @"name"
#define __kScopeKey__ @"scope"
#define __kScopeTypeSingleton__ @"singleton"

typedef NS_ENUM(NSUInteger, EGetBeanByType) {
    GetBeanByTypeClass,
    GetBeanByTypeProtocol,
};

@interface ASXMLManager ()

@property (nonatomic,strong) GDataXMLDocument *rootXmlDoc;
@property (nonatomic,strong) GDataXMLElement *rootElement;
@property (nonatomic,strong) NSArray *beans;

@property (nonatomic,strong) NSMutableArray<GDataXMLDocument*> *xmlDocArr;

@property (nonatomic,strong) NSMutableDictionary *singletons;

@end

@implementation ASXMLManager

static id _sharedInstance;
+ (instancetype)sharedXMLManager{
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
        
        
        self.rootXmlDoc = [self p_readXML:__kXMLPath__];
        
        self.rootElement = [self.rootXmlDoc rootElement];
        
        NSMutableArray *mBeansArr = [NSMutableArray new];
        self.xmlDocArr = [NSMutableArray new];
        
        for (GDataXMLElement *xmlElement in [_rootElement nodesForXPath:@"package" error:nil]) {
            NSString *xmlPath = [[xmlElement attributeForName:@"name"] stringValue];
            GDataXMLDocument *XMLDocTemp = [self p_readXML:xmlPath];
            GDataXMLElement *rootElementTemp = [XMLDocTemp rootElement];
            //需要将GDataXMLElement对象保持
            [self.xmlDocArr addObject:XMLDocTemp];
            [mBeansArr addObjectsFromArray:[rootElementTemp nodesForXPath:@"beans/bean" error:nil]];
        }
        
        self.beans = [self p_getBeans:mBeansArr];
        
        self.singletons = [NSMutableDictionary new];
    }
    return self;
}


- (id)getBeanByClass:(NSString *)className{
    return [self p_getXMLBeanWithName:className type:GetBeanByTypeClass];
}

- (id)getBeanByProtocol:(NSString *)protocolName{
    return [self p_getXMLBeanWithName:protocolName type:GetBeanByTypeProtocol];
}

#pragma mark - private function

- (id)p_getBeanWithClass:(NSString *)className{
    id bean = [self.singletons valueForKey:className]?:[[NSClassFromString(className) alloc] init];;
    if (!bean) {
        NSLog(@"\nWARNING\n<%@>无法被实例化",className);
    }
    NSLog(@"\n装载<%@>",className);
    return bean;
}

- (id)p_getBeanWithId:(NSString *)idName{
    id bean;
    for (GDataXMLElement *beanElement in _beans){
        if ([[[beanElement attributeForName:__kIdKey__] stringValue] isEqualToString:idName]) {
            if ([[beanElement attributeForName:__kProtocolNameKey__] stringValue])//有protocolName
            {
                bean = [self getBeanByProtocol:[[beanElement attributeForName:__kProtocolNameKey__] stringValue]];
            }
            else if([[beanElement attributeForName:__kClassNameKey__] stringValue])//有className
            {
                bean = [self getBeanByClass:[[beanElement attributeForName:__kClassNameKey__] stringValue]];
            }
            else if([[beanElement attributeForName:__kRefKey__] stringValue])//有ref
            {
               bean = [self p_getBeanWithId:[[beanElement attributeForName:__kRefKey__] stringValue]];
            }
            else
            {
                NSLog(@"\nWARNING\n找不到id=<%@>对象",idName);
            }
            return bean;
        }
    }
    return bean;
}

- (BOOL) p_isSingleton:(GDataXMLElement *)element{
    if ([[[element attributeForName:__kScopeKey__] stringValue] isEqualToString:__kScopeTypeSingleton__]) {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (id)p_getXMLBeanWithName:(NSString *)name type:(EGetBeanByType) type{
    id instance;
    for (GDataXMLElement *beanElement in _beans)
    {
        switch (type) {
            case GetBeanByTypeClass:
            {
                
                if ([[[beanElement attributeForName:__kClassNameKey__] stringValue] isEqualToString:name])
                {
                    if ([[beanElement children] count] == 0)//没有property子标签
                    {
                        instance = [self p_getBeanWithClass:name];
                    }
                    else
                    {
                        if ([[beanElement attributeForName:__kClassNameKey__] stringValue])
                        {
                            instance = [self p_getBeanWithClass:name];
                            NSError *error;
                            NSArray *propertys = [beanElement nodesForXPath:__kPropertyKey__ error:&error];
                            if (!error)
                            {
                                for (GDataXMLElement *propertyElement in propertys)
                                {
                                    id subInstance;
                                    if (![[propertyElement attributeForName:__kProtocolNameKey__] stringValue])//没有protocolName属性
                                    {
                                        if (![[propertyElement attributeForName:__kRefKey__] stringValue])//没有ref属性
                                        {
                                            
                                            subInstance = [self p_getBeanWithClass:[[propertyElement attributeForName:__kClassNameKey__] stringValue]];
                                        }
                                        else
                                        {
                                            subInstance = [self p_getBeanWithId:[[propertyElement attributeForName:__kRefKey__] stringValue]];
                                        }
                                        if (subInstance && [self p_isSingleton:propertyElement]) {
                                            [self.singletons setValue:subInstance forKey:NSStringFromClass([subInstance class])];
                                        }
                                        [instance setValue:subInstance forKey:[[propertyElement attributeForName:__kNameKey__] stringValue]];
                                    }
                                    else
                                    {
                                        Protocol *protocol = NSProtocolFromString([[propertyElement attributeForName:__kProtocolNameKey__] stringValue]);
                                        subInstance = [self p_getBeanWithId:[[propertyElement attributeForName:__kRefKey__] stringValue]];
                                        if (subInstance && [self p_isSingleton:propertyElement]) {
                                            [self.singletons setValue:subInstance forKey:NSStringFromClass([subInstance class])];
                                        }
                                        if ([subInstance conformsToProtocol:protocol]) {
                                            [instance setValue:subInstance forKey:[[propertyElement attributeForName:__kNameKey__] stringValue]];
                                        }
                                        else
                                        {
                                            NSLog(@"\nWARNING\n<%@>不支持协议<%@>",[[propertyElement attributeForName:__kRefKey__] stringValue],[[propertyElement attributeForName:__kProtocolNameKey__] stringValue]);
                                        }
                                    }
                                }
                                
                            }
                        }
                        else
                        {
                            NSLog(@"\nWARNING\n<%@>找不到匹配的bean对象",name);
                        }
                        
                    }
                    if (instance && [self p_isSingleton:beanElement]) {
                        [self.singletons setValue:instance forKey:NSStringFromClass([instance class])];
                    }
                    return instance;
                }
            }
                break;
            case GetBeanByTypeProtocol:
            {
                
                if ([[[beanElement attributeForName:__kProtocolNameKey__] stringValue] isEqualToString:name])
                {
                    Protocol *protocol = NSProtocolFromString([[beanElement attributeForName:__kProtocolNameKey__] stringValue]);
                    instance = [self p_getBeanWithId:[[beanElement attributeForName:__kRefKey__] stringValue]];
                    if (![instance conformsToProtocol:protocol]) {
                        NSLog(@"\nWARNING\n<%@>不支持协议<%@>",[[beanElement attributeForName:__kRefKey__] stringValue],name);
                    }
                    return instance;
                }
            }
                break;
        }
        
    }
    return instance;
}


- (GDataXMLDocument *)p_readXML:(NSString *)path{
    NSLog(@"%@",path);
    
    NSError *error;
    NSData *xmlData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:path ofType:nil]];
    
    GDataXMLDocument *document;
    
    if (xmlData) {
        if ([__kXMLPath__ hasSuffix:@"xml"]) {
            document = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&error];
            if (!error) {
                return document;
            }else{
                NSLog(@"%@",error.domain);
            }
            
        }else{
            NSData *decryptedData = [RNDecryptor decryptData:xmlData
                                                withPassword:__kAESKey__
                                                       error:&error];
            document = [[GDataXMLDocument alloc] initWithData:decryptedData options:0 error:&error];
            if (!error) {
                return document;
            }else{
                NSLog(@"%@",error.domain);
            }
        }
    }else{
        NSLog(@"\nERROR\n读取文件<%@>错误",path);
    }
    
    return document;
}

- (NSArray *)p_getBeans:(NSArray *) beans{
    NSMutableDictionary *tempDic = [NSMutableDictionary new];
    for (GDataXMLElement *element in beans) {
        NSString *key = [[element attributeForName:__kIdKey__] stringValue];
        if (![tempDic valueForKey:key]) {
            [tempDic setValue:key forKey:key];
        }else{
            NSLog(@"\nERROR\n id<%@>重复定义",key);
            return nil;
        }
    }
    
    return beans;
}

@end

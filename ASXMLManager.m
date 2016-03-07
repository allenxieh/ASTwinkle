//
//  ASXMLManager.m
//
//  Created by allen on 16/1/8.
//  Copyright © 2016年 Allen All rights reserved.
//

#import "ASXMLManager.h"
#import "GDataXMLNode.h"
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
@property (nonatomic,strong) NSArray<GDataXMLElement *> *beanElements;

@property (nonatomic,strong) NSMutableArray<GDataXMLDocument*> *xmlDocArr;

@property (nonatomic,strong) NSMutableDictionary *singletons; //!< 保存单例配置的对象

@property (nonatomic,strong) NSDictionary *classDic; //!< 将xml中所有的class缓存至字典

@property (nonatomic,strong) NSMutableDictionary *initializingClassPool; //!<初始化类池

@end

@implementation ASXMLManager

+ (void)load{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [DDTTYLogger sharedInstance].logFormatter = [ASTwinkleLoggerFormatter new];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
}

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
        
        NSMutableArray<GDataXMLElement *> *mBeansArr = [NSMutableArray new];
        self.xmlDocArr = [NSMutableArray new];
        
        for (GDataXMLElement *xmlElement in [_rootElement nodesForXPath:@"package" error:nil]) {
            NSString *xmlPath = [[xmlElement attributeForName:@"name"] stringValue];
            GDataXMLDocument *XMLDocTemp = [self p_readXML:xmlPath];
            GDataXMLElement *rootElementTemp = [XMLDocTemp rootElement];
            //需要将GDataXMLElement对象保持
            [self.xmlDocArr addObject:XMLDocTemp];
            [mBeansArr addObjectsFromArray:[rootElementTemp nodesForXPath:@"beans/bean" error:nil]];
        }
        
        //启动时检查id及class
        NSError *error;
        self.classDic = [self p_cacheClass:mBeansArr error:&error];
        if (error) {
            DDLogError(@"%@",[[[error userInfo] allValues] objectAtIndex:0]);
        }
        
        self.beanElements = [mBeansArr copy];
        
        self.singletons = [NSMutableDictionary new];
        
        self.initializingClassPool = [NSMutableDictionary new];
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
    id bean = [self.singletons valueForKey:className]?:[[[self.classDic valueForKey:className] alloc] init];;
    if (!bean) {
        DDLogError(@"<%@>无法被实例化",className);
    }
    DDLogInfo(@"装载<%@>",className);
    return bean;
}

- (id)p_getBeanWithId:(NSString *)idName{
    id bean;
    for (GDataXMLElement *beanElement in _beanElements){
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
                DDLogError(@"找不到id=<%@>对象",idName);
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
    for (GDataXMLElement *beanElement in _beanElements)
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
                        //获取bean实例
                        NSLog(@"%@",self.initializingClassPool);
                        if ([self.initializingClassPool valueForKey:name]) {
                            NSException *astException = [NSException exceptionWithName:@"ASTwinkle Error: BeanCurrentlyInCreationException" reason:[NSString stringWithFormat:@"line:%d <%@>循环依赖",__LINE__,name] userInfo:nil];
                            @throw astException;
                        }
                        instance = [self p_getBeanWithClass:name];
                        [self.initializingClassPool setValue:name forKey:name];
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
                                    @try {
                                        [instance setValue:subInstance forKey:[[propertyElement attributeForName:__kNameKey__] stringValue]];
                                    }
                                    @catch (NSException *exception) {
                                        
                                        NSException *astException = [NSException exceptionWithName:@"ASTwinkle ERROR" reason:[NSString stringWithFormat:@"\nASTwinkle ERROR\nline:%d <%@>找不到key值为<%@>属性",__LINE__,NSStringFromClass([instance class]),[[propertyElement attributeForName:__kNameKey__] stringValue]] userInfo:nil];
                                        @throw astException;
                                    }
                                    
                                }
                                else
                                {
                                    Protocol *protocol = NSProtocolFromString([[propertyElement attributeForName:__kProtocolNameKey__] stringValue]);
                                    subInstance = [self p_getBeanWithId:[[propertyElement attributeForName:__kRefKey__] stringValue]];
                                    if (subInstance && [self p_isSingleton:propertyElement]) {
                                        [self.singletons setValue:subInstance forKey:NSStringFromClass([subInstance class])];
                                    }
                                    if ([subInstance conformsToProtocol:protocol]) {
                                        @try {
                                            [instance setValue:subInstance forKey:[[propertyElement attributeForName:__kNameKey__] stringValue]];
                                        }
                                        @catch (NSException *exception) {
                                            NSException *astException = [NSException exceptionWithName:@"ASTwinkle ERROR" reason:[NSString stringWithFormat:@"\nASTwinkle ERROR\nline:%d <%@>找不到key值为<%@>属性",__LINE__,NSStringFromClass([instance class]),[[propertyElement attributeForName:__kNameKey__] stringValue]] userInfo:nil];
                                            @throw astException;
                                        }
                                        
                                    }
                                    else
                                    {
                                        DDLogError(@"<%@>不支持协议<%@>",[[propertyElement attributeForName:__kRefKey__] stringValue],[[propertyElement attributeForName:__kProtocolNameKey__] stringValue]);
                                    }
                                }
                            }
                            
                        }
                        
                    }
                    if (instance && [self p_isSingleton:beanElement]) {
                        [self.singletons setValue:instance forKey:NSStringFromClass([instance class])];
                    }
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
                        DDLogError(@"<%@>不支持协议<%@>",[[beanElement attributeForName:__kRefKey__] stringValue],name);
                    }
                }
            }
                break;
        }
        
    }
    [self.initializingClassPool removeAllObjects];
    return instance;
}


- (GDataXMLDocument *)p_readXML:(NSString *)path{
    DDLogInfo(@"%@",path);
    
    NSError *error;
    NSData *xmlData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:path ofType:nil]];
    
    GDataXMLDocument *document;
    
    if (xmlData) {
        if ([path hasSuffix:@"xml"]) {
            document = [[GDataXMLDocument alloc] initWithData:xmlData options:0 error:&error];
            if (!error) {
                return document;
            }else{
                DDLogError(@"%@",error.domain);
            }
            
        }else{
            //TODO: 读取加密后的xml
            /*
            NSData *decryptedData = [RNCryptor decryptData:xmlData
                                                password:__kAESKey__
                                                       error:&error];
            
            document = [[GDataXMLDocument alloc] initWithData:decryptedData options:0 error:&error];
            if (!error) {
                return document;
            }else{
                DDLogError(@"%@",error.domain);
            }
             */
        }
    }else{
        DDLogError(@"读取文件<%@>错误",path);
    }
    
    return document;
}


- (NSArray *)p_getBeans:(NSArray<GDataXMLElement *> *) beans{
    NSMutableDictionary *tempDic = [NSMutableDictionary new];
    for (GDataXMLElement *element in beans) {
        NSString *key = [[element attributeForName:__kIdKey__] stringValue];
        if (![tempDic valueForKey:key]) {
            [tempDic setValue:key forKey:key];
        }else{
            DDLogError(@"id<%@>重复定义",key);
            return nil;
        }
    }
    return beans;
}

- (NSDictionary *)p_cacheClass:(NSArray<GDataXMLElement *> *) beans error:(NSError **)error{
    NSMutableDictionary *tempDic = [NSMutableDictionary new];
    NSMutableDictionary *classDic = [NSMutableDictionary new];
    for (GDataXMLElement *element in beans) {
        NSString *idValue = [[element attributeForName:__kIdKey__] stringValue];
        if (idValue) {
            if (![tempDic valueForKey:idValue]) {
                [tempDic setValue:idValue forKey:idValue];
            }else{
                if (error) {
                    *error = [NSError errorWithDomain:@"com.ASTwinkle"
                                                 code:-1
                                             userInfo:@{@"ErrorInfo":[NSString stringWithFormat:@"id<%@>重复定义",idValue]}];
                }
                return nil;
            }
        }
        
        NSString *classNameValue = [[element attributeForName:__kClassNameKey__] stringValue];
        if (classNameValue) {
            Class class = NSClassFromString(classNameValue);
            if (!class) {
                if (error) {
                    *error = [NSError errorWithDomain:@"com.ASTwinkle"
                                                 code:-1
                                             userInfo:@{@"ErrorInfo":[NSString stringWithFormat:@"class<%@>加载失败",classNameValue]}];
                    return nil;
                }
            }else{
                [classDic setValue:class forKey:classNameValue];
            }
        }
        if ([element children].count) {
            for (GDataXMLElement *childrenElement in element.children) {
                NSString *childrenClassNameValue = [[childrenElement attributeForName:__kClassNameKey__] stringValue];
                if (childrenClassNameValue) {
                    Class class = NSClassFromString(childrenClassNameValue);
                    if (!class) {
                        if (error) {
                            *error = [NSError errorWithDomain:@"com.ASTwinkle"
                                                         code:-1
                                                     userInfo:@{@"ErrorInfo":[NSString stringWithFormat:@"class<%@>加载失败",childrenClassNameValue]}];
                            return nil;
                        }
                    }else{
                        [classDic setValue:class forKey:childrenClassNameValue];
                    }
                }
            }
        }
        
    }
    return classDic;
}


@end

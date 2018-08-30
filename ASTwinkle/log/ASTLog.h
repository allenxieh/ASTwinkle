//
//  ASTLog.h
//
//  Created by allen on 16/4/12.
//  Copyright © 2016年 Allen All rights reserved.
//

#import <Foundation/Foundation.h>

@class ASTLogMessage,ASTLogger;
@protocol ASTLogFormatter;
typedef NS_OPTIONS(NSUInteger, ASTLogFlag){
    /**
     *  0...00000 ASTLogFlagError
     */
    ASTLogFlagError      = (1 << 0),
    
    /**
     *  0...00001 ASTLogFlagWarning
     */
    ASTLogFlagWarning    = (1 << 1),
    
    /**
     *  0...00010 ASTLogFlagInfo
     */
    ASTLogFlagInfo       = (1 << 2),
    
    /**
     *  0...00100 ASTLogFlagDebug
     */
    ASTLogFlagDebug      = (1 << 3),
    
    /**
     *  0...01000 ASTLogFlagVerbose
     */
    ASTLogFlagVerbose    = (1 << 4)
};

/**
 *  Log levels are used to filter out logs. Used together with flags.
 */
typedef NS_ENUM(NSUInteger, ASTLogLevel){
    /**
     *  No logs
     */
    ASTLogLevelOff       = 0,
    
    /**
     *  Error logs only
     */
    ASTLogLevelError     = (ASTLogFlagError),
    
    /**
     *  Error and warning logs
     */
    ASTLogLevelWarning   = (ASTLogLevelError   | ASTLogFlagWarning),
    
    /**
     *  Error, warning and info logs
     */
    ASTLogLevelInfo      = (ASTLogLevelWarning | ASTLogFlagInfo),
    
    /**
     *  Error, warning, info and debug logs
     */
   ASTLogLevelDebug     = (ASTLogLevelInfo    | ASTLogFlagDebug),
    
    /**
     *  Error, warning, info, debug and verbose logs
     */
    ASTLogLevelVerbose   = (ASTLogLevelDebug   |ASTLogFlagVerbose),
    
    /**
     *  All logs (1...11111)
     */
    ASTLogLevelAll       = NSUIntegerMax
};

@interface ASTLog : NSObject

@property (nonatomic,strong) ASTLogger *logger;

+ (void)level:(ASTLogLevel)level
         flag:(ASTLogFlag)flag
         file:(const char *)file
     function:(const char *)function
         line:(NSUInteger)line
       format:(NSString *)format, ... NS_FORMAT_FUNCTION(6,7);
@end


@protocol ASTLogFormatter <NSObject>

@required
- (NSString *)formatLogMessage:(ASTLogMessage *)logMessage;

@end

/**
 *  @author Allen, 16-04-27 10:04:15
 *
 *  @brief 日志消息
 */
@interface ASTLogMessage : NSObject

@property (nonatomic,readonly) NSString *message;
@property (nonatomic,readonly) NSString *fileName;
@property (nonatomic,readonly) NSString *function;
@property (nonatomic, readonly) NSUInteger line;
@property (nonatomic,readonly) NSDate *timestamp;
@property (nonatomic, readonly) ASTLogLevel level;
@property (nonatomic, readonly) ASTLogFlag flag;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithMessage:(NSString *)message
                           file:(NSString *)file
                          level:(ASTLogLevel)level
                           flag:(ASTLogFlag)flag
                       function:(NSString *)function
                           line:(NSUInteger)line
                      timestamp:(NSDate *)timestamp NS_DESIGNATED_INITIALIZER;

@end

@interface ASTLogger : NSObject<ASTLogFormatter>

@end

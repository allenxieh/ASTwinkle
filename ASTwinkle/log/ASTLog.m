//
//  ASTLog.m
//
//  Created by allen on 16/4/12.
//  Copyright © 2016年 Allen All rights reserved.
//

#import "ASTLog.h"

@implementation ASTLog

+ (void)level:(ASTLogLevel)level
         flag:(ASTLogFlag)flag
         file:(const char *)file
     function:(const char *)function
         line:(NSUInteger)line
       format:(NSString *)format, ...{
    va_list args;
    
    if (format) {
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        
        ASTLogMessage *logMessage = [[ASTLogMessage alloc] initWithMessage:message file:[NSString stringWithUTF8String:file] level:level flag:flag function:[NSString stringWithUTF8String:function] line:line timestamp:[NSDate date]];
        fprintf(stderr,"%s\n",[[[ASTLogger new] formatLogMessage:logMessage] UTF8String]);
        va_end(args);
    }
}

@end

@implementation ASTLogMessage

- (instancetype)initWithMessage:(NSString *)message
                           file:(NSString *)file
                          level:(ASTLogLevel)level
                           flag:(ASTLogFlag)flag
                       function:(NSString *)function
                           line:(NSUInteger)line
                      timestamp:(NSDate *)timestamp{
    if (self = [super init]) {
        _message      = [message copy];
        _level        = level;
        _flag         = flag;
        _line         = line;
        _timestamp    = timestamp ?: [NSDate new];
        _fileName = [file lastPathComponent];
        _function = function;
        NSUInteger dotLocation = [_fileName rangeOfString:@"." options:NSBackwardsSearch].location;
        if (dotLocation != NSNotFound)
        {
            _fileName = [_fileName substringToIndex:dotLocation];
        }
    }
    return self;
}

@end

@interface ASTLogger()

@property (nonatomic,strong)NSDateFormatter *threadUnsafeDateFormatter;

@end

@implementation ASTLogger

- (instancetype)init {
    if((self = [super init])) {
        self.threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
        [self.threadUnsafeDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
    }
    return self;
}

-(NSString *)formatLogMessage:(ASTLogMessage *)logMessage{
    NSString *logLevel;
    
    NSString *dateAndTime = [self.threadUnsafeDateFormatter stringFromDate:(logMessage.timestamp)];
    NSString *function = logMessage.function;
    NSString *logMsg = logMessage.message;
    NSString *fileName = logMessage.fileName;
    NSUInteger line = logMessage.line;
    NSString *formatMessage;
    
    switch (logMessage.flag) {
        case ASTLogFlagError    :
        {
            logLevel = @"[ERROR]";
            formatMessage = [NSString stringWithFormat:@"%@ %@ %@ line:%lul %@", dateAndTime, logLevel, function, line,logMsg];
        }
            break;
        case ASTLogFlagWarning  :
        {
            logLevel = @"[WARNING]";
            formatMessage = [NSString stringWithFormat:@"%@ %@ %@ line:%lul %@", dateAndTime, logLevel, function, line,logMsg];
        }
            break;
        case ASTLogFlagInfo:
        {
            logLevel = @"[INFO]";
            formatMessage = [NSString stringWithFormat:@"%@ %@ [%@] %@", dateAndTime, logLevel, fileName, logMsg];
        }
            break;
        case ASTLogFlagDebug    :
        {
            logLevel = @"[DEBUG]";
            formatMessage = [NSString stringWithFormat:@"%@ %@ %@ line:%lul %@", dateAndTime, logLevel, function, line,logMsg];
        }
            break;
        default                :
        {
            logLevel = @"[VERBOSE]";
        }
            break;
    }
    
    
    
    return formatMessage;
}

@end

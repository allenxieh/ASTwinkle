//
//  ASTwinkleLoggerFormatter.m
//
//  Created by allen on 16/1/13.
//  Copyright © 2016年 com.juwang.lumberJack. All rights reserved.
//

#import "ASTwinkleLoggerFormatter.h"

@interface ASTwinkleLoggerFormatter ()
{
    int loggerCount;
    NSDateFormatter *threadUnsafeDateFormatter;
}
@end

@implementation ASTwinkleLoggerFormatter

- (id)init {
    if((self = [super init])) {
        threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
        [threadUnsafeDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage{
    NSString *logLevel;
    
    NSString *dateAndTime = [threadUnsafeDateFormatter stringFromDate:(logMessage->_timestamp)];
    NSString *function = logMessage->_function;
    NSString *logMsg = logMessage->_message;
    NSString *fileName = logMessage->_fileName;
    NSUInteger line = logMessage->_line;
    
    NSString *formatMessage;
    
    switch (logMessage->_flag) {
        case DDLogFlagError    :
        {
            logLevel = @"[ERROR]";
            formatMessage = [NSString stringWithFormat:@"%@ %@ %@ line:%ld %@", dateAndTime, logLevel, function, line,logMsg];
        }
            break;
        case DDLogFlagWarning  :
        {
            logLevel = @"[WARNING]";
            formatMessage = [NSString stringWithFormat:@"%@ %@ %@ line:%ld %@", dateAndTime, logLevel, function, line,logMsg];
        }
            break;
        case DDLogFlagInfo     :
        {
            logLevel = @"[INFO]";
            formatMessage = [NSString stringWithFormat:@"%@ %@ [%@] %@", dateAndTime, logLevel, fileName, logMsg];
        }
            break;
        case DDLogFlagDebug    :
        {
            logLevel = @"[DEBUG]";
            formatMessage = [NSString stringWithFormat:@"%@ %@ %@ line:%ld %@", dateAndTime, logLevel, function, line,logMsg];
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

- (void)didAddToLogger:(id <DDLogger>)logger {
    loggerCount++;
    NSAssert(loggerCount <= 1, @"This logger isn't thread-safe");
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger {
    loggerCount--;
}

@end

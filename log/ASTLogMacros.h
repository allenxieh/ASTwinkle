//
//  ASTLogMacros.h
//  如意夺宝
//
//  Created by allen on 16/4/14.
//  Copyright © 2016年 com.juwang.rydb. All rights reserved.
//

#ifndef ASTLogMacros_h
#define ASTLogMacros_h

#ifndef ASTLOG_LEVEL_DEF
#define ASTLOG_LEVEL_DEF ASTLogLevelDef
#endif

#define ASTLOG_MACRO(lvl, flg, fnct, frmt, ...)                            \
        [ASTLog level : lvl                                             \
        flag : flg                                                      \
        file : __FILE__                                                 \
        function : fnct                                                 \
        line : __LINE__                                                 \
        format : (frmt), ## __VA_ARGS__]

#define ASTLOG_MAYBE(lvl, flg, fnct, frmt, ...) \
do { if(lvl & flg) ASTLOG_MACRO(lvl, flg, fnct, frmt, ##__VA_ARGS__); } while(0)

#ifdef ASTLogLevelDef
#define ASTLogError(frmt, ...)   ASTLOG_MAYBE(ASTLOG_LEVEL_DEF, ASTLogFlagError, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define ASTLogWarn(frmt, ...)    ASTLOG_MAYBE(ASTLOG_LEVEL_DEF, ASTLogFlagWarning, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define ASTLogInfo(frmt, ...)    ASTLOG_MAYBE(ASTLOG_LEVEL_DEF, ASTLogFlagInfo, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define ASTLogDebug(frmt, ...)   ASTLOG_MAYBE(ASTLOG_LEVEL_DEF, ASTLogFlagDebug, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define ASTLogVerbose(frmt, ...) ASTLOG_MAYBE(ASTLOG_LEVEL_DEF, ASTLogFlagVerbose, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#else
#define ASTLogError(frmt, ...)
#define ASTLogWarn(frmt, ...)
#define ASTLogInfo(frmt, ...)
#define ASTLogDebug(frmt, ...)
#define ASTLogVerbose(frmt, ...)
#endif

#endif /* ASTLogMacros_h */

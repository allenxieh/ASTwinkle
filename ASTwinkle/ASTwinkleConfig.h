//
//  ASTwinkleConfig.h
//
//  Created by allen on 16/1/8.
//  Copyright © 2016年 Allen All rights reserved.
//

#ifndef ASTwinkleConfig_h
#define ASTwinkleConfig_h

#define ASTLogLevelDef ASTLogLevelOff //!< 定义日志等级

#import "ASTwinkleLog.h"

#define ASDEBUG 1

#if ASDEBUG

#define __kXMLPath__ @"ApplicationContext.xml"
#define __kAESKey__ @""

#else

#define __kXMLPath__ @"ApplicationContext.juwang"
#define __kAESKey__ @"com.juwang"

#endif

#endif /* ASTwinkleConfig_h */

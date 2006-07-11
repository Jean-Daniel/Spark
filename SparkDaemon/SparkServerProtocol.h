//
//  SparkServerProtocol.h
//  Spark
//
//  Created by Fox on Thu Dec 11 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#if !defined(__SPARK_SERVER_PROTOCOL_H)
#define __SPARK_SERVER_PROTOCOL_H 1

#import "SparkAppleScriptSuite.h"

enum {
  kSparkActionObjectType = 'acti',
  kSparkTriggerObjectType = 'trig',
  kSparkApplicationObjectType = 'appl'
};

#if defined(__OBJC__)

#if defined(DEBUG)
#define kSparkConnectionName		@"SparkServer_Debug"
#else
#define kSparkConnectionName		@"SparkServer"
#endif

@protocol SparkServer

- (oneway void)shutDown;

- (oneway void)addObject:(bycopy id)plist type:(in OSType)type;
- (oneway void)updateObject:(bycopy id)plist type:(in OSType)type;
- (oneway void)removeObject:(in UInt32)uid type:(in OSType)type;

//- (BOOL)setTrigger:(UInt32)uid enabled:(BOOL)flag;

@end

#endif /* __OBJC__ */

#endif /* __SPARK_SERVER_PROTOCOL_H */

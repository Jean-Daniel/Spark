/*
 *  SparkServerProtocol.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#if !defined(__SPARK_SERVER_PROTOCOL_H)
#define __SPARK_SERVER_PROTOCOL_H 1

enum {
  kSparkActionType = 'acti',
  kSparkTriggerType = 'trig',
  kSparkApplicationType = 'appl'
};

#if defined(__OBJC__)

#if defined(DEBUG)
#define kSparkConnectionName		@"SparkServer_Debug"
#else
#define kSparkConnectionName		@"SparkServer"
#endif

@protocol SparkServer

- (oneway void)shutdown;

//- (oneway void)addEntry:(in SparkFlatEntry *)entry;
//- (oneway void)removeEntry:(in SparkFlatEntry *)entry;

- (oneway void)addObject:(bycopy id)plist type:(in OSType)type;
- (oneway void)updateObject:(bycopy id)plist type:(in OSType)type;
- (oneway void)removeObject:(in UInt32)uid type:(in OSType)type;

@end

#endif /* __OBJC__ */

#endif /* __SPARK_SERVER_PROTOCOL_H */

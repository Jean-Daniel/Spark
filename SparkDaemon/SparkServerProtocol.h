//
//  SparkServerProtocol.h
//  Spark
//
//  Created by Fox on Thu Dec 11 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#ifndef __SPARK_SERVER_PROTOCOL
#define __SPARK_SERVER_PROTOCOL

#import "SparkAppleScriptSuite.h"

#ifdef __OBJC__

#ifdef DEBUG
#define kSparkConnectionName		@"SparkServer_Debug"
#else
#define kSparkConnectionName		@"SparkServer"
#endif

@protocol SparkServer

- (oneway void)shutDown;

- (oneway void)addList:(bycopy id)plist;
- (oneway void)updateList:(bycopy id)plist;
- (oneway void)removeList:(unsigned)uid;

- (oneway void)addAction:(bycopy id)plist;
- (oneway void)updateAction:(bycopy id)plist;
- (oneway void)removeAction:(unsigned)uid;

- (oneway void)addHotKey:(bycopy id)plist;
- (oneway void)updateHotKey:(bycopy id)plist;
- (oneway void)removeHotKey:(unsigned)uid;
- (BOOL)setActive:(BOOL)flag forHotKey:(unsigned)keyUid;

- (oneway void)addApplication:(bycopy id)plist;
- (oneway void)updateApplication:(bycopy id)plist;
- (oneway void)removeApplication:(unsigned)uid;

@end

#endif  /* __OBJC__ */

#endif /* __SPARK_SERVER_PROTOCOL */
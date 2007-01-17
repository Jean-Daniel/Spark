/*
 *  SparkServerProtocol.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#if !defined(__SPARK_SERVER_PROTOCOL_H)
#define __SPARK_SERVER_PROTOCOL_H 1

#if defined(__OBJC__)

#if defined(DEBUG)
#define kSparkConnectionName		@"SparkServer_Debug"
#else
#define kSparkConnectionName		@"SparkServer"
#endif

@protocol SparkLibrary;
@protocol SparkServer

- (int)version;

- (oneway void)shutdown;

- (id<SparkLibrary>)library;

@end

#endif /* __OBJC__ */

#endif /* __SPARK_SERVER_PROTOCOL_H */

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
  #define kSparkConnectionName		@"org.shadowlab.spark.server.debug"
#else
  #define kSparkConnectionName		@"org.shadowlab.spark.server"
#endif

@protocol SparkLibrary;
@protocol SparkServer

@property (readonly) uint32_t version;
@property (readonly,getter=isEnabled) BOOL enabled;

- (oneway void)shutdown;

@property (readonly) NSDistantObject<SparkLibrary> *library;

@end

#endif /* __OBJC__ */

#endif /* __SPARK_SERVER_PROTOCOL_H */

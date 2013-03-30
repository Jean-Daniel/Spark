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
	#if __LP64__
		#define kSparkConnectionName		@"org.shadowlab.spark.server.debug.64"
	#else
		#define kSparkConnectionName		@"org.shadowlab.spark.server.debug"
	#endif
#else
	#if __LP64__
		#define kSparkConnectionName		@"org.shadowlab.spark.server.64"
	#else
		#define kSparkConnectionName		@"org.shadowlab.spark.server"
	#endif
#endif

@protocol SparkLibrary;
@protocol SparkServer

- (UInt32)version;

- (oneway void)shutdown;

- (NSDistantObject<SparkLibrary> *)library;

@end

#endif /* __OBJC__ */

#endif /* __SPARK_SERVER_PROTOCOL_H */

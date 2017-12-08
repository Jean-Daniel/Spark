/*
 *  ServerController.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEScriptHandler.h"
#import <SparkKit/SparkServerProtocol.h>

SPARK_PRIVATE
NSString * const SEServerStatusDidChangeNotification;

@class SparkLibrarySynchronizer;
@interface SEServerConnection : NSObject

+ (SEServerConnection *)defaultConnection;

- (BOOL)connect;
- (void)disconnect;
- (BOOL)isConnected;

@property (readonly) NSDistantObject<SparkServer> *server;

/* Daemon control */
- (void)restart;
- (void)shutdown;

- (BOOL)isRunning;
- (SparkDaemonStatus)status;

- (uint32_t)version;

@end

SPARK_PRIVATE
NSString * const kSparkDaemonExecutableName;

SPARK_PRIVATE
BOOL SELaunchSparkDaemon(pid_t *pid);
SPARK_PRIVATE
NSURL *SESparkDaemonURL(void);
SPARK_PRIVATE
void SEServerStartConnection(void);
SPARK_PRIVATE
void SEServerStopConnection(void);

SPARK_PRIVATE
BOOL SEDaemonIsEnabled(void);


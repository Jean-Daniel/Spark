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
@interface SEServerConnection : NSObject {
  @private
  struct _se_scFlags {
    unsigned int fail:1;
    unsigned int restart:1;
    unsigned int reserved:30;
  } se_scFlags;
  SparkDaemonStatus se_status;
  SparkLibrarySynchronizer *se_sync;
  NSDistantObject<SparkServer> *se_server;
}

+ (SEServerConnection *)defaultConnection;

- (BOOL)connect;
- (void)disconnect;
- (BOOL)isConnected;

- (NSDistantObject<SparkServer> *)server;

/* Daemon control */
- (void)restart;
- (void)shutdown;

- (BOOL)isRunning;
- (SparkDaemonStatus)status;

- (UInt32)version;

@end

SPARK_PRIVATE
NSString * const kSparkDaemonExecutableName;

SPARK_PRIVATE
BOOL SELaunchSparkDaemon(ProcessSerialNumber *psn);
SPARK_PRIVATE
NSString *SESparkDaemonPath(void);
SPARK_PRIVATE
void SEServerStartConnection(void);
SPARK_PRIVATE
void SEServerStopConnection(void);

SPARK_PRIVATE
BOOL SEDaemonIsEnabled(void);


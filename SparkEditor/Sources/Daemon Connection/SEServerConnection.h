/*
 *  ServerController.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEScriptHandler.h"
#import <SparkKit/SparkServerProtocol.h>

@class SparkLibrarySynchronizer;
@interface SEServerConnection : NSObject {
  @private
  struct _se_scFlags {
    unsigned int fail:1;
    unsigned int restart:1;
    unsigned int reserved:30;
  } se_scFlags;
  SparkLibrarySynchronizer *se_sync;
  NSDistantObject<SparkServer> *se_server;
}

+ (SEServerConnection *)defaultConnection;

- (void)restart;
- (void)shutdown;

- (BOOL)connect;
- (BOOL)isConnected;

- (int)version;
- (NSDistantObject<SparkServer> *)server;

@end

SK_PRIVATE
NSString * const kSparkDaemonExecutableName;

SK_PRIVATE
BOOL SELaunchSparkDaemon(void);
SK_PRIVATE
NSString *SESparkDaemonPath(void);
SK_PRIVATE
void SEServerStartConnection(void);

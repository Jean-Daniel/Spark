/*
 *  ServerController.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SEScriptHandler.h"
#import <SparkKit/SparkServerProtocol.h>

@interface SEServerConnection : NSObject {
  @private
  struct _se_scFlags {
    unsigned int fail:1;
    unsigned int reserved:31;
  } se_scFlags;
  NSDistantObject<SparkServer> *se_server;
}

+ (SEServerConnection *)defaultConnection;

- (BOOL)connect;
- (BOOL)isConnected;

- (id<SparkServer>)server;

@end

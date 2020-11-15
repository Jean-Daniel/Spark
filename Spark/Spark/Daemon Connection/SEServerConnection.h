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
@interface SEAgentConnection : NSObject <SparkEditor>

+ (NSURL *)agentURL;

+ (SEAgentConnection *)defaultConnection;

- (void)restart;
- (BOOL)isRunning;
- (SparkDaemonStatus)status;

@end

// Set Agent enabled (start login item)
SPARK_PRIVATE
BOOL SESparkAgentIsEnabled(pid_t *pid);

SPARK_PRIVATE
BOOL SESparkAgentSetEnabled(BOOL enabled);

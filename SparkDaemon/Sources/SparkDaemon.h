/*
 *  SparkDaemon.h
 *  SparkServer
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkServerProtocol.h>

@class SparkDistantLibrary;
@interface SparkDaemon : NSObject {
  BOOL sd_disabled;
  SparkDistantLibrary *sd_library;
}

- (BOOL)openConnection;

- (void)loadTriggers;
- (void)registerTriggers;
- (void)unregisterTriggers;
- (void)unregisterVolatileTriggers;

- (void)checkActions;

- (void)run;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

@end

@interface SparkDaemon (SparkServerProtocol) <SparkServer>

- (int)version;
- (void)shutdown;

- (id<SparkLibrary>)library;

@end

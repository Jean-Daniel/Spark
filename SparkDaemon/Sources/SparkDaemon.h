/*
 *  SparkDaemon.h
 *  SparkServer
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkServerProtocol.h>
#import <SparkKit/SparkAppleScriptSuite.h>

@class SparkLibrary, SparkDistantLibrary;
@interface SparkDaemon : NSObject {
  BOOL sd_disabled;
  SparkLibrary *sd_library;
  SparkDistantLibrary *sd_rlibrary;
}

- (BOOL)openConnection;
- (void)closeConnection;

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

- (UInt32)version;
- (void)shutdown;

- (id<SparkLibrary>)library;

@end

SK_PRIVATE
void SDSendStateToEditor(SparkDaemonStatus state);

/*
 *  SparkDaemon.h
 *  SparkServer
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkServerProtocol.h>
#import <SparkKit/SparkAppleScriptSuite.h>

@class SparkApplication, SparkEntry;
@class SparkLibrary, SparkDistantLibrary;
@interface SparkDaemon : NSObject {
  BOOL sd_disabled;
  SparkLibrary *sd_library;
  SparkApplication *sd_front;
  SparkDistantLibrary *sd_rlibrary;
  
  NSLock *sd_lock;
  NSMapTable *sd_locks;
  
  /* Growl support */
  NSMutableArray *sd_growl;
}

- (BOOL)openConnection;
- (void)closeConnection;

- (void)registerEntries;
- (void)unregisterEntries;
- (void)unregisterVolatileEntries;
- (void)setEntryStatus:(SparkEntry *)entry; // register or unregister an entry

- (void)checkActions;

- (void)run;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

- (void)frontApplicationDidChange:(ProcessSerialNumber *)psn;

@end

@interface SparkDaemon (SparkServerProtocol) <SparkServer>

- (UInt32)version;
- (void)shutdown;

- (id<SparkLibrary>)library;

@end

WB_PRIVATE
void SDSendStateToEditor(SparkDaemonStatus state);

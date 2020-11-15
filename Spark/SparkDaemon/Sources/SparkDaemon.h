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

@interface SparkDaemon : NSObject<NSApplicationDelegate> {
  SparkLibrary *sd_library;
  SparkApplication *sd_front;
  SparkDistantLibrary *sd_rlibrary;
}

- (void)openConnection;
- (void)closeConnection;

- (void)registerEntries;
- (void)unregisterEntries;
- (void)unregisterVolatileEntries;
- (void)setEntryStatus:(SparkEntry *)entry; // register or unregister an entry

- (void)checkActions;

- (void)run;

@property (readonly,getter=isEnabled) BOOL enabled;

- (void)frontApplicationDidChange:(NSRunningApplication *)app;

@end

@interface SparkDaemon (SparkServerProtocol)

#pragma mark Notifications
- (void)didAddEntry:(NSNotification *)aNotification;
- (void)didUpdateEntry:(NSNotification *)aNotification;
- (void)didRemoveEntry:(NSNotification *)aNotification;
- (void)didChangeEntryStatus:(NSNotification *)aNotification;

- (void)didChangePlugInStatus:(NSNotification *)aNotification;

- (void)willRemoveTrigger:(NSNotification *)aNotification;
- (void)willRemoveApplication:(NSNotification *)aNotification;
- (void)didChangeApplicationStatus:(NSNotification *)aNotification;

@end

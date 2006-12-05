/*
 *  SparkDaemon.h
 *  SparkServer
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkServerProtocol.h>

@class SparkTrigger, SparkLibrary, SparkActionLibrary;
@interface SparkDaemon : NSObject {
  BOOL sd_disabled;
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

- (void)addObject:(id)plist type:(OSType)type;
- (void)updateObject:(id)plist type:(OSType)type;
- (void)removeObject:(UInt32)uid type:(OSType)type;

#pragma mark Entries Management
- (void)addLibraryEntry:(SparkLibraryEntry *)anEntry;
- (void)removeLibraryEntry:(SparkLibraryEntry *)anEntry;
- (void)replaceLibraryEntry:(SparkLibraryEntry *)anEntry withLibraryEntry:(SparkLibraryEntry *)newEntry;

- (void)enableLibraryEntry:(SparkLibraryEntry *)anEntry;
- (void)disableLibraryEntry:(SparkLibraryEntry *)anEntry;

#pragma mark Plugins Management
- (void)enablePlugIn:(NSString *)plugin;
- (void)disablePlugIn:(NSString *)plugin;

- (void)registerPlugIn:(NSString *)plugin;

@end

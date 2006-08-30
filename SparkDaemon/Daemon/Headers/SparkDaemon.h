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
  
}

- (BOOL)openConnection;
- (void)loadTriggers;
- (void)checkActions;

- (void)run;

@end

@interface SparkDaemon (SparkServerProtocol) <SparkServer>

- (void)shutdown;

- (void)addObject:(id)plist type:(OSType)type;
- (void)updateObject:(id)plist type:(OSType)type;
- (void)removeObject:(UInt32)uid type:(OSType)type;

- (void)addLibraryEntry:(SparkLibraryEntry *)anEntry;
- (void)removeLibraryEntry:(SparkLibraryEntry *)anEntry;
- (void)replaceLibraryEntry:(SparkLibraryEntry *)anEntry withLibraryEntry:(SparkLibraryEntry *)newEntry;

- (void)setStatus:(BOOL)status forLibraryEntry:(SparkLibraryEntry *)anEntry;

@end

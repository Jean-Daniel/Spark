//
//  ServerController.h
//  Spark
//
//  Created by Fox on Thu Dec 11 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkServerProtocol.h>

@class SparkTrigger, SparkLibrary, SparkActionLibrary;
@interface SparkDaemon : NSObject {
}

- (BOOL)openConnection;
- (void)loadTriggers;
- (void)checkActions;

- (void)didAddTrigger:(SparkTrigger *)aTrigger;
- (void)willRemoveTrigger:(SparkTrigger *)aTrigger;

- (void)run;

@end

@interface SparkDaemon (SparkServerProtocol) <SparkServer>

- (void)shutdown;

- (void)enableTrigger:(UInt32)uid;
- (void)disableTrigger:(UInt32)uid;

- (void)addEntry:(SparkEntry *)entry;
- (void)removeEntryAtIndex:(UInt32)idx;

- (void)addObject:(id)plist type:(OSType)type;
- (void)updateObject:(id)plist type:(OSType)type;
- (void)removeObject:(UInt32)uid type:(OSType)type;

@end

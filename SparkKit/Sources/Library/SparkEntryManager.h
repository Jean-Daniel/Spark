/*
 *  SparkEntryManager.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

#pragma mark Notifications

SPARK_EXPORT
NSString * const SparkEntryManagerWillAddEntryNotification;
SPARK_EXPORT
NSString * const SparkEntryManagerDidAddEntryNotification;

SPARK_EXPORT
NSString * const SparkEntryManagerWillUpdateEntryNotification;
SPARK_EXPORT
NSString * const SparkEntryManagerDidUpdateEntryNotification;

SPARK_EXPORT
NSString * const SparkEntryManagerWillRemoveEntryNotification;
SPARK_EXPORT
NSString * const SparkEntryManagerDidRemoveEntryNotification;

SPARK_EXPORT
NSString * const SparkEntryManagerDidChangeEntryEnabledNotification;

@class SparkAction;
@class SparkLibrary, SparkEntry;
@interface SparkEntryManager : NSObject {
  @private
  SparkLibrary *sp_library; /* __weak */
  CFMutableSetRef sp_set;
  CFMutableArrayRef sp_entries;
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary;

- (SparkLibrary *)library;
- (NSUndoManager *)undoManager;

#pragma mark Management
- (void)addEntry:(SparkEntry *)anEntry;
- (void)removeEntry:(SparkEntry *)anEntry;
- (void)removeEntries:(NSArray *)theEntries;
- (void)replaceEntry:(SparkEntry *)anEntry withEntry:(SparkEntry *)newEntry;

- (void)enableEntry:(SparkEntry *)anEntry;
- (void)disableEntry:(SparkEntry *)anEntry;

#pragma mark Queries
- (NSArray *)entriesForAction:(UInt32)anAction;
- (NSArray *)entriesForTrigger:(UInt32)aTrigger;
- (NSArray *)entriesForApplication:(UInt32)anApplication;

- (BOOL)containsEntry:(SparkEntry *)anEntry;
- (BOOL)containsEntryForAction:(UInt32)anAction;
- (BOOL)containsEntryForTrigger:(UInt32)aTrigger;
- (BOOL)containsEntryForApplication:(UInt32)anApplication;

- (BOOL)containsActiveEntryForTrigger:(UInt32)aTrigger;
- (BOOL)containsOverwriteEntryForTrigger:(UInt32)aTrigger;
- (BOOL)containsPermanentEntryForTrigger:(UInt32)aTrigger;

- (BOOL)containsEntryForTrigger:(UInt32)aTrigger application:(UInt32)anApplication;
- (SparkEntry *)entryForTrigger:(UInt32)aTrigger application:(UInt32)anApplication;
- (SparkAction *)actionForTrigger:(UInt32)aTrigger application:(UInt32)anApplication isActive:(BOOL *)status;

@end

#pragma mark Serialization
@interface SparkEntryManager (SparkSerialization)
- (NSFileWrapper *)fileWrapper:(NSError **)outError;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError;

/* private: v1 import */
- (void)postProcess;
- (void)addEntryWithAction:(UInt32)action trigger:(UInt32)trigger application:(UInt32)application enabled:(BOOL)enabled;

@end

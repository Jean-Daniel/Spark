/*
 *  SparkEntryManager.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

typedef struct _SparkLibraryEntry {
  UInt32 status;
  UInt32 action;
  UInt32 trigger;
  UInt32 application;
} SparkLibraryEntry;

@class SparkAction;
@class SparkLibrary, SparkEntry;
@interface SparkEntryManager : NSObject {
  @private
  SparkLibrary *sp_library; /* __weak */
  CFMutableSetRef sp_set;
  CFMutableArrayRef sp_entries;
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary;

- (void)addEntry:(SparkEntry *)anEntry;
- (void)removeEntry:(SparkEntry *)anEntry;
- (void)replaceEntry:(SparkEntry *)anEntry withEntry:(SparkEntry *)newEntry;

- (BOOL)statusForEntry:(SparkEntry *)anEntry;
- (void)setStatus:(BOOL)status forEntry:(SparkEntry *)anEntry;

- (NSArray *)entriesForAction:(UInt32)anAction;
- (NSArray *)entriesForTrigger:(UInt32)aTrigger;
- (NSArray *)entriesForApplication:(UInt32)anApplication;

- (BOOL)containsEntry:(SparkEntry *)anEntry;
- (BOOL)containsEntryForAction:(UInt32)anAction;
- (BOOL)containsEntryForTrigger:(UInt32)aTrigger;
- (BOOL)containsEntryForApplication:(UInt32)anApplication;
- (BOOL)containsActiveEntryForTrigger:(UInt32)aTrigger;

- (BOOL)containsEntryForTrigger:(UInt32)aTrigger application:(UInt32)anApplication;
- (SparkEntry *)entryForTrigger:(UInt32)aTrigger application:(UInt32)anApplication;
- (SparkAction *)actionForTrigger:(UInt32)aTrigger application:(UInt32)anApplication status:(BOOL *)status;

/* Private */
#pragma mark Low-Level Methods

- (void)addLibraryEntry:(SparkLibraryEntry *)anEntry;
- (void)removeLibraryEntry:(const SparkLibraryEntry *)anEntry;
- (void)replaceLibraryEntry:(SparkLibraryEntry *)anEntry withLibraryEntry:(SparkLibraryEntry *)newEntry;

- (void)setStatus:(BOOL)status forLibraryEntry:(SparkLibraryEntry *)anEntry;

@end

SPARK_EXPORT
NSString * const SparkEntryNotificationKey;
SPARK_EXPORT
NSString * const SparkEntryReplacedNotificationKey;

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

@interface SparkEntryManager (SparkSerialization)
- (NSFileWrapper *)fileWrapper:(NSError **)outError;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError;
@end


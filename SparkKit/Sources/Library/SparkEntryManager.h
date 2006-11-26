/*
 *  SparkEntryManager.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

typedef struct _SparkLibraryEntry {
  UInt32 flags;
  UInt32 action;
  UInt32 trigger;
  UInt32 application;
} SparkLibraryEntry;

enum {
  kSparkEntryEnabled = 1 << 0,
  kSparkEntryHidden = 1 << 1,
};

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
- (void)removeEntries:(NSArray *)theEntries;
- (void)replaceEntry:(SparkEntry *)anEntry withEntry:(SparkEntry *)newEntry;

- (BOOL)isEntryEnabled:(SparkEntry *)anEntry;
- (void)entry:(SparkEntry *)anEntry setEnabled:(BOOL)flag;

- (NSArray *)entriesForAction:(UInt32)anAction;
- (NSArray *)entriesForTrigger:(UInt32)aTrigger;
- (NSArray *)entriesForApplication:(UInt32)anApplication;

- (BOOL)containsEntry:(SparkEntry *)anEntry;
- (BOOL)containsEntryForAction:(UInt32)anAction;
- (BOOL)containsEntryForTrigger:(UInt32)aTrigger;
- (BOOL)containsEntryForApplication:(UInt32)anApplication;

- (BOOL)containsActiveEntryForTrigger:(UInt32)aTrigger;
- (BOOL)containsOverwriteEntryForTrigger:(UInt32)aTrigger;

- (BOOL)containsEntryForTrigger:(UInt32)aTrigger application:(UInt32)anApplication;
- (SparkEntry *)entryForTrigger:(UInt32)aTrigger application:(UInt32)anApplication;
- (SparkAction *)actionForTrigger:(UInt32)aTrigger application:(UInt32)anApplication enabled:(BOOL *)status;

/* Private */
#pragma mark Low-Level Methods
- (void)addLibraryEntry:(SparkLibraryEntry *)anEntry;
- (void)removeLibraryEntry:(const SparkLibraryEntry *)anEntry;
- (void)replaceLibraryEntry:(SparkLibraryEntry *)anEntry withLibraryEntry:(SparkLibraryEntry *)newEntry;

- (SparkLibraryEntry *)libraryEntryForEntry:(SparkEntry *)anEntry;
- (void)libraryEntry:(SparkLibraryEntry *)anEntry setEnabled:(BOOL)flag;

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

SPARK_EXPORT
NSString * const SparkEntryManagerWillChangeEntryStatusNotification;
SPARK_EXPORT
NSString * const SparkEntryManagerDidChangeEntryStatusNotification;

@interface SparkEntryManager (SparkSerialization)
- (NSFileWrapper *)fileWrapper:(NSError **)outError;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError;
@end


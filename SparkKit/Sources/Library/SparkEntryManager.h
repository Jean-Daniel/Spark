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
NSString * const SparkEntryManagerDidChangeEntryStatusNotification;

@class SparkObject;
@class SparkLibrary, SparkEntry;
SK_CLASS_EXPORT
@interface SparkEntryManager : NSObject {
  @private
  SparkLibrary *sp_library; /* __weak */
  //CFMutableSetRef sp_set;
  CFMutableArrayRef sp_entries;
  /* editing support */
  SparkObject *sp_edit[3];
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary;

- (SparkLibrary *)library;
- (NSUndoManager *)undoManager;

/* Private, use to dereference weak */
- (void)setLibrary:(SparkLibrary *)library;

#pragma mark Management
- (SparkEntry *)entryWithUID:(UInt32)uid;

- (void)addEntry:(SparkEntry *)anEntry;
- (void)removeEntry:(SparkEntry *)anEntry;
- (void)removeEntries:(NSArray *)theEntries;

/* Internal use only */
- (void)updateEntry:(SparkEntry *)anEntry;

#pragma mark Queries
- (NSArray *)entriesForAction:(SparkUID)anAction;
- (NSArray *)entriesForTrigger:(SparkUID)aTrigger;
- (NSArray *)entriesForApplication:(SparkUID)anApplication;

- (BOOL)containsEntry:(SparkEntry *)anEntry;
- (BOOL)containsEntryForAction:(SparkUID)anAction;
- (BOOL)containsEntryForTrigger:(SparkUID)aTrigger;
- (BOOL)containsEntryForApplication:(SparkUID)anApplication;

- (BOOL)containsActiveEntryForTrigger:(SparkUID)aTrigger;
- (BOOL)containsOverwriteEntryForTrigger:(SparkUID)aTrigger;
//- (BOOL)containsPersistentEntryForTrigger:(SparkUID)aTrigger;

- (BOOL)containsPersistentActiveEntryForTrigger:(SparkUID)aTrigger;

//- (BOOL)containsEntryForTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication;
//- (SparkEntry *)entryForTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication;

/* return NULL if no active action found */
- (SparkEntry *)activeEntryForTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication;
- (SparkEntry *)child:(SparkEntry *)parent forTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication;

@end

#pragma mark Serialization
@interface SparkEntryManager (SparkSerialization)

//- (void)postProcess;

- (NSFileWrapper *)fileWrapper:(NSError **)outError;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError;

@end

@interface SparkEntryManager (SparkLegacyLibraryImporter)

- (void)postProcessLegacy;

@end

/*
 *  SparkEntryManagerPrivate.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkEntryManager.h>

@interface SparkEntryManager (SparkEntryEditor)

- (void)beginEditing:(SparkEntry *)anEntry;
- (void)endEditing:(SparkEntry *)anEntry;

- (void)enableEntry:(SparkEntry *)anEntry;
- (void)disableEntry:(SparkEntry *)anEntry;

@end

//typedef struct _SparkLibraryEntry {
//  SparkUID flags;
//  SparkUID action;
//  SparkUID trigger;
//  SparkUID application;
//} SparkLibraryEntry;
//
//enum {
//  /* Persistents flags */
//  kSparkEntryEnabled = 1 << 0,
//  /* Volatile flags */
//  kSparkEntryUnplugged = 1 << 16,
//  kSparkEntryPersistent = 1 << 17,
//  kSparkPersistentFlagsMask = 0xffff,
//};
//
//SPARK_PRIVATE
//void SparkLibraryEntryInitFlags(SparkLibraryEntry *lentry, SparkEntry *entry);

@class SparkTrigger;
@interface SparkEntryManager (SparkEntryManagerInternal)

- (void)checkTriggerValidity:(SparkTrigger *)trigger;
//- (void)removeEntriesForAction:(SparkUID)action;

//- (void)initInternal;
//- (void)deallocInternal;
//
//#pragma mark Low-Level Methods
//- (void)addLibraryEntry:(SparkLibraryEntry *)anEntry;
//- (void)removeLibraryEntry:(const SparkLibraryEntry *)anEntry;
//- (void)replaceLibraryEntry:(SparkLibraryEntry *)anEntry withLibraryEntry:(SparkLibraryEntry *)newEntry;
//
//- (void)setEnabled:(BOOL)flag forLibraryEntry:(SparkLibraryEntry *)anEntry;
//
///* Convert Library entry */
//- (SparkLibraryEntry *)libraryEntryForEntry:(SparkEntry *)anEntry;
//- (SparkLibraryEntry *)libraryEntryForTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication;
//
//- (SparkEntry *)entryForLibraryEntry:(const SparkLibraryEntry *)anEntry;
//
///* Library Entry info */
//- (SparkEntryType)typeForLibraryEntry:(const SparkLibraryEntry *)anEntry;
//
@end

SK_EXPORT
void SparkDumpEntries(SparkLibrary *aLibrary);


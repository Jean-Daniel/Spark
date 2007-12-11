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

@class SparkTrigger;
@interface SparkEntryManager (SparkEntryManagerInternal)

- (void)checkTriggerValidity:(SparkTrigger *)trigger;

#pragma mark Low-Level Methods
- (void)sp_addEntry:(SparkEntry *)anEntry;
- (void)sp_removeEntry:(SparkEntry *)anEntry;

//- (void)addLibraryEntry:(SparkLibraryEntry *)anEntry;
//- (void)removeLibraryEntry:(const SparkLibraryEntry *)anEntry;
//- (void)replaceLibraryEntry:(SparkLibraryEntry *)anEntry withLibraryEntry:(SparkLibraryEntry *)newEntry;

/* Convert Library entry */
//- (SparkLibraryEntry *)libraryEntryForEntry:(SparkEntry *)anEntry;
//- (SparkLibraryEntry *)libraryEntryForTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication;
//
//- (SparkEntry *)entryForLibraryEntry:(const SparkLibraryEntry *)anEntry;

@end

@interface SparkEntryManager (SparkLegacyLibraryImporter)
- (void)resolveParents;
  /* simple array of entries builded from an Spark 2 library. */
- (void)loadLegacyEntries:(NSArray *)entries;
  /* library version 2.0 */
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError;
  /* parent resolution helper */
- (SparkEntry *)entryForTrigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;

@end

SK_EXPORT
void SparkDumpEntries(SparkLibrary *aLibrary);


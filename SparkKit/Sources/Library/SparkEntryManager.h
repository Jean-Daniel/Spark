/*
 *  SparkEntryManager.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

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

- (BOOL)statusForEntry:(SparkEntry *)anEntry;
- (void)setStatus:(BOOL)status forEntry:(SparkEntry *)anEntry;

- (NSArray *)entriesForAction:(UInt32)anAction;
- (NSArray *)entriesForTrigger:(UInt32)aTrigger;
- (NSArray *)entriesForApplication:(UInt32)anApplication;

- (BOOL)containsEntryForTrigger:(UInt32)aTrigger application:(UInt32)anApplication;
- (SparkAction *)actionForTrigger:(UInt32)aTrigger application:(UInt32)anApplication;

/* Do not use */
- (void)addLibraryEntry:(SparkLibraryEntry *)anEntry;

@end

@interface SparkEntryManager (SparkSerialization)
- (NSFileWrapper *)fileWrapper:(NSError **)outError;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError;
@end


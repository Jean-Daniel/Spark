/*
 *  SparkEntryManagerPrivate.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkEntryManager.h>
#import <SparkKit/SparkEntry.h>
/* for kSparkApplicationSystemUID */
#import <SparkKit/SparkLibrary.h>

typedef struct _SparkLibraryEntry {
  SparkUID flags;
  SparkUID action;
  SparkUID trigger;
  SparkUID application;
} SparkLibraryEntry;

enum {
  /* Persistents flags */
  kSparkEntryEnabled = 1 << 0,
  /* Volatile flags */
  kSparkEntryUnplugged = 1 << 16,
  kSparkEntryPersistent = 1 << 17,
  kSparkPersistentFlagsMask = 0xffff,
};

SPARK_PRIVATE
void SparkLibraryEntryInitFlags(SparkLibraryEntry *lentry, SparkEntry *entry);

@interface SparkEntryManager (SparkEntryManagerInternal)

- (void)initInternal;
- (void)deallocInternal;

#pragma mark Low-Level Methods
- (void)addLibraryEntry:(SparkLibraryEntry *)anEntry;
- (void)removeLibraryEntry:(const SparkLibraryEntry *)anEntry;
- (void)replaceLibraryEntry:(SparkLibraryEntry *)anEntry withLibraryEntry:(SparkLibraryEntry *)newEntry;

- (void)setEnabled:(BOOL)flag forLibraryEntry:(SparkLibraryEntry *)anEntry;

/* Convert Library entry */
- (SparkLibraryEntry *)libraryEntryForEntry:(SparkEntry *)anEntry;
- (SparkLibraryEntry *)libraryEntryForTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication;

- (SparkEntry *)entryForLibraryEntry:(const SparkLibraryEntry *)anEntry;

/* Library Entry info */
- (SparkEntryType)typeForLibraryEntry:(const SparkLibraryEntry *)anEntry;

@end

@interface SparkEntry (SparkEntryManager)

- (void)setEnabled:(BOOL)flag;
- (void)setPlugged:(BOOL)flag;

@end

SK_INLINE
BOOL SparkLibraryEntryIsEnabled(const SparkLibraryEntry *entry) {
  return (entry->flags & kSparkEntryEnabled) != 0;
}

SK_INLINE
BOOL SparkLibraryEntryIsPlugged(const SparkLibraryEntry *entry) {
  return (entry->flags & kSparkEntryUnplugged) == 0;
}

SK_INLINE
BOOL SparkLibraryEntryIsPersistent(const SparkLibraryEntry *entry) {
  return (entry->flags & kSparkEntryPersistent) != 0;
}

SK_INLINE
BOOL SparkLibraryEntryIsActive(const SparkLibraryEntry *entry) {
  return SparkLibraryEntryIsEnabled(entry) && SparkLibraryEntryIsPlugged(entry);
}

SK_INLINE
BOOL SparkLibraryEntryIsOverwrite(const SparkLibraryEntry *entry) {
  return entry->application != kSparkApplicationSystemUID;
}

SK_EXPORT
void SparkDumpEntries(SparkLibrary *aLibrary);


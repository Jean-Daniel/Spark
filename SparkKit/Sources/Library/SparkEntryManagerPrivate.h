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

- (void)replaceAction:(SparkAction *)anAction inEntry:(SparkEntry *)anEntry;
- (void)replaceTrigger:(SparkTrigger *)aTrigger inEntry:(SparkEntry *)anEntry;
- (void)replaceApplication:(SparkApplication *)anApplication inEntry:(SparkEntry *)anEntry;

@end

@class SparkTrigger;
@interface SparkEntryManager (SparkEntryManagerInternal)

/* remove orphan trigger, and update trigger flags */
- (void)updateTriggerStatus:(SparkTrigger *)trigger;

/* called by SparkEntry */
- (void)addEntry:(SparkEntry *)anEntry parent:(SparkEntry *)parent;

- (void)updateEntry:(SparkEntry *)anEntry
          setAction:(SparkAction *)anAction
            trigger:(SparkTrigger *)aTrigger
        application:(SparkApplication *)anApplication;

#pragma mark Low-Level Methods
- (void)sp_addEntry:(SparkEntry *)anEntry parent:(SparkEntry *)aParent;
- (void)sp_removeEntry:(SparkEntry *)anEntry;

// MARK: Notification handling
- (void)didRemoveApplication:(NSNotification *)aNotification;
- (void)didChangePlugInStatus:(NSNotification *)aNotification;

@end

@interface SparkEntryManager (SparkArchiving) <NSCoding>
/* Library version 2.1 */
- (void)cleanup;
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

SPARK_EXPORT
void SparkDumpEntries(SparkLibrary *aLibrary);


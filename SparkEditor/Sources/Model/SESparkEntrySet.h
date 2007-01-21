/*
 *  SESparkEntrySet.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkEntry.h>

@class SparkAction, SparkTrigger;
@interface SESparkEntrySet : NSObject {
  @private
  NSMapTable *se_set;
  NSMutableArray *se_entries;
}

- (unsigned)count;

/* Get member */
- (SparkEntry *)entry:(SparkEntry *)anEntry;

- (void)removeAllEntries;

- (void)addEntry:(SparkEntry *)anEntry;
- (void)removeEntry:(SparkEntry *)anEntry;
- (void)replaceEntry:(SparkEntry *)anEntry withEntry:(SparkEntry *)newEntry;

- (void)addEntriesFromEntrySet:(SESparkEntrySet *)set;
- (void)addEntriesFromArray:(NSArray *)entries;

- (NSArray *)allObjects;
- (NSEnumerator *)entryEnumerator;

- (BOOL)containsTrigger:(SparkTrigger *)trigger;
- (SparkEntry *)entryForTrigger:(SparkTrigger *)aTrigger;
- (SparkAction *)actionForTrigger:(SparkTrigger *)trigger;

@end

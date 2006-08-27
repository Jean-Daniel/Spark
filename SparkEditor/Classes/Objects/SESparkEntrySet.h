/*
 *  SESparkEntrySet.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

SK_PRIVATE
NSArray *gSortByNameDescriptors;

#import <SparkKit/SparkEntry.h>

@interface SparkEntry (SEExtensions)
- (BOOL)overwrite;
@end

#pragma mark -
@class SparkAction, SparkTrigger;
@interface SESparkEntrySet : NSObject {
  @private
  NSMapTable *se_set;
  NSMutableArray *se_entries;
}

- (unsigned)count;

- (void)removeAllEntries;

- (void)addEntry:(SparkEntry *)entry;

- (void)addEntriesFromEntrySet:(SESparkEntrySet *)set;
- (void)addEntriesFromArray:(NSArray *)entries;

- (NSEnumerator *)entryEnumerator;

- (BOOL)containsTrigger:(SparkTrigger *)trigger;
- (SparkEntry *)entryForTrigger:(SparkTrigger *)aTrigger;
- (SparkAction *)actionForTrigger:(SparkTrigger *)trigger;

@end

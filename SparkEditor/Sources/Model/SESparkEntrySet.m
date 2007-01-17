/*
 *  SESparkEntrySet.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SESparkEntrySet.h"

#import <SparkKit/SparkApplication.h>

@implementation SparkEntry (SEExtensions)

- (BOOL)overwrite {
  return [[self application] uid] != 0; 
}

@end
@implementation SESparkEntrySet

- (id)init {
  if (self = [super init]) {
    se_entries = [[NSMutableArray alloc] init];
    se_set = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
  }
  return self;
}

- (void)dealloc {
  [se_entries release];
  NSFreeMapTable(se_set);
  [super dealloc];
}

#pragma mark -
- (unsigned)count {
  return [se_entries count];
}
- (void)removeAllEntries {
  NSResetMapTable(se_set);
  [se_entries removeAllObjects];
}

- (void)addEntry:(SparkEntry *)entry {
  /* Remove previous entry */
  SparkEntry *previous = NSMapGet(se_set, [entry trigger]);
  if (previous)
    [se_entries removeObjectIdenticalTo:previous];
  
  /* Insert */
  [se_entries addObject:entry];
  NSMapInsert(se_set, [entry trigger], entry);
}

- (void)removeEntry:(SparkEntry *)anEntry {
  SparkEntry *entry = NSMapGet(se_set, [anEntry trigger]);
  if (entry) {
    NSMapRemove(se_set, [entry trigger]);
    [se_entries removeObjectIdenticalTo:entry];
  }
}

- (SparkEntry *)entry:(SparkEntry *)anEntry {
  unsigned idx = [se_entries indexOfObject:anEntry];
  if (idx != NSNotFound)
    return [se_entries objectAtIndex:idx];
  return nil;
}

- (void)replaceEntry:(SparkEntry *)anEntry withEntry:(SparkEntry *)newEntry {
  unsigned idx = [se_entries indexOfObjectIdenticalTo:anEntry];
  NSAssert(idx != NSNotFound, @"Invalid entry parameter.");
  
  [se_entries replaceObjectAtIndex:idx withObject:newEntry];
  NSMapRemove(se_set, [anEntry trigger]);
  NSMapInsert(se_set, [newEntry trigger], newEntry);
}

- (void)addEntriesFromEntrySet:(SESparkEntrySet *)set {
  SparkEntry *entry = nil;
  NSEnumerator *entries = [set entryEnumerator];
  while (entry = [entries nextObject]) {
    [self addEntry:entry];
  }
}
- (void)addEntriesFromArray:(NSArray *)anArray {
  SparkEntry *entry;
  NSEnumerator *entries = [anArray objectEnumerator];
  while (entry = [entries nextObject]) {
    [self addEntry:entry];
  }
}

- (NSArray *)allObjects {
  return se_entries;
}
- (NSEnumerator *)entryEnumerator {
  return [se_entries objectEnumerator];
}

- (BOOL)containsTrigger:(SparkTrigger *)trigger {
  return NSMapGet(se_set, trigger) != nil;
}

- (SparkEntry *)entryForTrigger:(SparkTrigger *)aTrigger {
  unsigned idx = [se_entries count];
  while (idx-- > 0) {
    SparkEntry *entry = [se_entries objectAtIndex:idx];
    if ([entry trigger] == aTrigger)
      return entry;
  }
  return nil;
}

- (SparkAction *)actionForTrigger:(SparkTrigger *)trigger {
  return [(SparkEntry *)NSMapGet(se_set, trigger) action];
}

@end

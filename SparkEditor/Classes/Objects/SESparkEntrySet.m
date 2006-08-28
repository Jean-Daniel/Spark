/*
 *  SESparkEntrySet.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SESparkEntrySet.h"

#import <SparkKit/SparkPrivate.h>

/*
 - Globals.			# a t a s => Global
 - Inherits Full	# a t @ @ => Inherits
 - Inherits Action.	# a t @ s => Weak Overwrite
 - Overwrite.		# a t a s => Overwrite
 */
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

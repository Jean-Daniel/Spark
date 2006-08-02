/*
 *  SETriggerEntry.m
 *  Spark Editor
 *
 *  Created by Grayfox on 09/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "SETriggerEntry.h"

@implementation SETriggerEntry

+ (id)entryWithTrigger:(SparkTrigger *)aTrigger action:(SparkAction *)anAction {
  return [[[self alloc] initWithTrigger:aTrigger action:anAction] autorelease];
}

- (id)initWithTrigger:(SparkTrigger *)aTrigger action:(SparkAction *)anAction {
  if (self = [super init]) {
    [self setAction:anAction];
    [self setTrigger:aTrigger];
  }
  return self;
}

- (void)dealloc {
  [se_action release];
  [se_trigger release];
  [super dealloc];
}

- (SparkAction *)action {
  return se_action;
}
- (void)setAction:(SparkAction *)action {
  SKSetterRetain(se_action, action);
}

- (SparkTrigger *)trigger {
  return se_trigger;
}
- (void)setTrigger:(SparkTrigger *)trigger {
  SKSetterRetain(se_trigger, trigger);
}

- (BOOL)isEnabled {
  return [se_trigger isEnabled];
}
- (NSImage *)icon {
  return [se_action icon];
}
- (NSString *)name {
  return [se_action name];
}
- (NSString *)categorie {
  return [se_action categorie];
}
- (NSString *)shortDescription {
  return [se_action shortDescription];
}
- (NSString *)triggerDescription {
  return [se_trigger triggerDescription];
}
@end

@implementation SETriggerEntrySet

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

- (void)removeAllEntries {
  NSResetMapTable(se_set);
  [se_entries removeAllObjects];
}

- (void)addEntry:(SETriggerEntry *)entry {
  /* Remove previous entry */
  SETriggerEntry *previous = NSMapGet(se_set, [entry trigger]);
  if (previous)
    [se_entries removeObjectIdenticalTo:previous];
  
  /* Insert */
  [se_entries addObject:entry];
  NSMapInsert(se_set, [entry trigger], entry);
}
- (void)addEntriesFromEntrySet:(SETriggerEntrySet *)set {
  SETriggerEntry *entry = nil;
  NSEnumerator *entries = [set entryEnumerator];
  while (entry = [entries nextObject]) {
    SETriggerEntry *copy = [[SETriggerEntry alloc] initWithTrigger:[entry trigger] action:[entry action]];
    [self addEntry:copy];
    [copy release];
  }
}
- (void)addEntriesFromDictionary:(NSDictionary *)aDictionary {
  SparkTrigger *key = nil;
  NSEnumerator *keys = [aDictionary keyEnumerator];
  while (key = [keys nextObject]) {
    SETriggerEntry *entry = [[SETriggerEntry alloc] initWithTrigger:key action:[aDictionary objectForKey:key]];
    [self addEntry:entry];
    [entry release];
  }
}

- (NSEnumerator *)entryEnumerator {
  return [se_entries objectEnumerator];
}

- (SETriggerEntry *)entryAtIndex:(unsigned)idx {
  return [se_entries objectAtIndex:idx];
}

- (BOOL)containsTrigger:(SparkTrigger *)trigger {
  return NSMapGet(se_set, trigger) != nil;
}
- (SparkAction *)actionForTrigger:(SparkTrigger *)trigger {
  return [(SETriggerEntry *)NSMapGet(se_set, trigger) action];
}

@end

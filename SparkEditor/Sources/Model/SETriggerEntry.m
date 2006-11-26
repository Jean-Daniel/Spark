/*
 *  SETriggerEntry.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SETriggerEntry.h"

#import <SparkKit/SparkPrivate.h>

@implementation SETriggerEntry

- (id)copyWithZone:(NSZone *)aZone {
  SETriggerEntry *copy = (SETriggerEntry *)NSCopyObject(self, 0, aZone);
  [copy->se_action retain];
  [copy->se_trigger retain];
  return copy;
}

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

- (NSString *)description {
  return [NSString stringWithFormat:@"{ Trigger: %@, Action: %@ }", se_trigger, se_action];
}

#pragma mark -
- (int)type {
  return se_type;
}
- (void)setType:(int)type {
  se_type = type;
}

- (SparkAction *)action {
  return se_action;
}
- (void)setAction:(SparkAction *)action {
  SKSetterRetain(se_action, action);
}

- (id)trigger {
  return se_trigger;
}
- (void)setTrigger:(SparkTrigger *)trigger {
  SKSetterRetain(se_trigger, trigger);
}

- (BOOL)isEnabled {
  return [se_action isEnabled];
}
- (void)setEnabled:(BOOL)enabled {
  [se_action setEnabled:enabled];
}

- (NSImage *)icon {
  return [se_action icon];
}
- (NSString *)name {
  return [se_action name];
}
- (void)setName:(NSString *)aName {
  [se_action setName:aName];
}

- (NSString *)categorie {
  return [se_action categorie];
}
- (NSString *)actionDescription {
  return [se_action actionDescription];
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
    SETriggerEntry *copy = [entry copy];
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

- (SETriggerEntry *)entryForTrigger:(SparkTrigger *)aTrigger {
  unsigned idx = [se_entries count];
  while (idx-- > 0) {
    SETriggerEntry *entry = [se_entries objectAtIndex:idx];
    if ([entry trigger] == aTrigger)
      return entry;
  }
  return nil;
}

- (BOOL)containsTrigger:(SparkTrigger *)trigger {
  return NSMapGet(se_set, trigger) != nil;
}
- (SparkAction *)actionForTrigger:(SparkTrigger *)trigger {
  return [(SETriggerEntry *)NSMapGet(se_set, trigger) action];
}

@end

/*
 *  SEEntryList.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEEntryList.h"
#import "SEEntryCache.h"
#import "SESparkEntrySet.h"
#import "SELibraryDocument.h"

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkEntryManager.h>

NSString * const SEEntryListDidChangeNameNotification = @"SEEntryListDidChangeName";

@implementation SEEntryList

- (id)initWithName:(NSString *)name icon:(NSImage *)icon {
  if (self = [super init]) {
    [self setName:name];
    [self setIcon:icon];
  }
  return self;
}

- (void)dealloc {
  [se_icon release];
  [se_name release];
  [se_entries release];
  /* unregister notifications */
  [[se_library notificationCenter] removeObserver:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [se_library release];
  [super dealloc];
}

#pragma mark -
- (NSImage *)icon {
  return se_icon;
}
- (void)setIcon:(NSImage *)icon {
  [self willChangeValueForKey:@"representation"];
  SKSetterRetain(se_icon, icon);
  [self didChangeValueForKey:@"representation"];
}

- (NSString *)name {
  return se_name;
}
- (void)setName:(NSString *)name {
  [self willChangeValueForKey:@"representation"];
  SKSetterCopy(se_name, name);
  [self didChangeValueForKey:@"representation"];
}

- (UInt8)group {
  return se_elFlags.group;
}
- (void)setGroup:(UInt8)group {
  se_elFlags.group = group;
}

- (SELibraryDocument *)document {
  return se_document;
}
- (void)setDocument:(SELibraryDocument *)aDocument {
  if (se_document) {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SEApplicationDidChangeNotification
                                                  object:se_document];
    
    [[[se_document library] notificationCenter] removeObserver:self];
    [se_library release];
    se_library = nil;
  }
  se_document = aDocument;
  if (se_document) {
    se_library = [[aDocument library] retain];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidChange:)
                                                 name:SEApplicationDidChangeNotification
                                               object:se_document];
    [[se_library notificationCenter] addObserver:self
                                        selector:@selector(didAddEntry:)
                                            name:SEEntryCacheDidAddEntryNotification
                                          object:[se_document cache]];
    [[se_library notificationCenter] addObserver:self
                                        selector:@selector(didUpdateEntry:)
                                            name:SEEntryCacheDidUpdateEntryNotification
                                          object:[se_document cache]];
    [[se_library notificationCenter] addObserver:self
                                        selector:@selector(willRemoveEntry:)
                                            name:SEEntryCacheWillRemoveEntryNotification
                                          object:[se_document cache]];
  }
  [self reload];
}

- (BOOL)isEditable {
  return NO;
}

- (void)addEntries:(NSArray *)entries {
  SKClusterException();
}
- (void)removeEntries:(NSArray *)entries {
  SKClusterException();
}

- (id)representation {
  return self;
}
- (void)setRepresentation:(NSString *)representation {
  [self setName:representation];
}

- (NSComparisonResult)compare:(id)object {
  UInt8 g1 = [self group], g2 = [object group];
  if (g1 != g2)
    return g1 - g2;
  else return [[self name] caseInsensitiveCompare:[object name]];
}

- (void)reload {
  // Too subclass
}

- (void)removeAllObjects {
  if ([se_entries count]) {
    [self willChangeValueForKey:@"entries"];
    [se_entries removeAllObjects];
    [self didChangeValueForKey:@"entries"];
  }
}

#pragma mark -
- (NSArray *)entries {
  return se_entries;
}

- (NSUInteger)countOfEntries {
  return [se_entries count];
}

- (void)setEntries:(NSArray *)entries {
  SKSetterMutableCopy(se_entries, entries);
}

- (SparkEntry *)objectInEntriesAtIndex:(NSUInteger)idx {
  return [se_entries objectAtIndex:idx];
}

- (void)getEntries:(id *)aBuffer range:(NSRange)range {
  [se_entries getObjects:aBuffer range:range];
}

- (void)insertObject:(SparkEntry *)anEntry inEntriesAtIndex:(NSUInteger)idx {
  [se_entries insertObject:anEntry atIndex:idx];
}
- (void)removeObjectFromEntriesAtIndex:(NSUInteger)idx {
  [se_entries removeObjectAtIndex:idx];
}
- (void)replaceObjectInEntriesAtIndex:(NSUInteger)idx withObject:(SparkEntry *)object {
  [se_entries replaceObjectAtIndex:idx withObject:object];
}

#pragma mark Notifications
- (void)applicationDidChange:(NSNotification *)aNotification {
  SparkApplication *previous = [[aNotification userInfo] objectForKey:SEPreviousApplicationKey];
  
  if (!previous) {
    [self reload];
  } else {
    SparkApplication *application = [[aNotification object] application];
    /* Reload when switching to/from global */
    if ([application uid] == 0 || [previous uid] == 0) {
      [self reload];
    } else {
      /* Reload if previous or current contains custom entries */
      SparkEntryManager *manager = [[[aNotification object] library] entryManager];
      if ([manager containsEntryForApplication:[previous uid]] || 
          [manager containsEntryForApplication:[application uid]])
        [self reload];
    }
  }
}

- (BOOL)acceptsEntry:(SparkEntry *)anEntry {
  SKClusterException();
  return NO;
}

- (void)didAddEntry:(NSNotification *)aNotification {
  SparkEntry *entry = SparkNotificationObject(aNotification);
  // If se_list contains trigger for entry, add entry.
  if ([self acceptsEntry:entry]) {
    [self insertObject:entry inEntriesAtIndex:[[self entries] count]];
  }
}

- (void)didUpdateEntry:(NSNotification *)aNotification {
  SparkEntry *entry = SparkNotificationObject(aNotification);
  SparkEntry *updated = SparkNotificationUpdatedObject(aNotification);
  if ([self acceptsEntry:entry]) {
    /* First, get index of the previous entry */
    NSUInteger idx = [[self entries] indexOfObject:updated];
    if (idx != NSNotFound) {
      // if contains updated->trigger, replace updated.
      [self replaceObjectInEntriesAtIndex:idx withObject:entry];
    } else {
      // if does not contains updated->trigger, add entry
      [self insertObject:entry inEntriesAtIndex:[[self entries] count]];
    }
  } else {
    // se_list does not contain the new entry->trigger, so if se_entries contains updated, remove updated
    NSUInteger idx = [[self entries] indexOfObject:updated];
    if (idx != NSNotFound) {
      [self removeObjectFromEntriesAtIndex:idx];
    }
  }
}

- (void)willRemoveEntry:(NSNotification *)aNotification {
  NSUInteger idx = [se_entries indexOfObject:SparkNotificationObject(aNotification)];
  if (idx != NSNotFound) {
    [self removeObjectFromEntriesAtIndex:idx];
  }
}

@end

#pragma mark -
#pragma mark User Lists
@implementation SEUserEntryList

- (id)initWithList:(SparkList *)aList {
  NSParameterAssert(aList);
  if (self = [super init]) {
    se_list = [aList retain];
    [super setIcon:[aList icon]];
    [super setName:[aList name]];
    [se_list addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionOld context:nil];
    
    NSNotificationCenter *center = [[se_list library] notificationCenter];
    [center addObserver:self
               selector:@selector(didAddTrigger:)
                   name:SparkListDidAddObjectNotification
                 object:se_list];
    [center addObserver:self
               selector:@selector(didAddTriggers:)
                   name:SparkListDidAddObjectsNotification
                 object:se_list];
    
    [center addObserver:self
               selector:@selector(didUpdateTrigger:)
                   name:SparkListDidUpdateObjectNotification
                 object:se_list];
    
    [center addObserver:self
               selector:@selector(didRemoveTrigger:)
                   name:SparkListDidRemoveObjectNotification
                 object:se_list];
    [center addObserver:self
               selector:@selector(didRemoveTriggers:)
                   name:SparkListDidRemoveObjectsNotification
                 object:se_list];
  }
  return self;
}

- (void)dealloc {
  [se_list removeObserver:self forKeyPath:@"name"];
  [[[se_list library] notificationCenter] removeObserver:self];
  [se_list release];
  [super dealloc];
}

#pragma mark -
- (void)reload {
  NSMutableArray *entries = [[NSMutableArray alloc] init];
  if ([self document]) {
    SparkTrigger *trigger = nil;
    NSEnumerator *triggers = [se_list objectEnumerator];
    SESparkEntrySet *cache = [[[self document] cache] entries];
    while (trigger = [triggers nextObject]) {
      SparkEntry *entry = [cache entryForTrigger:trigger];
      if (entry)
        [entries addObject:entry];
    }
  }
  [self setEntries:entries];
  [entries release];
}

- (BOOL)isEditable {
  return YES;
}

- (void)addEntries:(NSArray *)entries {
  NSUInteger count = [entries count];
  while (count-- > 0) {
    SparkEntry *entry = [entries objectAtIndex:count];
    SparkTrigger *trigger = [entry trigger];
    if (![se_list containsObject:trigger]) {
      [se_list addObject:trigger];
    }
  }
}
- (void)removeEntries:(NSArray *)entries {
  NSUInteger count = [entries count];
  while (count-- > 0) {
    SparkEntry *entry = [entries objectAtIndex:count];
    NSUInteger idx = [[self entries] indexOfObjectIdenticalTo:entry];
    NSAssert1(idx != NSNotFound, @"Must contains entry %@", entry);
    
    SparkTrigger *trigger = [entry trigger];
    NSAssert2([se_list containsObject:trigger], @"%@ Must contains %@", se_list, trigger);
    
    [se_list removeObject:trigger];
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([@"name" isEqualToString:keyPath] && object == se_list) {
    [[[self document] undoManager] registerUndoWithTarget:se_list
                                                 selector:@selector(setName:)
                                                   object:[change objectForKey:NSKeyValueChangeOldKey]];
    [super setName:[object name]];
  }
}

- (void)setName:(NSString *)aName {
  [se_list setName:aName];
}

- (SparkList *)list {
  return se_list;
}

- (BOOL)acceptsEntry:(SparkEntry *)anEntry {
  return [se_list containsObject:[anEntry trigger]];
}

#pragma mark Notifications
- (NSUInteger)indexOfEntryForTrigger:(SparkTrigger *)trigger {
  NSUInteger count = [[self entries] count];
  while (count-- > 0) {
    SparkEntry *entry = [[self entries] objectAtIndex:count];
    if ([[entry trigger] isEqual:trigger])
      return count;
  }
  return NSNotFound;
}

- (void)didAddTrigger:(NSNotification *)aNotification {
  SparkEntry *entry = [[[[self document] cache] entries] entryForTrigger:SparkNotificationObject(aNotification)];
  if (entry) {
    [self insertObject:entry inEntriesAtIndex:[[self entries] count]];
  }
}
- (void)didAddTriggers:(NSNotification *)aNotification {
  SESparkEntrySet *cache = [[[self document] cache] entries];
  NSArray *entries = SparkNotificationObject(aNotification);
  NSUInteger count = [entries count];
  while (count-- > 0) {
    SparkEntry *entry = [cache entryForTrigger:[entries objectAtIndex:count]];
    if (entry) {
      [self insertObject:entry inEntriesAtIndex:[[self entries] count]];
    }
  }
}

- (void)didUpdateTrigger:(NSNotification *)aNotification {
  ShadowTrace();
  // Should never append.
}

- (void)didRemoveTrigger:(NSNotification *)aNotification {
  NSUInteger idx = [self indexOfEntryForTrigger:SparkNotificationObject(aNotification)];
  if (idx != NSNotFound) {
    [self removeObjectFromEntriesAtIndex:idx];
  }
}
- (void)didRemoveTriggers:(NSNotification *)aNotification {
  NSArray *entries = SparkNotificationObject(aNotification);
  NSUInteger count = [entries count];
  while (count-- > 0) {
    NSUInteger idx = [self indexOfEntryForTrigger:[entries objectAtIndex:count]];
    if (idx != NSNotFound) {
      [self removeObjectFromEntriesAtIndex:idx];
    }
  }
}

@end

#pragma mark -
#pragma mark Smart Lists
@implementation SESmartEntryList
  
- (void)dealloc {
  [se_ctxt release];
  [super dealloc];
}

#pragma mark -
- (void)reload {
  NSMutableArray *entries = [[NSMutableArray alloc] init];
  if (se_filter && [self document]) {
    SparkTrigger *trigger = nil;
    SESparkEntrySet *cache = [[[self document] cache] entries];
    NSEnumerator *triggers = [[[[self document] library] triggerSet] objectEnumerator];
    while (trigger = [triggers nextObject]) {
      SparkEntry *entry = [cache entryForTrigger:trigger];
      if (entry && se_filter(self, entry, se_ctxt))
        [entries addObject:entry];
    }
  }
  [self setEntries:entries];
  [entries release];
}

- (void)setListFilter:(SEEntryListFilter)aFilter context:(id)aCtxt {
  se_filter = aFilter;
  SKSetterRetain(se_ctxt, aCtxt);
  [self reload];
}

- (BOOL)acceptsEntry:(SparkEntry *)anEntry {
  return se_filter && se_filter(self, anEntry, se_ctxt);
}

@end


/*
 *  SparkList.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkEntryManager.h>

#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKAppKitExtensions.h>

/* Reload when filter change */
NSString * const SparkListDidReloadNotification = @"SparkListDidReload";

NSString * const SparkListDidAddObjectNotification = @"SparkListDidAddObject";
NSString * const SparkListDidAddObjectsNotification = @"SparkListDidAddObjects";

NSString * const SparkListDidUpdateObjectNotification = @"SparkListDidUpdateObject";

NSString * const SparkListDidRemoveObjectNotification = @"SparkListDidRemoveObject";
NSString * const SparkListDidRemoveObjectsNotification = @"SparkListDidRemoveObjects";

static 
NSString * const kSparkObjectsKey = @"SparkObjects";

@implementation SparkList

- (id)initWithName:(NSString *)name icon:(NSImage *)icon {
  if (self = [super initWithName:name icon:icon]) {
    sp_entries = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  [self setLibrary:nil];
  [sp_entries release];
  [sp_ctxt release];
  [super dealloc];
}

#pragma mark -
- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    NSAssert([self library], @"invalid unarchiver");
    [self setGroup:SKDecodeInteger(coder, @"group")];
    [self setEditable:[coder decodeBoolForKey:@"editable"]];
    sp_entries = [[coder decodeObjectForKey:@"entries"] retain];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  SKEncodeInteger(coder, [self group], @"group");
  [coder encodeObject:sp_entries forKey:@"entries"];
  [coder encodeBool:[self isEditable] forKey:@"editable"];
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  return NO;
}

- (id)initWithSerializedValues:(NSDictionary *)plist  {
  return nil;
}

#pragma mark -
- (NSImage *)icon {
  NSImage *icon = [super icon];
  if (!icon) {
    icon = [NSImage imageNamed:@"SimpleList" inBundle:kSparkKitBundle];
    [self setIcon:icon];
  }
  return icon;
}

- (BOOL)shouldSaveIcon {
  return NO;
}

- (void)reload {
  if ([self isDynamic]) {
    [self willChangeValueForKey:@"entries"];
    /* Refresh objects */
    [sp_entries removeAllObjects];
    if (sp_filter) {
      SparkEntry *entry;
      NSEnumerator *entries = [[self library] entryEnumerator];
      while (entry = [entries nextObject]) {
        if ([self acceptsEntry:entry]) {
          [sp_entries addObject:entry];
        }
      }
    }
    [self didChangeValueForKey:@"entries"];
    SparkLibraryPostNotification([self library], SparkListDidReloadNotification, self, nil);
  }
}

- (BOOL)isDynamic {
  return sp_filter != NULL;
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  if (aLibrary != [self library]) {
    if ([self library]) {
      [[[self library] notificationCenter] removeObserver:self
                                                     name:SparkEntryManagerDidAddEntryNotification
                                                   object:nil];
      [[[self library] notificationCenter] removeObserver:self
                                                     name:SparkEntryManagerDidUpdateEntryNotification
                                                   object:nil];
      [[[self library] notificationCenter] removeObserver:self
                                                     name:SparkEntryManagerWillRemoveEntryNotification
                                                   object:nil];
    }
    [super setLibrary:aLibrary];
    if ([self library]) {
      /* Add */
      [[[self library] notificationCenter] addObserver:self
                                              selector:@selector(didAddEntry:)
                                                  name:SparkEntryManagerDidAddEntryNotification
                                                object:nil];
      /* Update */
      [[[self library] notificationCenter] addObserver:self
                                              selector:@selector(didUpdateEntry:)
                                                  name:SparkEntryManagerWillRemoveEntryNotification
                                                object:nil];
      /* Remove */
      [[[self library] notificationCenter] addObserver:self
                                              selector:@selector(willRemoveEntry:)
                                                  name:SparkEntryManagerDidUpdateEntryNotification
                                                object:nil];
    }
  }
}

- (id)filterContext {
  return sp_ctxt;
}
- (void)setListFilter:(SparkListFilter)aFilter context:(id)aCtxt {
  sp_filter = aFilter;
  SKSetterRetain(sp_ctxt, aCtxt);
  /* Refresh contents */
  [self reload];
}
- (void)reloadWithFilter:(SparkListFilter)aFilter context:(id)aCtxt {
  sp_filter = aFilter;
  SKSetterRetain(sp_ctxt, aCtxt);
  /* Refresh contents */
  [self reload];
  /* Remove dynamic */
  sp_filter = NULL;
  SKSetterRetain(sp_ctxt, nil);
}

#pragma mark -
#pragma mark Array
- (NSUInteger)count {
  return [sp_entries count];
}
- (BOOL)containsObject:(SparkObject *)anObject {
  return [sp_entries containsObject:anObject];
}
- (NSEnumerator *)objectEnumerator {
  return [sp_entries objectEnumerator];
}

- (NSArray *)entriesForApplication:(SparkApplication *)anApplication {
  return nil;
}

#pragma mark Modification
- (NSUndoManager *)undoManager {
  return [[self library] undoManager];
}

- (void)addEntry:(SparkEntry *)anEntry {
  [self insertObject:anEntry inEntriesAtIndex:[sp_entries count]];
}
- (void)addEntriesFromArray:(NSArray *)anArray {
}

- (void)removeEntry:(SparkEntry *)anEntry {
  NSUInteger idx = [sp_entries indexOfObject:anEntry];
  if (idx != NSNotFound) {
    [self removeObjectFromEntriesAtIndex:idx];
  }
}
- (void)removeEntriesInArray:(NSArray *)anArray {
}

//- (void)addObjectsFromArray:(NSArray *)anArray {
//  /* Undo Manager */
//  if (![self isDynamic])
//    [[self undoManager] registerUndoWithTarget:self selector:@selector(removeObjectsInArray:) object:anArray];
//  [sp_entries addObjectsFromArray:anArray];
//  SparkLibraryPostNotification([self library], SparkListDidAddObjectsNotification, self, anArray);
//}
//
//- (void)removeObjectsInArray:(NSArray *)anArray {
//  NSUInteger count = [anArray count];
//  NSMutableArray *removed = [[NSMutableArray alloc] init];
//  while (count-- > 0) {
//    NSUInteger idx = [sp_entries indexOfObject:[anArray objectAtIndex:count]];
//    if (NSNotFound != idx) {
//      [removed addObject:[sp_entries objectAtIndex:idx]];
//      [sp_entries removeObjectAtIndex:idx];
//    }
//  }
//  if ([removed count]) {
//    /* Undo Manager */
//    if (![self isDynamic])
//      [[self undoManager] registerUndoWithTarget:self selector:@selector(addObjectsFromArray:) object:removed];    
//    SparkLibraryPostNotification([self library], SparkListDidRemoveObjectsNotification, self, removed);
//  }
//  [removed release];    
//}

#pragma mark -
#pragma mark Notifications
- (BOOL)acceptsEntry:(SparkEntry *)anEntry {
  return sp_filter && sp_filter(self, anEntry, sp_ctxt);
}

- (void)didAddEntry:(NSNotification *)aNotification {
  SparkEntry *entry = SparkNotificationObject(aNotification);
  NSAssert1(entry, @"invalid notification: %@", aNotification);
  if ([self acceptsEntry:entry]) {
    [self addEntry:entry];
  }
}
- (void)didUpdateEntry:(NSNotification *)aNotification {
//  NSUInteger idx = 0;
//  SparkObject *object = SparkNotificationObject(aNotification);
//  SparkObject *previous = SparkNotificationUpdatedObject(aNotification);
//  /* If contains old value */
//  if (previous && (idx = [sp_entries indexOfObject:previous]) != NSNotFound) {
//    /* If is not smart, or updated object is always valid, replace old value */
//    if (!sp_filter || sp_filter(self, object, sp_ctxt)) {
//      [sp_entries replaceObjectAtIndex:idx withObject:object];
//      SparkLibraryPostUpdateNotification([self library], SparkListDidUpdateObjectNotification, self, previous, object);
//    } else {
//      /* remove old value */
//      [self removeObject:object];
//    }
//  } else {
//    /* Do not contains previous value but updated object is valid */
//    if (sp_filter && sp_filter(self, object, sp_ctxt)) {
//      [self addObject:object];
//    }
//  }
}

- (void)willRemoveEntry:(NSNotification *)aNotification {
  SparkEntry *entry = SparkNotificationObject(aNotification);
  NSAssert1(entry, @"invalid notification: %@", aNotification);
  if (entry)
    [self removeEntry:entry];
}

#pragma mark KVC
- (NSArray *)entries {
  return sp_entries;
}

- (NSUInteger)countOfEntries {
  return [sp_entries count];
}

- (void)setEntries:(NSArray *)entries {
  SKSetterMutableCopy(sp_entries, entries);
}

- (SparkEntry *)objectInEntriesAtIndex:(NSUInteger)idx {
  return [sp_entries objectAtIndex:idx];
}

- (void)getEntries:(id *)aBuffer range:(NSRange)range {
  [sp_entries getObjects:aBuffer range:range];
}

- (void)insertObject:(SparkEntry *)anEntry inEntriesAtIndex:(NSUInteger)idx {
  /* try to insert a non root entry */
  if ([anEntry parent]) {
    if ([sp_entries containsObjectIdenticalTo:[anEntry parent]])
      return;
    /* insert parent instead */
    anEntry = [anEntry parent];
  }
  if (![self isDynamic])
    [[[self undoManager] prepareWithInvocationTarget:self] removeObjectFromEntriesAtIndex:idx];
  [sp_entries insertObject:anEntry atIndex:idx];
  SparkLibraryPostNotification([self library], SparkListDidAddObjectNotification, self, anEntry);
}
- (void)removeObjectFromEntriesAtIndex:(NSUInteger)idx {
  SparkEntry *entry = [[sp_entries objectAtIndex:idx] retain];
  /* Undo Manager */
  if (![self isDynamic])
    [[[self undoManager] prepareWithInvocationTarget:self] insertObject:entry inEntriesAtIndex:idx];
  [sp_entries removeObjectAtIndex:idx];
  SparkLibraryPostNotification([self library], SparkListDidRemoveObjectNotification, self, entry);
  [entry release];
}
- (void)replaceObjectInEntriesAtIndex:(NSUInteger)idx withObject:(SparkEntry *)object {
  //[sp_entries replaceObjectAtIndex:idx withObject:object];
}

#pragma mark Spark Editor
- (UInt8)group {
  return sp_selFlags.group;
}
- (void)setGroup:(UInt8)group {
  sp_selFlags.group = group;
}

- (BOOL)isEditable {
  return sp_selFlags.editable;
}
- (void)setEditable:(BOOL)flag {
  SKFlagSet(sp_selFlags.editable, flag);
}

- (NSComparisonResult)compare:(id)object {
  UInt8 g1 = [self group], g2 = [object group];
  if (g1 != g2)
    return g1 - g2;
  else return [[self name] caseInsensitiveCompare:[object name]];
}

@end

//- (void)didUpdateEntry:(NSNotification *)aNotification {
//  SparkEntry *entry = SparkNotificationObject(aNotification);
//  SparkEntry *updated = SparkNotificationUpdatedObject(aNotification);
//  if ([self acceptsEntry:entry]) {
//    /* First, get index of the previous entry */
//    NSUInteger idx = [[self entries] indexOfObject:updated];
//    if (idx != NSNotFound) {
//      // if contains updated->trigger, replace updated.
//      [self replaceObjectInEntriesAtIndex:idx withObject:entry];
//    } else {
//      // if does not contains updated->trigger, add entry
//      [self insertObject:entry inEntriesAtIndex:[[self entries] count]];
//    }
//  } else {
//    // se_list does not contain the new entry->trigger, so if se_entries contains updated, remove updated
//    NSUInteger idx = [[self entries] indexOfObject:updated];
//    if (idx != NSNotFound) {
//      [self removeObjectFromEntriesAtIndex:idx];
//    }
//  }
//}

//@end


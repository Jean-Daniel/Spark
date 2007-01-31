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
  [[NSNotificationCenter defaultCenter] removeObserver:self];
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
  }
  se_document = aDocument;
  if (se_document) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidChange:)
                                                 name:SEApplicationDidChangeNotification
                                               object:se_document];
  }
  [self reload];
}

- (BOOL)isEditable {
  return NO;
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

- (unsigned)countOfEntries {
  return [se_entries count];
}

- (void)setEntries:(NSArray *)entries {
  SKSetterCopy(se_entries, entries);
}

- (SparkEntry *)objectInEntriesAtIndex:(unsigned)idx {
  return [se_entries objectAtIndex:idx];
}

- (void)getEntries:(id *)aBuffer range:(NSRange)range {
  [se_entries getObjects:aBuffer range:range];
}

- (void)insertObject:(SparkEntry *)anEntry inEntriesAtIndex:(unsigned)idx {
  [se_entries insertObject:anEntry atIndex:idx];
}
- (void)removeObjectFromEntriesAtIndex:(unsigned)idx {
  [se_entries removeObjectAtIndex:idx];
}
- (void)replaceObjectInEntriesAtIndex:(unsigned)idx withObject:(SparkEntry *)object {
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

//- (void)registerNotifications {
//  SparkLibrary *library = [self library];
//  [[library notificationCenter] addObserver:self
//                                   selector:@selector(didAddEntry:)
//                                       name:SEEntryCacheDidAddEntryNotification
//                                     object:nil];
//  [[library notificationCenter] addObserver:self
//                                   selector:@selector(didUpdateEntry:)
//                                       name:SEEntryCacheDidUpdateEntryNotification
//                                     object:nil];
//  [[library notificationCenter] addObserver:self
//                                   selector:@selector(didRemoveEntry:)
//                                       name:SEEntryCacheDidRemoveEntryNotification
//                                     object:nil];
//}

//- (void)didAddEntry:(NSNotification *)aNotification {
//  ShadowTrace();
//}
//
//- (void)didUpdateEntry:(NSNotification *)aNotification {
//  ShadowTrace();
//}
//
//- (void)didRemoveEntry:(NSNotification *)aNotification {
//  ShadowTrace();
//}

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
  }
  return self;
}

- (void)dealloc {
  [se_list removeObserver:self forKeyPath:@"name"];
  [se_list release];
  [super dealloc];
}

#pragma mark -
- (void)reload {
  NSMutableArray *entries = [[NSMutableArray alloc] init];
  if ([self document]) {
    SparkTrigger *trigger = nil;
    SESparkEntrySet *cache = [[[self document] cache] entries];
    NSEnumerator *triggers = [[[[self document] library] triggerSet] objectEnumerator];
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

@end


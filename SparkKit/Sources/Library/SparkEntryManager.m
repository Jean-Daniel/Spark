/*
 *  SparkEntryManager.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Sparkkit/SparkEntryManager.h>
#import "SparkEntryManagerPrivate.h"

#import <ShadowKit/SKCFContext.h>
#import <ShadowKit/SKEnumerator.h>

#import <SparkKit/SparkPrivate.h>

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkObjectSet.h>

/* Plugin status */
#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkActionLoader.h>

NSString * const SparkEntryManagerWillAddEntryNotification = @"SparkEntryManagerWillAddEntry";
NSString * const SparkEntryManagerDidAddEntryNotification = @"SparkEntryManagerDidAddEntry";

NSString * const SparkEntryManagerWillUpdateEntryNotification = @"SparkEntryManagerWillUpdateEntry";
NSString * const SparkEntryManagerDidUpdateEntryNotification = @"SparkEntryManagerDidUpdateEntry";

NSString * const SparkEntryManagerWillRemoveEntryNotification = @"SparkEntryManagerWillRemoveEntry";
NSString * const SparkEntryManagerDidRemoveEntryNotification = @"SparkEntryManagerDidRemoveEntry";

NSString * const SparkEntryManagerDidChangeEntryStatusNotification = @"SparkEntryManagerDidChangeEntryStatus";

@implementation SparkEntryManager

- (id)init {
  if (self = [self initWithLibrary:nil]) {
    
  }
  return self;
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary {
  NSParameterAssert(aLibrary);
  if (self = [super init]) {
    sp_library = aLibrary;
    sp_objects = NSCreateMapTable(NSIntegerMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePluginStatus:) 
                                                 name:SparkPlugInDidChangeStatusNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  NSFreeMapTable(sp_objects);
  [super dealloc];
}

- (SparkLibrary *)library {
  return sp_library;
}
- (void)setLibrary:(SparkLibrary *)library {
  sp_library = library;
}

- (NSUndoManager *)undoManager {
  return [[self library] undoManager];
}

#pragma mark -
#pragma mark Query
- (NSEnumerator *)entryEnumerator {
  return SKMapTableEnumerator(sp_objects, NO);
}

- (SparkEntry *)entryWithUID:(SparkUID)uid {
  return NSMapGet(sp_objects, (const void *)(intptr_t)uid);
}

typedef SparkUID (*SparkEntryAccessor)(SparkEntry *, SEL);
- (NSArray *)entriesForField:(SEL)field uid:(SparkUID)uid {
  NSMutableArray *result = [[NSMutableArray alloc] init];
  
  SparkEntry *entry;
  SparkEntryAccessor accessor = NULL;
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
    if (!accessor) accessor = (SparkEntryAccessor)[entry methodForSelector:field];
    NSAssert1(accessor, @"invalid selector: %@", NSStringFromSelector(field));
    
    if (accessor(entry, field) == uid) {
      [result addObject:entry];
    }
  }
  NSEndMapTableEnumeration(&iter);
  return [result autorelease];
}

- (BOOL)containsEntryForField:(SEL)field uid:(SparkUID)uid {
  SparkEntry *entry;
  SparkEntryAccessor accessor = NULL;
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
    if (!accessor) accessor = (SparkEntryAccessor)[entry methodForSelector:field];
    NSAssert1(accessor, @"invalid selector: %@", NSStringFromSelector(field));
    
    if (accessor(entry, field) == uid) {
      NSEndMapTableEnumeration(&iter);
      return YES;
    }
  }
  NSEndMapTableEnumeration(&iter);
  return NO;
}

- (BOOL)containsEntryForTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication {
  SparkEntry *entry;
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
    if ([entry triggerUID] == aTrigger && [entry applicationUID] == anApplication) {
      NSEndMapTableEnumeration(&iter);
      return YES;
    }
  }
  NSEndMapTableEnumeration(&iter);
  return NO;
}

#pragma mark -
#pragma mark High-Level Methods
- (void)addEntry:(SparkEntry *)anEntry {
  NSParameterAssert(![anEntry manager]);
  NSParameterAssert([[anEntry action] uid] != 0);
  NSParameterAssert([[anEntry trigger] uid] != 0);
  
  /* sanity check, avoid entry conflict */
  NSParameterAssert(![anEntry isEnabled] || ![self activeEntryForTrigger:[anEntry trigger] application:[anEntry application]]);
  
  /* Undo management */
  [[self undoManager] registerUndoWithTarget:self selector:@selector(removeEntry:) object:anEntry];
  
  // Will add
  SparkLibraryPostNotification([self library], SparkEntryManagerWillAddEntryNotification, self, anEntry);
  
  [self sp_addEntry:anEntry];
  
  // Did add
  SparkLibraryPostNotification([self library], SparkEntryManagerDidAddEntryNotification, self, anEntry);
}

//- (void)replaceEntry:(SparkEntry *)anEntry withEntry:(SparkEntry *)newEntry {
//  NSParameterAssert([self containsEntry:anEntry]);
//  /* Undo management */
//  [[[self undoManager] prepareWithInvocationTarget:self] replaceEntry:newEntry withEntry:anEntry];
//  
//  // Will update
//  SparkLibraryPostUpdateNotification([self library], SparkEntryManagerWillUpdateEntryNotification, self, anEntry, newEntry);
//  SparkLibraryEntry update = { 0, 0, 0, 0 };
//  
//  /* Set entry uids */
//  update.action = [[newEntry action] uid];
//  update.trigger = [[newEntry trigger] uid];
//  update.application = [[newEntry application] uid];
//  /* Init flags */
//  SparkLibraryEntryInitFlags(&update, newEntry);
//  
//  [self replaceLibraryEntry:entry withLibraryEntry:&update];
//  
//  /* Update type */
//  [newEntry setType:[self typeForLibraryEntry:entry]];
//  [newEntry setPlugged:SparkLibraryEntryIsPlugged(entry)];
//  
//  // Did update
//  SparkLibraryPostUpdateNotification([self library], SparkEntryManagerDidUpdateEntryNotification, self, anEntry, newEntry);
//}

- (void)removeEntry:(SparkEntry *)anEntry {
  NSParameterAssert([anEntry manager] == self);
  
  /* Undo management */
  [[self undoManager] registerUndoWithTarget:self selector:@selector(addEntry:) object:anEntry];
  
  // Will remove
  SparkLibraryPostNotification([self library], SparkEntryManagerWillRemoveEntryNotification, self, anEntry);
  
  [[anEntry retain] autorelease];
  
  [self sp_removeEntry:anEntry];
  
  // Did remove
  SparkLibraryPostNotification([self library], SparkEntryManagerDidRemoveEntryNotification, self, anEntry);
}

- (void)removeEntries:(NSArray *)theEntries {
  NSUInteger count = [theEntries count];
  while (count-- > 0) {
    [self removeEntry:[theEntries objectAtIndex:count]];
  }
}

#pragma mark Getters
- (NSArray *)entriesForAction:(SparkUID)anAction {
  return [self entriesForField:@selector(actionUID) uid:anAction];
}
- (NSArray *)entriesForTrigger:(SparkUID)aTrigger {
  return [self entriesForField:@selector(triggerUID) uid:aTrigger];
}
- (NSArray *)entriesForApplication:(SparkUID)anApplication {
  return [self entriesForField:@selector(applicationUID) uid:anApplication];
}

- (BOOL)containsEntry:(SparkEntry *)anEntry {
  return [self containsEntryForTrigger:[[anEntry trigger] uid] application:[[anEntry application] uid]];
}

- (BOOL)containsEntryForAction:(SparkAction *)anAction{
  return [self containsEntryForField:@selector(actionUID) uid:[anAction uid]];
}
- (BOOL)containsEntryForTrigger:(SparkTrigger *)aTrigger {
  return [self containsEntryForField:@selector(triggerUID) uid:[aTrigger uid]];
}
- (BOOL)containsEntryForApplication:(SparkApplication *)anApplication {
  return [self containsEntryForField:@selector(applicationUID) uid:[anApplication uid]];
}
- (BOOL)containsActiveEntryForTrigger:(SparkTrigger *)aTrigger {
  SparkEntry *entry;
  SparkUID uid = [aTrigger uid];
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
    if (([entry triggerUID] == uid) && [entry isActive]) {
      NSEndMapTableEnumeration(&iter);
      return YES;
    }
  }
  NSEndMapTableEnumeration(&iter);
  return NO;
}
- (BOOL)containsPersistentActiveEntryForTrigger:(SparkTrigger *)aTrigger {
  SparkEntry *entry;
  SparkUID uid = [aTrigger uid];
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
    if (([entry triggerUID] == uid) && [entry isActive] && [entry isPersistent]) {
      NSEndMapTableEnumeration(&iter);
      return YES;
    }
  }
  NSEndMapTableEnumeration(&iter);
  return NO;
}

//- (BOOL)containsOverwriteEntryForTrigger:(SparkUID)aTrigger {
//  CFIndex count = CFArrayGetCount(sp_entries);
//  while (count-- > 0) {
//    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, count);
//    if (![entry isSystem] && ([entry triggerUID] == aTrigger)) {
//      return YES;
//    }
//  }
//  return NO;
//}
//- (BOOL)containsPersistentEntryForTrigger:(SparkUID)aTrigger {
//  CFIndex count = CFArrayGetCount(sp_entries);
//  while (count-- > 0) {
//    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, count);
//    if (([entry triggerUID] == aTrigger) && [entry isPersistent]) {
//      return YES;
//    }
//  }
//  return NO;
//}

#pragma mark -
- (SparkEntry *)activeEntryForTrigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
  SparkEntry *def = NULL;
  SparkEntry *entry = NULL;
  /* special case: anApplication is "All Application" (0) => def will always be null after the loop, so we don't have to do something special */
  SparkUID trigger = [aTrigger uid];
  SparkUID application = [anApplication uid];
  
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
    if ([entry triggerUID] == trigger && [entry isActive]) {
      if ([entry applicationUID] == application) {
        /* an active entry match */
        NSEndMapTableEnumeration(&iter);
        return entry;
      } else if ([entry isSystem]) {
        def = entry;
      }
    }
  }
  NSEndMapTableEnumeration(&iter);
  /* we didn't find a matching entry  */
  if (def) {
    SparkEntry *child = [def childWithApplication:anApplication];
    /* If the default is overwritten, we ignore it (whatever the child is) */
    if (!child)
      return def;
  }
  return NULL;
}

//- (SparkEntry *)child:(SparkEntry *)parent forTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication {
//  CFIndex count = CFArrayGetCount(sp_entries);
//  while (count-- > 0) {
//    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, count);
//    if ([entry triggerUID] == aTrigger && [entry applicationUID] == anApplication && [[entry parent] isEqual:parent]) {
//      return entry;
//    }
//  }
//  return NULL;  
//}

//- (SparkEntry *)entryForTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication {
//  const SparkLibraryEntry *entry = [self libraryEntryForTrigger:aTrigger application:anApplication];
//  if (entry) {
//    return [self entryForLibraryEntry:entry];
//  }
//  return nil;
//}

//- (SparkAction *)actionForTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication isActive:(BOOL *)active {
//  const SparkLibraryEntry *entry = [self libraryEntryForTrigger:aTrigger application:anApplication];
//  if (entry) {
//    if (active)
//      *active = SparkLibraryEntryIsActive(entry);
//    return [[[self library] actionSet] objectWithUID:entry->action];
//  }
//  return nil;
//}

//- (BOOL)isActionActive:(SparkUID)anAction forApplication:(SparkUID)anApplication {
//  BOOL enabled = NO;
//  CFIndex count = CFArrayGetCount(sp_entries);
//  while (count-- > 0) {
//    const SparkLibraryEntry *entry = CFArrayGetValueAtIndex(sp_entries, count);
//    if (entry->action == anAction) {
//      if (entry->application == anApplication) {
//        /* Set specific */
//        enabled = SparkLibraryEntryIsActive(entry);
//        break;
//      } else if (entry->application == kSparkApplicationSystemUID) {
//        /* Set default */
//        enabled = SparkLibraryEntryIsActive(entry);
//      }
//    }
//  }
//  return enabled;
//}

@end


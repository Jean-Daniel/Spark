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
    sp_entries = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kSKNSObjectArrayCallBacks);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePluginStatus:) 
                                                 name:SparkPlugInDidChangeStatusNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  CFRelease(sp_entries);
  [[NSNotificationCenter defaultCenter] removeObserver:self];
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
typedef SparkUID (*SparkEntryAccessor)(SparkEntry *, SEL);

- (SparkEntry *)entryForUID:(UInt32)uid {
  /* inefficient array search */
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, count);
    if ([entry uid] == uid) {
      return entry;
    }
  }
  return NO;
}

- (NSArray *)entriesForField:(SEL)field uid:(SparkUID)uid {
  NSMutableArray *result = [[NSMutableArray alloc] init];
  
  SparkEntryAccessor accessor = NULL;
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, count);
    if (!accessor) accessor = (SparkEntryAccessor)[entry methodForSelector:field];
    NSAssert1(accessor, @"invalid selector: %@", NSStringFromSelector(field));
    
    if (accessor(entry, field) == uid) {
      [result addObject:entry];
    }
  }
  return [result autorelease];
}

- (BOOL)containsEntryForField:(SEL)field uid:(SparkUID)uid {
  SparkEntryAccessor accessor = NULL;
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, count);
    if (!accessor) accessor = (SparkEntryAccessor)[entry methodForSelector:field];
    NSAssert1(accessor, @"invalid selector: %@", NSStringFromSelector(field));
    
    if (accessor(entry, field) == uid) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)containsEntryForTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication {
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, count);
    if ([entry triggerUID] == aTrigger && [entry applicationUID] == anApplication) {
      return YES;
    }
  }
  return NO;
}

#pragma mark -
#pragma mark High-Level Methods
- (void)addEntry:(SparkEntry *)anEntry {
  static NSUInteger sUID = 0;
  NSParameterAssert([[anEntry action] uid] != 0);
  NSParameterAssert([[anEntry trigger] uid] != 0);
  NSParameterAssert(![self containsEntry:anEntry]);
    
  /* Undo management */
  [[self undoManager] registerUndoWithTarget:self selector:@selector(removeEntry:) object:anEntry];
  /* should also undo sUID++ */
  
  /* New entry is disabled */
  [anEntry setEnabled:NO];
  
  // Will add
  SparkLibraryPostNotification([self library], SparkEntryManagerWillAddEntryNotification, self, anEntry);
  
  /* add entry */
  [anEntry setUID:++sUID];
  CFArrayAppendValue(sp_entries, anEntry);
  
  /* Update trigger flag */
  if ([anEntry applicationUID] != kSparkApplicationSystemUID)
    [[anEntry trigger] setHasManyAction:YES];
  
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
  NSParameterAssert([self containsEntry:anEntry]);
  /* Undo management */
  if ([anEntry isEnabled]) {
    [[self undoManager] registerUndoWithTarget:self selector:@selector(disableEntry:) object:anEntry];
  }
  [[self undoManager] registerUndoWithTarget:self selector:@selector(addEntry:) object:anEntry];
  
  // Will remove
  SparkLibraryPostNotification([self library], SparkEntryManagerWillRemoveEntryNotification, self, anEntry);
  
  
  [anEntry retain];
  //    BOOL global = anEntry->application == kSparkApplicationSystemUID;
  SparkAction *action = [anEntry action];
  SparkTrigger *trigger = [anEntry trigger];
  
  /* copy anEntry on stack */
  CFIndex idx = CFArrayGetFirstIndexOfValue(sp_entries, CFRangeMake(0, CFArrayGetCount(sp_entries)), anEntry);
  NSAssert(idx != kCFNotFound, @"Cannot found object in manager array, but found in set");
  if (idx != kCFNotFound)
    CFArrayRemoveValueAtIndex(sp_entries, idx);
  /* Note: anEntry could be freed an should no longer be used. */
  
  /* Should not automagically remove weak entries */
  //    if (global) {
  //      /* Remove weak entries */
  //      [self removeEntriesForAction:action];
  //    }
  
  /* Remove orphan action or update action status */
  if (![self containsEntryForAction:[action uid]]) {
    [[[self library] actionSet] removeObject:action];
  }
  /* Remove orphan trigger */
  [self checkTriggerValidity:trigger];
  
  // Did remove
  SparkLibraryPostNotification([self library], SparkEntryManagerDidRemoveEntryNotification, self, anEntry);
  [anEntry release];
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

- (BOOL)containsEntryForAction:(SparkUID)anAction {
  return [self containsEntryForField:@selector(actionUID) uid:anAction];
}
- (BOOL)containsEntryForTrigger:(SparkUID)aTrigger {
  return [self containsEntryForField:@selector(triggerUID) uid:aTrigger];
}
- (BOOL)containsEntryForApplication:(SparkUID)anApplication {
  return [self containsEntryForField:@selector(applicationUID) uid:anApplication];
}
- (BOOL)containsActiveEntryForTrigger:(SparkUID)aTrigger {
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, count);
    if (([entry triggerUID] == aTrigger) && [entry isActive]) {
      return YES;
    }
  }
  return NO;
}
- (BOOL)containsOverwriteEntryForTrigger:(SparkUID)aTrigger {
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, count);
    if (([entry applicationUID] != kSparkApplicationSystemUID) && ([entry triggerUID] == aTrigger)) {
      return YES;
    }
  }
  return NO;
}
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
- (BOOL)containsPersistentActiveEntryForTrigger:(SparkUID)aTrigger {
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, count);
    if (([entry triggerUID] == aTrigger) && [entry isActive] && [entry isPersistent]) {
      return YES;
    }
  }
  return NO;
}

#pragma mark -
- (SparkEntry *)activeEntryForTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication {
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, count);
    if ([entry triggerUID] == aTrigger && [entry applicationUID] == anApplication && [entry isActive]) {
      return entry;
    }
  }
  return NULL;
}
- (SparkEntry *)child:(SparkEntry *)parent forTrigger:(SparkUID)aTrigger application:(SparkUID)anApplication {
  CFIndex count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    SparkEntry *entry = (SparkEntry *)CFArrayGetValueAtIndex(sp_entries, count);
    if ([entry triggerUID] == aTrigger && [entry applicationUID] == anApplication && [[entry parent] isEqual:parent]) {
      return entry;
    }
  }
  return NULL;  
}

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


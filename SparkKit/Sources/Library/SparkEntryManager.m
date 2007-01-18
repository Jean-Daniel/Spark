/*
 *  SparkEntryManager.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Sparkkit/SparkEntryManager.h>
#import "SparkEntryManagerPrivate.h"

#import <SparkKit/SparkPrivate.h>

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkObjectSet.h>

/* Plugin status */
#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkActionLoader.h>

NSString * const SparkEntryNotificationKey = @"SparkEntryNotificationKey";
NSString * const SparkEntryReplacedNotificationKey = @"SparkEntryReplacedNotificationKey";

NSString * const SparkEntryManagerWillAddEntryNotification = @"SparkEntryManagerWillAddEntry";
NSString * const SparkEntryManagerDidAddEntryNotification = @"SparkEntryManagerDidAddEntry";

NSString * const SparkEntryManagerWillUpdateEntryNotification = @"SparkEntryManagerWillUpdateEntry";
NSString * const SparkEntryManagerDidUpdateEntryNotification = @"SparkEntryManagerDidUpdateEntry";
NSString * const SparkEntryManagerWillRemoveEntryNotification = @"SparkEntryManagerWillRemoveEntry";
NSString * const SparkEntryManagerDidRemoveEntryNotification = @"SparkEntryManagerDidRemoveEntry";

NSString * const SparkEntryManagerDidChangeEntryEnabledNotification = @"SparkEntryManagerDidChangeEntryEnabled";

@implementation SparkEntryManager

- (id)init {
  if (self = [self initWithLibrary:nil]) {
    
  }
  return self;
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary {
  NSParameterAssert(aLibrary);
  if (self = [super init]) {
    [self initInternal];
    sp_library = aLibrary;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePluginStatus:) 
                                                 name:SparkPlugInDidChangeStatusNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [self deallocInternal];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (SparkLibrary *)library {
  return sp_library;
}

- (NSUndoManager *)undoManager {
  return [sp_library undoManager];
}

#pragma mark -
#pragma mark Query
- (NSArray *)entriesForField:(unsigned)anIndex uid:(UInt32)uid {
  NSMutableArray *result = [[NSMutableArray alloc] init];
  
  UInt32 count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    const union {
      UInt32 key[4];
      SparkLibraryEntry entry;
    } *entry = CFArrayGetValueAtIndex(sp_entries, count);
    
    if (entry->key[anIndex] == uid) {
      SparkEntry *object = [self entryForLibraryEntry:&entry->entry];
      if (object)
        [result addObject:object];
    }
  }
  return [result autorelease];
}

- (BOOL)containsEntryForField:(unsigned)anIndex uid:(UInt32)uid {
  UInt32 count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    const union {
      UInt32 key[4];
      SparkLibraryEntry entry;
    } *entry = CFArrayGetValueAtIndex(sp_entries, count);
    
    if (entry->key[anIndex] == uid) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)containsEntryForTrigger:(UInt32)aTrigger application:(UInt32)anApplication {
  SparkLibraryEntry search;
  search.action = 0;
  search.trigger = aTrigger;
  search.application = anApplication;
  return CFSetContainsValue(sp_set, &search);
}

#pragma mark -
#pragma mark Entry Management - Enabled
- (void)setEnabled:(BOOL)flag forEntry:(SparkEntry *)anEntry {
  SparkLibraryEntry *entry = [self libraryEntryForEntry:anEntry];
  if (entry && XOR(flag, SparkLibraryEntryIsEnabled(entry))) {
    /* Undo management */
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:!flag forEntry:anEntry];
    /* update entry */
    [anEntry setEnabled:flag];
    /* Update library entry => Undo */
    [self setEnabled:flag forLibraryEntry:entry];
    SparkLibraryPostNotification([self library], SparkEntryManagerDidChangeEntryEnabledNotification, self, anEntry);
  }
}

- (void)enableEntry:(SparkEntry *)anEntry {
  [self setEnabled:YES forEntry:anEntry];
}
- (void)disableEntry:(SparkEntry *)anEntry {
  [self setEnabled:NO forEntry:anEntry];
}

#pragma mark -
#pragma mark High-Level Methods
- (void)addEntry:(SparkEntry *)anEntry {
  NSParameterAssert([[anEntry action] uid] != 0);
  NSParameterAssert([[anEntry trigger] uid] != 0);
  NSParameterAssert(![self containsEntry:anEntry]);
    
  /* Undo management */
  [[self undoManager] registerUndoWithTarget:self selector:@selector(removeEntry:) object:anEntry];
  
  // Will add
  SparkLibraryPostNotification([self library], SparkEntryManagerWillAddEntryNotification, self, anEntry);
  SparkLibraryEntry entry = { 0, 0, 0, 0 };
  entry.action = [[anEntry action] uid];
  entry.trigger = [[anEntry trigger] uid];
  entry.application = [[anEntry application] uid];
  
  /* New entry is disabled */
  [anEntry setEnabled:NO];
  SparkLibraryEntryInitFlags(&entry, anEntry);
  
  [self addLibraryEntry:&entry];
  
  /* Update entry */
  [anEntry setType:[self typeForLibraryEntry:&entry]];
  [anEntry setPlugged:SparkLibraryEntryIsPlugged(&entry)]; 

  // Did add
  SparkLibraryPostNotification([self library], SparkEntryManagerDidAddEntryNotification, self, anEntry);
}

- (void)replaceEntry:(SparkEntry *)anEntry withEntry:(SparkEntry *)newEntry {
  NSParameterAssert([self containsEntry:anEntry]);
  SparkLibraryEntry *entry = [self libraryEntryForEntry:anEntry];
  if (entry) {
    /* Undo management */
    [[[self undoManager] prepareWithInvocationTarget:self] replaceEntry:newEntry withEntry:anEntry];
    
    // Will update
    SparkLibraryPostUpdateNotification([self library], SparkEntryManagerWillUpdateEntryNotification, self, anEntry, newEntry);
    SparkLibraryEntry update = { 0, 0, 0, 0 };

    /* Set entry uids */
    update.action = [[newEntry action] uid];
    update.trigger = [[newEntry trigger] uid];
    update.application = [[newEntry application] uid];
    /* Init flags */
    SparkLibraryEntryInitFlags(&update, newEntry);
    
    [self replaceLibraryEntry:entry withLibraryEntry:&update];
    /* Update type */
    [newEntry setType:[self typeForLibraryEntry:entry]];
    // Did update
    SparkLibraryPostUpdateNotification([self library], SparkEntryManagerDidUpdateEntryNotification, self, anEntry, newEntry);
  }
}

- (void)removeEntry:(SparkEntry *)anEntry {
  NSParameterAssert([self containsEntry:anEntry]);
  /* Undo management */
  if ([anEntry isEnabled]) {
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:YES forEntry:anEntry];
  }
  [[self undoManager] registerUndoWithTarget:self selector:@selector(addEntry:) object:anEntry];
  
  // Will remove
  SparkLibraryPostNotification([self library], SparkEntryManagerWillRemoveEntryNotification, self, anEntry);
  SparkLibraryEntry entry;
  entry.action = [[anEntry action] uid];
  entry.trigger = [[anEntry trigger] uid];
  entry.application = [[anEntry application] uid];
  [self removeLibraryEntry:&entry];
  // Did remove
  SparkLibraryPostNotification([self library], SparkEntryManagerDidRemoveEntryNotification, self, anEntry);
}

- (void)removeEntries:(NSArray *)theEntries {
  unsigned count = [theEntries count];
  while (count-- > 0) {
    [self removeEntry:[theEntries objectAtIndex:count]];
  }
}

- (NSArray *)entriesForAction:(UInt32)anAction {
  return [self entriesForField:1 uid:anAction];
}
- (NSArray *)entriesForTrigger:(UInt32)aTrigger {
  return [self entriesForField:2 uid:aTrigger];
}
- (NSArray *)entriesForApplication:(UInt32)anApplication {
  return [self entriesForField:3 uid:anApplication];
}

- (BOOL)containsEntry:(SparkEntry *)anEntry {
  return [self containsEntryForTrigger:[[anEntry trigger] uid] application:[[anEntry application] uid]];
}

- (BOOL)containsEntryForAction:(UInt32)anAction {
  return [self containsEntryForField:1 uid:anAction];
}
- (BOOL)containsEntryForTrigger:(UInt32)aTrigger {
  return [self containsEntryForField:2 uid:aTrigger];
}
- (BOOL)containsEntryForApplication:(UInt32)anApplication {
  return [self containsEntryForField:3 uid:anApplication];
}
- (BOOL)containsActiveEntryForTrigger:(UInt32)aTrigger {
  UInt32 count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    const SparkLibraryEntry *entry = CFArrayGetValueAtIndex(sp_entries, count);
    if ((entry->trigger == aTrigger) && SparkLibraryEntryIsActive(entry)) {
      return YES;
    }
  }
  return NO;
}
- (BOOL)containsOverwriteEntryForTrigger:(UInt32)aTrigger {
  UInt32 count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    const SparkLibraryEntry *entry = CFArrayGetValueAtIndex(sp_entries, count);
    if (entry->application && (entry->trigger == aTrigger)) {
      return YES;
    }
  }
  return NO;
}
- (BOOL)containsPermanentEntryForTrigger:(UInt32)aTrigger {
  UInt32 count = CFArrayGetCount(sp_entries);
  while (count-- > 0) {
    const SparkLibraryEntry *entry = CFArrayGetValueAtIndex(sp_entries, count);
    if ((entry->trigger == aTrigger) && SparkLibraryEntryIsPermanent(entry)) {
      return YES;
    }
  }
  return NO;
}

- (SparkEntry *)entryForTrigger:(UInt32)aTrigger application:(UInt32)anApplication {
  const SparkLibraryEntry *entry = [self libraryEntryForTrigger:aTrigger application:anApplication];
  if (entry) {
    return [self entryForLibraryEntry:entry];
  }
  return nil;
}

- (SparkAction *)actionForTrigger:(UInt32)aTrigger application:(UInt32)anApplication isActive:(BOOL *)active {
  const SparkLibraryEntry *entry = [self libraryEntryForTrigger:aTrigger application:anApplication];
  if (entry) {
    if (active)
      *active = SparkLibraryEntryIsActive(entry);
    return [[sp_library actionSet] objectForUID:entry->action];
  }
  return nil;
}

@end


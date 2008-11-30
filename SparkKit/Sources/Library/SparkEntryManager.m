/*
 *  SparkEntryManager.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Sparkkit/SparkEntryManager.h>
#import "SparkEntryManagerPrivate.h"
#import "SparkEntryPrivate.h"

#import WBHEADER(WBEnumerator.h)

#import <objc/objc-runtime.h>
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
    [self setLibrary:aLibrary];
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
  [self setLibrary:nil];
  [super dealloc];
}

- (SparkLibrary *)library {
  return sp_library;
}
- (void)setLibrary:(SparkLibrary *)library {
	if (sp_library) {
		[[sp_library notificationCenter] removeObserver:self];
	}
  sp_library = library;
	if (sp_library) {
		[[sp_library notificationCenter] addObserver:self
																				selector:@selector(didRemoveApplication:) 
																						name:SparkObjectSetDidRemoveObjectNotification
																					object:[sp_library applicationSet]];
	}
}

- (NSUndoManager *)undoManager {
  return [[self library] undoManager];
}

#pragma mark -
#pragma mark Query
- (NSEnumerator *)entryEnumerator {
  return WBMapTableEnumerator(sp_objects, NO);
}

- (SparkEntry *)entryWithUID:(SparkUID)uid {
  return NSMapGet(sp_objects, (const void *)(intptr_t)uid);
}

typedef SparkUID (*SparkEntryAccessor)(SparkEntry *, SEL);

- (NSArray *)entriesForField:(SEL)field uid:(SparkUID)uid {
  SparkEntry *entry;
  NSMutableArray *result = [[NSMutableArray alloc] init];
  SparkEntryAccessor accessor = (SparkEntryAccessor)objc_msgSend;
  
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
    if (accessor(entry, field) == uid) {
      [result addObject:entry];
    }
  }
  NSEndMapTableEnumeration(&iter);
  return [result autorelease];
}

- (BOOL)containsEntryForField:(SEL)field uid:(SparkUID)uid {
  SparkEntry *entry;
  SparkEntryAccessor accessor = (SparkEntryAccessor)objc_msgSend;
  
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
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

- (SparkEntry *)addEntryWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
	NSParameterAssert(anAction && aTrigger && anApplication);
	SparkEntry *entry = [SparkEntry entryWithAction:anAction trigger:aTrigger application:anApplication];
	[self addEntry:entry parent:nil];
	return entry;
}

- (void)removeEntry:(SparkEntry *)anEntry {
	if (![anEntry manager]) return;
  NSParameterAssert([anEntry manager] == self);
	
  /* Undo management */
  [[[self undoManager] prepareWithInvocationTarget:self] addEntry:anEntry parent:[anEntry parent]];
  
  // Will remove
  SparkLibraryPostNotification([self library], SparkEntryManagerWillRemoveEntryNotification, self, anEntry);
  
  [[anEntry retain] autorelease];
  
  [self sp_removeEntry:anEntry];
	
  // Did remove
  SparkLibraryPostNotification([self library], SparkEntryManagerDidRemoveEntryNotification, self, anEntry);
}

- (void)removeEntriesInArray:(NSArray *)theEntries {
  NSUInteger count = [theEntries count];
  while (count-- > 0) {
    [self removeEntry:[theEntries objectAtIndex:count]];
  }
}

#pragma mark Getters
- (NSArray *)entriesForAction:(SparkAction *)anAction {
  return [self entriesForField:@selector(actionUID) uid:[anAction uid]];
}
- (NSArray *)entriesForTrigger:(SparkTrigger *)aTrigger {
  return [self entriesForField:@selector(triggerUID) uid:[aTrigger uid]];
}
- (NSArray *)entriesForApplication:(SparkApplication *)anApplication {
  return [self entriesForField:@selector(applicationUID) uid:[anApplication uid]];
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

- (BOOL)containsRegistredEntryForTrigger:(SparkTrigger *)aTrigger {
  SparkEntry *entry;
  SparkUID uid = [aTrigger uid];
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
    if (([entry triggerUID] == uid) && [entry isRegistred]) {
      NSEndMapTableEnumeration(&iter);
      return YES;
    }
  }
  NSEndMapTableEnumeration(&iter);
  return NO;
}

#pragma mark -
- (SparkEntry *)activeEntryForTrigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
	SparkEntry *entry = nil;
  SparkUID trigger = [aTrigger uid];
  SparkUID application = [anApplication uid];
  
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
    if ([entry triggerUID] == trigger && [entry isActive]) {
      if ([entry applicationUID] == application) {
        /* an active entry match */
        NSEndMapTableEnumeration(&iter);
        return entry;
      }
    }
  }
  NSEndMapTableEnumeration(&iter);
	return nil;
}

- (SparkEntry *)resolveEntryForTrigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
  SparkEntry *def = nil;
  SparkEntry *entry = nil;
  /* special case: anApplication is "All Application" (0) => def will always be null after the loop, so we don't have to do something special */
  SparkUID trigger = [aTrigger uid];
  SparkUID application = [anApplication uid];
  
  NSMapEnumerator iter = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&iter, NULL, (void * *)&entry)) {
    if ([entry triggerUID] == trigger && [entry isActive] && [entry isRegistred]) {
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
  /* we didn't find a matching entry, search default */
  if (def) {
    /* If the default is overwritten, we ignore it (whatever the child is) */
    if ([def variantWithApplication:anApplication]) 
      return NULL;
  }
  return def;
}

@end


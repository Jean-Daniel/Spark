/*
 *  SEEntryCache.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "Spark.h"
#import "SEEntryCache.h"
#import "SESparkEntrySet.h"
#import "SELibraryDocument.h"

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkObject.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkEntryManager.h>

#import <SparkKit/SparkActionLoader.h>

NSString * const SEEntryCacheDidReloadNotification = @"SEEntryCacheDidReload";

NSString * const SEEntryCacheDidAddEntryNotification = @"SEEntryCacheDidAddEntry";
NSString * const SEEntryCacheDidUpdateEntryNotification = @"SEEntryCacheDidUpdateEntry";
NSString * const SEEntryCacheWillRemoveEntryNotification = @"SEEntryCacheWillRemoveEntry";
NSString * const SEEntryCacheDidChangeEntryEnabledNotification = @"SEEntryCacheDidChangeEntryStatus";

@implementation SEEntryCache

- (id)init {
  [[self autorelease] doesNotRecognizeSelector:_cmd];
  return nil;
}

- (id)initWithDocument:(SELibraryDocument *)aDocument {
  if (self = [super init]) {
    se_document = aDocument;
    if (![aDocument library]) {
      [self release];
      self = nil;
      [NSException raise:NSInvalidArgumentException format:@"aDocument MUST contains a valid library."];
    } else {
      /* Create cache set */
      se_base = [[SESparkEntrySet alloc] init];
      se_merge = [[SESparkEntrySet alloc] init];
      
      /* Register for notifications */
      SparkLibrary *library = [se_document library];
      SparkEntryManager *manager = [library entryManager];
      
      [[library notificationCenter] addObserver:self
                                       selector:@selector(didAddEntry:) 
                                           name:SparkEntryManagerDidAddEntryNotification
                                         object:manager];
      [[library notificationCenter] addObserver:self
                                       selector:@selector(didUpdateEntry:) 
                                           name:SparkEntryManagerDidUpdateEntryNotification
                                         object:manager];
      [[library notificationCenter] addObserver:self
                                       selector:@selector(willRemoveEntry:) 
                                           name:SparkEntryManagerWillRemoveEntryNotification
                                         object:manager];
      /* Be sure the status is sync */
      [[library notificationCenter] addObserver:self
                                       selector:@selector(didChangeEntryStatus:) 
                                           name:SparkEntryManagerDidChangeEntryEnabledNotification
                                         object:manager];
      
      /* Update cache when enable/disable plugins */
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(didChangePlugin:)
                                                   name:SESparkEditorDidChangePluginStatusNotification
                                                 object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(didChangePlugin:)
                                                   name:SparkActionLoaderDidRegisterPlugInNotification
                                                 object:nil];
      [self reload];
    }
  }
  return self;
}

- (void)dealloc {
  [se_base release];
  [se_merge release];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[[se_document library] notificationCenter] removeObserver:self];
  [super dealloc];
}

- (void)reload {
  [se_base removeAllEntries];
  /* populate base */
  [se_base addEntriesFromArray:[[[se_document library] entryManager] entriesForApplication:0]];
  
  /* Populate merge */
  [self refresh];
  
  /* Notify reload */
  [[[se_document library] notificationCenter] postNotificationName:SEEntryCacheDidReloadNotification
                                                            object:self];
}

- (void)refresh {
  [se_merge removeAllEntries];
  
  [se_merge addEntriesFromEntrySet:se_base];  
  SparkEntryManager *manager = [[se_document library] entryManager];
  if ([[se_document application] uid] != 0 && [manager containsEntryForApplication:[[se_document application] uid]]) {
    /* Copy base */
    [se_merge addEntriesFromArray:[manager entriesForApplication:[[se_document application] uid]]];
  }
}

- (SESparkEntrySet *)entries {
  return se_merge;
}

#pragma mark -
- (BOOL)addEntry:(SparkEntry *)entry previous:(SparkEntry **)updated {
  NSParameterAssert(entry);
  
  SparkEntry *old = nil;
  /* If entry is global */
  if ([[entry application] uid] == 0) {
    /* first, update base */
    NSAssert(![se_base containsTrigger:[entry trigger]], @"Internal Inconsistency");
    [se_base addEntry:entry];
    /* If current application is global or merge does not override the new entry (=> inherits) */
    if ([[se_document application] uid] == 0 || ![se_merge containsTrigger:[entry trigger]]) {
      [se_merge addEntry:entry];
    } else {
      /* do not send notification */
      return NO;
    }
  } else if ([[se_document application] isEqual:[entry application]]) {
    /* entry is specific and match current context */
    old = [se_merge entryForTrigger:[entry trigger]];
    /* 'old' can only be an inherited entry, else update should be called instead of add */
    NSAssert(!old || [[old application] uid] == 0, @"Internal Inconsistency");
    [se_merge addEntry:entry];
  } else {
    /* entry->application != document->application, do nothing */
    return NO;
  }
  if (updated) *updated = old;
  return YES;
}

- (BOOL)removeEntry:(SparkEntry *)entry replacedBy:(SparkEntry **)newEntry {
  NSParameterAssert(entry);
  
  SparkEntry *new = nil;
  /* If entry is global */
  if ([[entry application] uid] == 0) {
    /* first, update base */
    NSAssert([se_base containsTrigger:[entry trigger]], @"Internal Inconsistency");
    [se_base removeEntry:entry];
    /* If current application is global or merge contains the removed entry (=> inherits) */
    if ([[se_document application] uid] == 0 || [se_merge containsEntry:entry]) {
      [se_merge removeEntry:entry];
    } else {
      /* do not send notification */
      return NO;
    }
  } else if ([[se_document application] isEqual:[entry application]]) {
    /* 'merge' MUST contains the removed entry */
    NSAssert([se_merge containsEntry:entry], @"Internal Inconsistency");
    [se_merge removeEntry:entry];
    /* If base contains a remplacement entry (=> inherits) */
    new = [se_base entryForTrigger:[entry trigger]];
    if (new)
      [se_merge addEntry:new];
  } else {
    /* entry->application != document->application, do nothing */
    return NO;
  }
  if (newEntry) *newEntry = new;
  return YES;
}

- (void)didAddEntry:(NSNotification *)aNotification {
  SparkEntry *updated = nil;
  SparkEntry *entry = SparkNotificationObject(aNotification);
  if ([self addEntry:entry previous:&updated]) {
    if (updated) {
      SparkLibraryPostUpdateNotification([se_document library], 
                                         SEEntryCacheDidUpdateEntryNotification, self, updated, entry);
    } else {
      /* Notify High-level entry change */
      SparkLibraryPostNotification([se_document library],
                                   SEEntryCacheDidAddEntryNotification, self, entry);
    }
  }
}

- (void)didUpdateEntry:(NSNotification *)aNotification {
  BOOL add = NO, delete = NO;
  SparkEntry *new = nil, *updated = nil;
  SparkEntry *added = SparkNotificationObject(aNotification);
  SparkEntry *removed = SparkNotificationUpdatedObject(aNotification);
  
  delete = [self removeEntry:removed replacedBy:&new];
  add = [self addEntry:added previous:&updated];
  
  if (delete && add && new != nil && new == updated) {
    /* Special case where new == updated */
    SparkLibraryPostUpdateNotification([se_document library], 
                                       SEEntryCacheDidUpdateEntryNotification, self, removed, added);
  } else {
    if (delete) {
      /* Notify removed */
      if (new) {
        SparkLibraryPostUpdateNotification([se_document library], 
                                           SEEntryCacheDidUpdateEntryNotification, self, removed, new);
      } else {
        /* Notify High-level entry change */
        SparkLibraryPostNotification([se_document library],
                                     SEEntryCacheWillRemoveEntryNotification, self, removed);
      }
    } 
    if (add) {
      /* Notify add */
      if (updated) {
        SparkLibraryPostUpdateNotification([se_document library], 
                                           SEEntryCacheDidUpdateEntryNotification, self, updated, added);
      } else {
        /* Notify High-level entry change */
        SparkLibraryPostNotification([se_document library],
                                     SEEntryCacheDidAddEntryNotification, self, added);
      }
    }
  }
}

- (void)willRemoveEntry:(NSNotification *)aNotification {
  SparkEntry *new = nil;
  SparkEntry *entry = SparkNotificationObject(aNotification);
  if ([self removeEntry:entry replacedBy:&new]) {
    if (new) {
      SparkLibraryPostUpdateNotification([se_document library], 
                                         SEEntryCacheDidUpdateEntryNotification, self, entry, new);
    } else {
      /* Notify High-level entry change */
      SparkLibraryPostNotification([se_document library],
                                   SEEntryCacheWillRemoveEntryNotification, self, entry);
    }
  }  
}

- (void)didChangeEntryStatus:(NSNotification *)aNotification {
  SparkEntry *entry = SparkNotificationObject(aNotification);
  
  SparkEntry *current = [se_base entry:entry];
  if (current)
    [se_base replaceEntry:current withEntry:entry];
  
  current = [se_merge entry:entry];
  if (current)
    [se_merge replaceEntry:current withEntry:entry];
  
  [[[se_document library] notificationCenter] postNotificationName:SEEntryCacheDidChangeEntryEnabledNotification
                                                            object:self
                                                          userInfo:[aNotification userInfo]];
}

- (void)didChangePlugin:(NSNotification *)aNotification {
  [self reload];
}

@end

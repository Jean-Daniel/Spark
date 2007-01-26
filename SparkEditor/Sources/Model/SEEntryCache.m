/*
 *  SEEntryCache.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEEntryCache.h"
#import "SESparkEntrySet.h"
#import "SELibraryDocument.h"

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkObject.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkEntryManager.h>

NSString * const SEEntryCacheDidReloadNotification = @"SEEntryCacheDidReload";

NSString * const SEEntryCacheDidAddEntryNotification = @"SEEntryCacheDidAddEntry";
NSString * const SEEntryCacheDidUpdateEntryNotification = @"SEEntryCacheDidUpdateEntry";
NSString * const SEEntryCacheDidRemoveEntryNotification = @"SEEntryCacheDidRemoveEntry";
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
                                       selector:@selector(didUpdateAction:) 
                                           name:SparkObjectSetDidUpdateObjectNotification
                                         object:[library actionSet]];
      [[library notificationCenter] addObserver:self
                                       selector:@selector(didUpdateTrigger:) 
                                           name:SparkObjectSetDidUpdateObjectNotification
                                         object:[library triggerSet]];
      
      [[library notificationCenter] addObserver:self
                                       selector:@selector(didAddEntry:) 
                                           name:SparkEntryManagerDidAddEntryNotification
                                         object:manager];
      [[library notificationCenter] addObserver:self
                                       selector:@selector(didUpdateEntry:) 
                                           name:SparkEntryManagerDidUpdateEntryNotification
                                         object:manager];
      [[library notificationCenter] addObserver:self
                                       selector:@selector(didRemoveEntry:) 
                                           name:SparkEntryManagerDidRemoveEntryNotification
                                         object:manager];
      /* Be sure the status is sync */
      [[library notificationCenter] addObserver:self
                                       selector:@selector(didChangeEntryStatus:) 
                                           name:SparkEntryManagerDidChangeEntryEnabledNotification
                                         object:manager];
      [self reload];
    }
  }
  return self;
}

- (void)dealloc {
  [se_base release];
  [se_merge release];
  [super dealloc];
}

- (void)reload {
  [se_base removeAllEntries];
  /* populate base */
  [se_base addEntriesFromArray:[[[se_document library] entryManager] entriesForApplication:0]];
  
  /* Populate merge */
  [self refresh];
  
  /* Notify reload */
  [[NSNotificationCenter defaultCenter] postNotificationName:SEEntryCacheDidReloadNotification
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

- (SESparkEntrySet *)base {
  return se_base;
}

- (SESparkEntrySet *)entries {
  return se_merge;
}

#pragma mark -
- (void)addEntry:(SparkEntry *)entry {
  if ([[entry application] uid] == 0) {
    [se_base addEntry:entry];
    /* If current application is global or merge does not override the new entry */
    if ([[se_document application] uid] == 0 || ![se_merge containsTrigger:[entry trigger]]) {
      [se_merge addEntry:entry];
    }
  } else if ([[entry application] uid] == [[se_document application] uid]) {
    [se_merge addEntry:entry];
  }
}

- (void)removeEntry:(SparkEntry *)entry {
  if ([[entry application] uid] == 0) {
    [se_base removeEntry:entry];
    /* if se_merge equals se_base */
    if ([[se_document application] uid] == 0)
      [se_merge removeEntry:entry];
  } else if ([[entry application] uid] == [[se_document application] uid]) {
    [se_merge removeEntry:entry];
    /* If global contains a trigger for the removed entry, add it to merge */
    SparkEntry *base = [se_base entryForTrigger:[entry trigger]];
    if (base)
      [se_merge addEntry:base];
  }
}

- (void)didUpdateAction:(NSNotification *)aNotification {
  
}

- (void)didUpdateTrigger:(NSNotification *)aNotification {
  
}


- (void)didAddEntry:(NSNotification *)aNotification {
  [self addEntry:SparkNotificationObject(aNotification)];
  /* Notify High-level entry change */
  [[[se_document library] notificationCenter] postNotificationName:SEEntryCacheDidAddEntryNotification
                                                            object:self 
                                                          userInfo:[aNotification userInfo]];
}

- (void)didUpdateEntry:(NSNotification *)aNotification {
  /* Remove old object */
  [self removeEntry:SparkNotificationUpdatedObject(aNotification)];
  /* Add new object */
  [self addEntry:SparkNotificationObject(aNotification)];
  /* Notify High-level entry change */
  [[[se_document library] notificationCenter] postNotificationName:SEEntryCacheDidUpdateEntryNotification
                                                            object:self 
                                                          userInfo:[aNotification userInfo]];
}

- (void)didRemoveEntry:(NSNotification *)aNotification {
  [self removeEntry:SparkNotificationObject(aNotification)];
  /* Notify High-level entry change */
  [[[se_document library] notificationCenter] postNotificationName:SEEntryCacheDidRemoveEntryNotification
                                                            object:self 
                                                          userInfo:[aNotification userInfo]];
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

@end

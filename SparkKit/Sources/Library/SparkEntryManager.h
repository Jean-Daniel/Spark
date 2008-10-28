/*
 *  SparkEntryManager.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

#pragma mark Notifications

SPARK_EXPORT
NSString * const SparkEntryManagerWillAddEntryNotification;
SPARK_EXPORT
NSString * const SparkEntryManagerDidAddEntryNotification;

SPARK_EXPORT
NSString * const SparkEntryManagerWillUpdateEntryNotification;
SPARK_EXPORT
NSString * const SparkEntryManagerDidUpdateEntryNotification;

SPARK_EXPORT
NSString * const SparkEntryManagerWillRemoveEntryNotification;
SPARK_EXPORT
NSString * const SparkEntryManagerDidRemoveEntryNotification;

SPARK_EXPORT
NSString * const SparkEntryManagerDidChangeEntryStatusNotification;

@class SparkObject;
@class SparkLibrary, SparkEntry;
@class SparkAction, SparkTrigger, SparkApplication;
SPARK_CLASS_EXPORT
@interface SparkEntryManager : NSObject {
  @private
  SparkLibrary *sp_library; /* __weak */
  NSMapTable *sp_objects;
	
	/* editing context */
	struct {
		SparkEntry *entry;
		SparkAction *action;
		SparkTrigger *trigger;
		SparkApplication *application;
	} sp_edit;
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary;

- (SparkLibrary *)library;
- (NSUndoManager *)undoManager;

/* Private, use to dereference weak */
- (void)setLibrary:(SparkLibrary *)library;

#pragma mark Management
- (NSEnumerator *)entryEnumerator;
- (SparkEntry *)entryWithUID:(SparkUID)uid;

/* add a new root entry */
- (SparkEntry *)addEntryWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)aApplication;

- (void)removeEntry:(SparkEntry *)anEntry;
- (void)removeEntriesInArray:(NSArray *)theEntries;

#pragma mark Queries
//- (NSArray *)entriesForAction:(SparkUID)anAction;
//- (NSArray *)entriesForTrigger:(SparkUID)aTrigger;
- (NSArray *)entriesForApplication:(SparkApplication *)anApplication;

/* Orphan check */
- (BOOL)containsEntryForAction:(SparkAction *)anAction;
- (BOOL)containsEntryForTrigger:(SparkTrigger *)aTrigger;

//- (BOOL)containsEntry:(SparkEntry *)anEntry;
//- (BOOL)containsOverwriteEntryForTrigger:(SparkUID)aTrigger;
//- (BOOL)containsPersistentEntryForTrigger:(SparkUID)aTrigger;

/* Daemon queries */
- (BOOL)containsRegistredEntryForTrigger:(SparkTrigger *)aTrigger;
//- (BOOL)containsActiveEntryForTrigger:(SparkTrigger *)aTrigger;
//- (BOOL)containsPersistentActiveEntryForTrigger:(SparkTrigger *)aTrigger;

/* Editor Queries */
- (BOOL)containsEntryForApplication:(SparkApplication *)anApplication;

- (SparkEntry *)activeEntryForTrigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;

/* First, search for specifics actions */
/* If not found, search for a default action */
/* If default action found, search default action child for anApplication, and if exist returns child, else returns default */
/* Else return NULL */
- (SparkEntry *)resolveEntryForTrigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;

@end

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

SPARK_OBJC_EXPORT
@interface SparkEntryManager : NSObject

- (instancetype)initWithLibrary:(SparkLibrary *)aLibrary;

@property(nonatomic, readonly) SparkLibrary *library;
@property(nonatomic, readonly) NSUndoManager *undoManager;

#pragma mark Management
- (SparkEntry *)entryWithUID:(SparkUID)uid;

- (void)enumerateEntriesUsingBlock:(void (^)(SparkEntry *entry, BOOL *stop))block;

/* add a new root entry */
- (SparkEntry *)addEntryWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)aApplication;

- (void)removeEntry:(SparkEntry *)anEntry;
- (void)removeEntriesInArray:(NSArray *)theEntries;

#pragma mark Queries
//- (NSArray *)entriesForAction:(SparkUID)anAction;
- (NSArray *)entriesForTrigger:(SparkTrigger *)aTrigger;
- (NSArray *)entriesForApplication:(SparkApplication *)anApplication;

/* Orphan check */
- (BOOL)containsEntryForAction:(SparkAction *)anAction;
- (BOOL)containsEntryForTrigger:(SparkTrigger *)aTrigger;
/* Editor Queries */
- (BOOL)containsEntryForApplication:(SparkApplication *)anApplication;

/* Daemon queries */
- (BOOL)containsRegistredEntryForTrigger:(SparkTrigger *)aTrigger;

- (SparkEntry *)activeEntryForTrigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;

/* First, search for specifics actions */
/* If not found, search for a default action */
/* If default action found, search default action child for anApplication. If one exists, returns NULL, else returns default */
- (SparkEntry *)resolveEntryForTrigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;

@end

@interface SparkEntryManager ()
/* Private, use to dereference weak */
@property(nonatomic, assign) SparkLibrary *library;

@end


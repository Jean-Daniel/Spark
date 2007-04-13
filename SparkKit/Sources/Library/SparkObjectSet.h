/*
 *  SparkObjectSet.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkObject.h>

/*!
@class SparkObjectSet
@abstract Spark Objects Library.
*/
@class SparkLibrary;
SK_CLASS_EXPORT
@interface SparkObjectSet : NSObject {
@private
  SparkUID sp_uid;
  NSMapTable *sp_objects;

  SparkLibrary *sp_library;
}

- (id)initWithLibrary:(SparkLibrary *)library;
+ (id)objectsLibraryWithLibrary:(SparkLibrary *)aLibrary;

- (SparkLibrary *)library;
- (void)setLibrary:(SparkLibrary *)aLibrary;

- (NSUndoManager *)undoManager;

#pragma mark Content Manipulation
- (NSUInteger)count;
- (NSArray *)objects;
- (NSEnumerator *)objectEnumerator;

- (BOOL)containsObject:(SparkObject *)object;
- (BOOL)containsObjectWithUID:(SparkUID)uid;

- (id)objectWithUID:(SparkUID)uid;

- (BOOL)addObject:(SparkObject *)object;
- (BOOL)updateObject:(SparkObject *)object;
- (void)removeObject:(SparkObject *)object;
- (void)removeObjectWithUID:(SparkUID)uid;

- (NSUInteger)addObjectsFromArray:(NSArray *)objects;
- (void)removeObjectsInArray:(NSArray *)newObjects;

- (NSFileWrapper *)fileWrapper:(NSError **)outError;
- (NSDictionary *)serialize:(SparkObject *)object error:(OSStatus *)error;
- (SparkObject *)deserialize:(NSDictionary *)plist error:(OSStatus *)error;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError;

#pragma mark UID Management
- (SparkUID)nextUID;
- (SparkUID)currentUID;
- (void)setCurrentUID:(SparkUID)uid;

@end

#pragma mark -
@interface SparkPlaceHolder : SparkObject {
  @private 
  NSDictionary *sp_plist;
}

- (NSDictionary *)values;

@end

#pragma mark -
#pragma mark Notifications
SPARK_EXPORT
NSString * const SparkObjectSetWillAddObjectNotification;
SPARK_EXPORT
NSString * const SparkObjectSetDidAddObjectNotification;

SPARK_EXPORT
NSString * const SparkObjectSetWillUpdateObjectNotification;
SPARK_EXPORT
NSString * const SparkObjectSetDidUpdateObjectNotification;

SPARK_EXPORT
NSString * const SparkObjectSetWillRemoveObjectNotification;
SPARK_EXPORT
NSString * const SparkObjectSetDidRemoveObjectNotification;


SPARK_EXPORT
NSComparisonResult SparkObjectCompare(SparkObject *obj1, SparkObject *obj2, void *source);

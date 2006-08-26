/*
 *  SparkObjectSet.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkObject.h>

/*!
@class SparkObjectSet
@abstract Spark Objects Library.
*/
@class SparkLibrary;
@interface SparkObjectSet : NSObject {
@private
  UInt32 sp_uid;
  NSMapTable *sp_objects;

  SparkLibrary *sp_library;
}

- (id)initWithLibrary:(SparkLibrary *)library;
+ (id)objectsLibraryWithLibrary:(SparkLibrary *)aLibrary;

- (SparkLibrary *)library;
- (void)setLibrary:(SparkLibrary *)aLibrary;

#pragma mark Content Manipulation
- (UInt32)count;
- (NSArray *)objects;
- (NSEnumerator *)objectEnumerator;

- (BOOL)containsObject:(SparkObject *)object;

- (id)objectForUID:(UInt32)uid;

- (BOOL)addObject:(SparkObject *)object;
- (BOOL)updateObject:(SparkObject *)object;
- (void)removeObject:(SparkObject *)object;
- (void)removeObjectWithUID:(UInt32)uid;

- (int)addObjectsFromArray:(NSArray *)objects;
- (void)removeObjectsInArray:(NSArray *)newObjects;

- (NSFileWrapper *)fileWrapper:(NSError **)outError;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError;

#pragma mark UID Management
- (UInt32)nextUID;
- (UInt32)currentUID;
- (void)setCurrentUID:(UInt32)uid;
@end

#pragma mark -
@interface SparkPlaceHolder : SparkObject {
  @private 
  NSDictionary *sp_plist;
}
@end

#pragma mark -
#pragma mark Notifications
SPARK_EXPORT
NSString * const kSparkLibraryWillAddObjectNotification;
SPARK_EXPORT
NSString * const kSparkLibraryDidAddObjectNotification;

SPARK_EXPORT
NSString * const kSparkLibraryWillUpdateObjectNotification;
SPARK_EXPORT
NSString * const kSparkLibraryDidUpdateObjectNotification;

SPARK_EXPORT
NSString * const kSparkLibraryWillRemoveObjectNotification;
SPARK_EXPORT
NSString * const kSparkLibraryDidRemoveObjectNotification;

SPARK_EXPORT
NSString * const kSparkNotificationObject;
SPARK_EXPORT
NSString * const kSparkNotificationUpdatedObject;

SPARK_INLINE
SparkObject *SparkNotificationObject(NSNotification *aNotification) {
  return [[aNotification userInfo] objectForKey:kSparkNotificationObject];
}

SPARK_EXPORT
NSComparisonResult SparkObjectCompare(SparkObject *obj1, SparkObject *obj2, void *source);

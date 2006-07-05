//
//  SparkObjectsLibrary.h
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit.h>

/*!
    @class SparkObjectsLibrary
    @abstract   (description)
*/

@class SparkLibrary, SparkLibraryObject;
@interface SparkObjectsLibrary : NSObject {
@private
  UInt32 sp_uid;
  CFMutableDictionaryRef sp_objects;

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

- (BOOL)containsObject:(SparkLibraryObject *)object;

- (id)objectWithId:(UInt32)uid;
- (NSArray *)objectsWithIds:(NSIndexSet *)uids;

- (BOOL)addObject:(SparkLibraryObject *)object;
- (BOOL)updateObject:(SparkLibraryObject *)object;
- (void)removeObject:(SparkLibraryObject *)object;

- (int)addObjects:(NSArray *)objects;
- (void)removeObjects:(NSArray *)newObjects;

//#pragma mark Objects Loading
//- (void)loadObjects:(NSArray *)newObjects;
//- (void)loadObject:(NSMutableDictionary *)object;

#pragma mark UID Management
- (UInt32)nextUID;
- (UInt32)currentUID;
- (void)setCurrentUID:(UInt32)uid;
@end

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

SPARK_INLINE
id SparkNotificationObject(NSNotification *aNotification) {
  return [[aNotification userInfo] objectForKey:kSparkNotificationObject];
}

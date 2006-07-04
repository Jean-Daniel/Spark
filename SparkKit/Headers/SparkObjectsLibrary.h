//
//  SparkObjectsLibrary.h
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKitBase.h>
#import <SparkKit/SparkSerialization.h>

/*!
    @class SparkObjectsLibrary
    @abstract   (description)
*/

SPARK_EXPORT
NSString * const kSparkLibraryObject;

SPARK_EXPORT
NSString * const kSparkNotificationObject;

SPARK_EXTERN_INLINE
id SparkNotificationObject(NSNotification *aNotification);

@class SparkLibrary;
@interface SparkObjectsLibrary : NSObject {
@private
  unsigned int _uid;
  unsigned int	_version;
  NSMutableDictionary *_objects;
  
  SparkLibrary *_library;
}

- (id)initWithLibrary:(SparkLibrary *)library;
+ (id)objectsLibraryWithLibrary:(SparkLibrary *)aLibrary;

- (NSData *)serialize;
- (BOOL)loadData:(NSData *)data;

- (SparkLibrary *)library;
- (void)setLibrary:(SparkLibrary *)aLibrary;

#pragma mark Content Manipulation
- (unsigned)count;
- (NSArray *)objects;
- (NSEnumerator *)objectEnumerator;

- (BOOL)containsObject:(id<SparkLibraryObject>)object;

- (id)objectWithId:(id)uid;
- (NSArray *)objectsWithIds:(NSArray *)ids;

- (BOOL)addObject:(id<SparkLibraryObject>)object;
- (BOOL)updateObject:(id<SparkLibraryObject>)object;
- (void)removeObject:(id<SparkLibraryObject>)object;

- (int)addObjects:(NSArray *)objects;
- (void)removeObjects:(NSArray *)newObjects;

#pragma mark Objects Loading
- (void)loadObjects:(NSArray *)newObjects;
- (void)loadObject:(NSMutableDictionary *)object;

#pragma mark Misc
- (id)propertyList;
- (unsigned int)version;

#pragma mark UID Management
- (unsigned)nextUid;
- (unsigned int)currentId;
- (void)setCurrentUid:(unsigned int)uid;

#pragma mark Notification Utility
- (void)postNotification:(NSString *)name withObject:(id)object;

@end

/*
 *  SparkObjectSet.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkObject.h>

NS_ASSUME_NONNULL_BEGIN

/*!
@class SparkObjectSet
@abstract Spark Objects Library.
*/
@class SparkLibrary;

SPARK_OBJC_EXPORT
@interface SparkObjectSet : NSObject

- (instancetype)initWithLibrary:(SparkLibrary *)library NS_DESIGNATED_INITIALIZER;
+ (instancetype)objectsSetWithLibrary:(SparkLibrary *)aLibrary;

@property(nonatomic, assign) SparkLibrary *library;

@property(nonatomic, nullable, readonly) NSUndoManager *undoManager;

#pragma mark Content Manipulation
@property(nonatomic, readonly) NSUInteger count;
@property(nonatomic, readonly) NSArray *allObjects;

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, BOOL *stop))block;

- (BOOL)containsObject:(SparkObject *)object;
- (BOOL)containsObjectWithUID:(SparkUID)uid;

- (nullable id)objectWithUID:(SparkUID)uid;

- (BOOL)addObject:(SparkObject *)object;
//- (BOOL)updateObject:(SparkObject *)object;
- (void)removeObject:(SparkObject *)object;
- (void)removeObjectWithUID:(SparkUID)uid;

- (NSUInteger)addObjectsFromArray:(NSArray *)objects;
- (void)removeObjectsInArray:(NSArray *)newObjects;

- (nullable NSFileWrapper *)fileWrapper:(out NSError **)outError;
- (nullable NSDictionary *)serialize:(SparkObject *)object error:(out NSError **)error;
- (nullable SparkObject *)deserialize:(NSDictionary *)plist error:(out NSError **)error;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(out NSError **)outError;

#pragma mark UID Management
- (SparkUID)nextUID;
- (SparkUID)currentUID;
- (void)setCurrentUID:(SparkUID)uid;

@end

#pragma mark -
@interface SparkPlaceHolder : SparkObject

- (nullable NSDictionary *)values;

@end

#pragma mark -
#pragma mark Notifications
SPARK_EXPORT
NSString * const SparkObjectSetWillAddObjectNotification;
SPARK_EXPORT
NSString * const SparkObjectSetDidAddObjectNotification;

//SPARK_EXPORT
//NSString * const SparkObjectSetWillUpdateObjectNotification;
//SPARK_EXPORT
//NSString * const SparkObjectSetDidUpdateObjectNotification;

SPARK_EXPORT
NSString * const SparkObjectSetWillRemoveObjectNotification;
SPARK_EXPORT
NSString * const SparkObjectSetDidRemoveObjectNotification;


SPARK_EXPORT
NSComparator SparkObjectCompare;

NS_ASSUME_NONNULL_END

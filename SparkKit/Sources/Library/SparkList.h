/*
 *  SparkList.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkObject.h>
#import <SparkKit/SparkObjectSet.h>

@class SparkList, SparkEntry;

typedef bool(^SparkListFilter)(SparkList *, SparkEntry *);

SPARK_EXPORT
NSString * const SparkListDidReloadNotification;

SPARK_EXPORT
NSString * const SparkListDidAddEntryNotification;
SPARK_EXPORT
NSString * const SparkListDidAddEntriesNotification;

SPARK_EXPORT
NSString * const SparkListDidRemoveEntryNotification;
SPARK_EXPORT
NSString * const SparkListDidRemoveEntriesNotification;

@class SparkEntry, SparkApplication;

SPARK_OBJC_EXPORT
@interface SparkList : SparkObject <NSFastEnumeration>

@property (nonatomic, readonly, getter=isDynamic) BOOL dynamic;

- (void)reload;

@property(nonatomic, copy) SparkListFilter filter;

@property(nonatomic, readonly) NSUInteger count;

- (BOOL)containsEntry:(SparkEntry *)anEntry;
- (NSUInteger)indexOfEntry:(SparkEntry *)anEntry;
- (NSArray *)entriesForApplication:(SparkApplication *)anApplication;

- (void)addEntry:(SparkEntry *)anEntry;
- (void)addEntriesFromArray:(NSArray *)anArray;

- (void)removeEntry:(SparkEntry *)anObject;
- (void)removeEntriesInArray:(NSArray *)anArray;

- (BOOL)acceptsEntry:(SparkEntry *)anEntry;
- (BOOL)acceptsEntryOrChild:(SparkEntry *)anEntry;

#pragma mark KVC
- (NSArray *)entries;
- (NSUInteger)countOfEntries;
- (void)setEntries:(NSArray *)entries;
- (SparkEntry *)objectInEntriesAtIndex:(NSUInteger)idx;
- (void)getEntries:(id __unsafe_unretained [])aBuffer range:(NSRange)range;
- (void)insertObject:(SparkEntry *)anEntry inEntriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromEntriesAtIndex:(NSUInteger)idx;
- (void)replaceObjectInEntriesAtIndex:(NSUInteger)idx withObject:(SparkEntry *)object;

@end

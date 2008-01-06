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
typedef BOOL(*SparkListFilter)(SparkList *, SparkEntry *, id ctxt);

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
SK_CLASS_EXPORT
@interface SparkList : SparkObject {
  @private  
  NSMutableArray *sp_entries;
  
  id sp_ctxt;
  SparkListFilter sp_filter;
}

- (void)reload;
- (BOOL)isDynamic;
- (id)filterContext;
- (void)setListFilter:(SparkListFilter)aFilter context:(id)aCtxt;

- (NSUInteger)count;
//- (NSEnumerator *)objectEnumerator;
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
- (void)getEntries:(id *)aBuffer range:(NSRange)range;
- (void)insertObject:(SparkEntry *)anEntry inEntriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromEntriesAtIndex:(NSUInteger)idx;
- (void)replaceObjectInEntriesAtIndex:(NSUInteger)idx withObject:(SparkEntry *)object;

@end

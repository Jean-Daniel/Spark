/*
 *  SparkList.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkObject.h>
#import <SparkKit/SparkObjectSet.h>

@class SparkList;
typedef BOOL(*SparkListFilter)(SparkList *, SparkObject *, id ctxt);

SPARK_EXPORT
NSString * const SparkListDidReloadNotification;

SPARK_EXPORT
NSString * const SparkListDidAddObjectNotification;
SPARK_EXPORT
NSString * const SparkListDidAddObjectsNotification;

SPARK_EXPORT
NSString * const SparkListDidUpdateObjectNotification;

SPARK_EXPORT
NSString * const SparkListDidRemoveObjectNotification;
SPARK_EXPORT
NSString * const SparkListDidRemoveObjectsNotification;

SK_CLASS_EXPORT
@interface SparkList : SparkObject {
  @private
  NSMutableArray *sp_entries;
  
  SparkObjectSet *sp_set; /* weak reference */
  
  id sp_ctxt;
  SparkListFilter sp_filter;
}

- (id)initWithObjectSet:(SparkObjectSet *)library;

- (void)setObjectSet:(SparkObjectSet *)library;

- (void)reload;
- (BOOL)isDynamic;
- (id)filterContext;
- (void)setListFilter:(SparkListFilter)aFilter context:(id)aCtxt;

/* Reload the list, but does not track library change */
- (void)reloadWithFilter:(SparkListFilter)aFilter context:(id)aCtxt;

/* Special initializer */
- (id)initWithSerializedValues:(NSDictionary *)plist
                     objectSet:(SparkObjectSet *)library;

- (NSUInteger)count;
- (NSEnumerator *)objectEnumerator;
- (void)addObject:(SparkObject *)anObject;
- (void)addObjectsFromArray:(NSArray *)anArray;

- (BOOL)containsObject:(SparkObject *)anObject;

- (void)removeObject:(SparkObject *)anObject;
- (void)removeObjectsInArray:(NSArray *)anArray;

/* protected */
- (void)registerNotifications;
- (void)unregisterNotifications;

@end

#pragma mark -
/* Same as Object Set but override deserialization */
@interface SparkListSet : SparkObjectSet {
}
- (SparkObject *)deserialize:(NSDictionary *)plist error:(OSStatus *)error;
@end

/*
 *  SparkList.h
 *  SparkKit
 *
 *  Created by Grayfox on 30/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkObject.h>
#import <SparkKit/SparkObjectSet.h>

typedef BOOL(*SparkListFilter)(SparkObject *, id ctxt);

@interface SparkList : SparkObject {
  @private
  NSMutableArray *sp_entries;
  
  SparkObjectSet *sp_set; /* weak reference */
  
  id sp_ctxt;
  SparkListFilter sp_filter;
  
  struct _sp_slFlags {
    unsigned int builtin:1;
    unsigned int reserved:31;
  } sp_slFlags;
}

- (id)initWithObjectSet:(SparkObjectSet *)library;

- (void)setObjectSet:(SparkObjectSet *)library;

- (void)reload;
- (id)filterContext;
- (void)setListFilter:(SparkListFilter)aFilter context:(id)aCtxt;

/* Special initializer */
- (id)initWithObjectSet:(SparkObjectSet *)library
     serializedValues:(NSDictionary *)plist;

- (unsigned)count;
- (void)addObject:(SparkObject *)anObject;

@end

#pragma mark -
/* Same as Object Set but override deserialization */
@interface SparkListSet : SparkObjectSet {
}
- (SparkObject *)deserialize:(NSDictionary *)plist error:(OSStatus *)error;
@end

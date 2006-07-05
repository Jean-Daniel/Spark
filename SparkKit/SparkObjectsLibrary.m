//
//  SparkObjectsLibrary.m
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkObjectsLibrary.h>

#import <ShadowKit/SKCFContext.h>
#import <SparkKit/SparkLibraryObject.h>

#import <libkern/OSAtomic.h>

//#import <SparkKit/Extension.h>
//#import <SparkKit/SparkLibrary.h>
//#import <SparkKit/SparkConstantes.h>
//#import <SparkKit/SparkActionPlugIn.h>
//#import <SparkKit/SparkSerialization.h>

static NSString * const kSparkLibraryVersionKey = @"SparkVersion";
static NSString * const kSparkLibraryObjectsKey = @"SparkObjects";

NSString * const kSparkNotificationObject = @"SparkNotificationObject";

NSString* const kSparkLibraryWillAddObjectNotification = @"SparkLibraryWillAddObject";
NSString* const kSparkLibraryDidAddObjectNotification = @"SparkLibraryDidAddObject";

NSString* const kSparkLibraryWillUpdateObjectNotification = @"kSparkLibraryWillUpdateObject";
NSString* const kSparkLibraryDidUpdateObjectNotification = @"SparkLibraryDidUpdateObject";

NSString* const kSparkLibraryWillRemoveObjectNotification = @"kSparkLibraryWillRemoveObject";
NSString* const kSparkLibraryDidRemoveObjectNotification = @"SparkLibraryDidRemoveObject";

#define kSparkLibraryVersion2_0		(unsigned int)0x200
static const unsigned int kSparkObjectsLibraryCurrentVersion = kSparkLibraryVersion2_0;

@implementation SparkObjectsLibrary

+ (id)objectsLibraryWithLibrary:(SparkLibrary *)aLibrary {
  return [[[self alloc] initWithLibrary:aLibrary] autorelease];
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary {
  NSParameterAssert(aLibrary);
  if (self = [super init]) {
    [self setLibrary:aLibrary];
    sp_objects = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kSKIntDictionaryKeyCallBacks, &kSKNSObjectDictionaryValueCallBacks);
  }
  return self;
}

- (void)dealloc {
  if (sp_objects)
    CFRelease(sp_objects);
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {Objects: %u}",
    [self class], self, [self count]];
}

#pragma mark -
//- (NSData *)serialize {
//  id error = nil;
//  NSData* data = [NSPropertyListSerialization dataFromPropertyList:[self propertyList]
//                                                            format:SparkLibraryFileFormat
//                                                  errorDescription:&error];
//  if (!data) {
//    NSLog(error);
//    [error release];
//  }
//  return data;
//}

//- (BOOL)loadData:(NSData *)data {
//  NSAssert(sp_library != nil, @"Unable to load library, sp_library cannot be nil");
//  
//  NSString *error;
//  NSPropertyListFormat format;
//  id library;
//  
//  if (_objects)
//    [_objects release];
//  _objects = [[NSMutableDictionary alloc] init];
//  
//  library = [NSPropertyListSerialization propertyListFromData:data
//                                             mutabilityOption:NSPropertyListMutableContainersAndLeaves
//                                                       format:&format
//                                             errorDescription:&error];
//  if(!library) {
//    NSLog(error);
//    [error release];
//    return NO;
//  }
//  id items = nil;
//  if ([library isKindOfClass:[NSDictionary class]]) {
//    _version = [[library objectForKey:kSparkLibraryVersionKey] unsignedIntValue];
//    items = [library objectForKey:kSparkLibraryObjectsKey];
//  } else if ([library isKindOfClass:[NSArray class]]) {
//    _version = 0;
//    items = library;
//  } else {
//    return NO;
//  }
//  [self loadObjects:items];
//  
//  return YES;
//}

- (SparkLibrary *)library {
  return sp_library;
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  sp_library = aLibrary;
}

#pragma mark -
- (UInt32)count {
  return sp_objects ? CFDictionaryGetCount(sp_objects) : 0;
}

- (NSArray *)objects {
  return [(id)sp_objects allValues];
}
- (NSEnumerator *)objectEnumerator {
  return [(id)sp_objects objectEnumerator];
}

- (BOOL)containsObject:(SparkLibraryObject *)object {
  return object ? CFDictionaryContainsKey(sp_objects, (void *)[object uid]) : NO;
}

- (id)objectWithId:(UInt32)uid {
  return uid ? (id)CFDictionaryGetValue(sp_objects, (void *)uid) : nil;
}

- (NSArray *)objectsWithIds:(NSIndexSet *)uids {
  return nil;
//  return [sp_objects objectsForKeys:uids notFoundMarker:[NSNull null]];
}

#pragma mark -
- (BOOL)addObject:(SparkLibraryObject *)object {
  NSParameterAssert(object != nil);
  @try {
    // Will add object
    if (![self containsObject:object]) {
      if (![object uid]) {
        [object setUID:[self nextUID]];
      } else if ([object uid] > sp_uid) {
        sp_uid = [object uid];
      }
      CFDictionarySetValue(sp_objects, (void *)[object uid], object);
      [object setLibrary:[self library]];
      // Did add
      return YES;
    } else { /* If object already in Library */
      [self updateObject:object];
    }
  }
  @catch (id exception) {
    SKLogException(exception);
  }
  return NO;
}
- (int)addObjects:(NSArray *)objects {
  int count = 0;
  SparkLibraryObject *item = nil;
  NSEnumerator *items = [objects objectEnumerator];
  while (item = [items nextObject]) {
    count += ([self addObject:item]) ? 1 : 0;
  }
  return count;
}

#pragma mark -
- (BOOL)updateObject:(SparkLibraryObject *)object {
  NSParameterAssert([self containsObject:object]);
  SparkLibraryObject *old = [self objectWithId:[object uid]];
  if (old && (old != object)) {
    // Will update
    CFDictionarySetValue(sp_objects, (void *)[object uid], object);
    [object setLibrary:[self library]];
    // Did update
    return YES;
  }
  return NO;
}

#pragma mark -
- (void)removeObject:(SparkLibraryObject *)object {
  if (object && [self containsObject:object]) {
    [object retain];
    // Will remove
    [object setLibrary:nil];
    CFDictionaryRemoveValue(sp_objects, (void *)[object uid]);
    // Did remove
    [object release];
  }
}
- (void)removeObjects:(NSArray *)objects {
  SparkLibraryObject *item = nil;
  NSEnumerator *items = [objects objectEnumerator];
  while (item = [items nextObject]) {
    [self removeObject:item];
  }
}

//#pragma mark -
//- (void)loadObjects:(NSArray *)newObjects {
//  id items = [newObjects objectEnumerator];
//  id item;
//  while (item = [items nextObject]) {
//    [self loadObject:item];
//  }
//}

//- (void)loadObject:(NSMutableDictionary *)item {
//  id object = nil;
//  @try {
//    [item setObject:[self library] forKey:@"_SparkLibrary_"];
//    if (object = SparkDeserializeObject(item)) {
//      [self addObject:object];
//    } else {
//      DLog(@"Unable to load object: %@", item);
//    }
//  }
//  @catch (id exception) {
//    SKLogException(exception);
//    [object release];
//  }
//}

//#pragma mark -
//- (id)propertyList {
//  NSMutableDictionary *plist = [NSMutableDictionary dictionary];
//  NSMutableArray *objects = [NSMutableArray array];
//  id items = [[sp_objects allValues] objectEnumerator];
//  id item;
//  while (item = [items nextObject]) {
//    @try {
//      [objects addObject:SparkSerializeObject(item)];
//    }
//    @catch (id exception) {
//      NSLog(@"Unable to save object: %@", item);
//      SKLogException(exception);
//    }
//  }
//  [plist setObject:objects forKey:kSparkLibraryObjectsKey];
//  [plist setObject:SKUInt([self libraryVersion]) forKey:kSparkLibraryVersionKey];
//  return plist;
//}

#pragma mark -
#pragma mark UID Management
- (UInt32)nextUID {
  return OSAtomicIncrement32((int32_t *)&sp_uid);
}

- (UInt32)currentUID {
  return sp_uid;
}

- (void)setCurrentUID:(UInt32)uid {
  sp_uid = uid;
}
#pragma mark -
- (void)postNotification:(NSString *)name withObject:(id)object {
  if ([self library]) {
    [[NSNotificationCenter defaultCenter] postNotificationName:name
                                                        object:[self library]
                                                      userInfo:[NSDictionary dictionaryWithObject:object
                                                                                           forKey:kSparkNotificationObject]];
  }
}

@end

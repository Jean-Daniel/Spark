//
//  SparkObjectsLibrary.m
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkObjectsLibrary.h>

#import <SparkKit/Extension.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkConstantes.h>
#import <SparkKit/SparkActionPlugIn.h>
#import <SparkKit/SparkSerialization.h>

static NSString * const kSparkLibraryVersionKey = @"SparkVersion";
static NSString * const kSparkLibraryObjectsKey = @"SparkObjects";

NSString * const kSparkNotificationObject = @"SparkNotificationObject";

__inline__ id SparkNotificationObject(NSNotification *aNotification) {
  return [[aNotification userInfo] objectForKey:kSparkNotificationObject];
}

#define kSparkLibraryVersion2_0		(unsigned int)0x200
static const unsigned int kSparkObjectsLibraryCurrentVersion = kSparkLibraryVersion2_0;

@implementation SparkObjectsLibrary

- (unsigned int)libraryVersion {
  return kSparkObjectsLibraryCurrentVersion;
}

+ (id)objectsLibraryWithLibrary:(SparkLibrary *)aLibrary {
  return [[[self alloc] initWithLibrary:aLibrary] autorelease];
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary {
  if (!aLibrary) {
    [self release];
    self = nil;
  } else if (self = [super init]) {
    [self setLibrary:aLibrary];
    _version = [self libraryVersion];
    _objects = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)dealloc {
  [_objects release];
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {version: %u count: %u}",
    NSStringFromClass([self class]), self,
    [self libraryVersion], [_objects count]];
}

#pragma mark -
- (NSData *)serialize {
  id error = nil;
  NSData* data = [NSPropertyListSerialization dataFromPropertyList:[self propertyList]
                                                            format:SparkLibraryFileFormat
                                                  errorDescription:&error];
  if (!data) {
    NSLog(error);
    [error release];
  }
  return data;
}

- (BOOL)loadData:(NSData *)data {
  NSAssert(_library != nil, @"Unable to load library, _library cannot be nil");
  
  NSString *error;
  NSPropertyListFormat format;
  id library;
  
  if (_objects)
    [_objects release];
  _objects = [[NSMutableDictionary alloc] init];
  
  library = [NSPropertyListSerialization propertyListFromData:data
                                             mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                       format:&format
                                             errorDescription:&error];
  if(!library) {
    NSLog(error);
    [error release];
    return NO;
  }
  id items = nil;
  if ([library isKindOfClass:[NSDictionary class]]) {
    _version = [[library objectForKey:kSparkLibraryVersionKey] unsignedIntValue];
    items = [library objectForKey:kSparkLibraryObjectsKey];
  } else if ([library isKindOfClass:[NSArray class]]) {
    _version = 0;
    items = library;
  } else {
    return NO;
  }
  [self loadObjects:items];
  
  return YES;
}

- (SparkLibrary *)library {
  return _library;
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  _library = aLibrary;
}

#pragma mark -
- (unsigned)count {
  return [_objects count];
}

- (NSArray*)objects {
  return [_objects allValues];
}
- (NSEnumerator *)objectEnumerator {
  return [_objects objectEnumerator];
}

- (BOOL)containsObject:(id<SparkLibraryObject>)object {
  return (object && [object uid]) ? [_objects objectForKey:[object uid]] != nil : NO;
}

- (id)objectWithId:(id)uid {
  return (uid) ? [_objects objectForKey:uid] : nil;
}

- (NSArray *)objectsWithIds:(NSArray *)ids {
  return [_objects objectsForKeys:ids notFoundMarker:[NSNull null]];
}

#pragma mark -
- (BOOL)addObject:(id<SparkLibraryObject>)object {
  NSParameterAssert(object != nil);
  @try {
    if (![self containsObject:object]) {
      if (![object uid]) {
        [object setUid:SKUInt([self nextUid])];
      } else if ([[object uid] unsignedIntValue] > _uid) {
        _uid = [[object uid] unsignedIntValue];
      }
      [_objects setObject:object forKey:[object uid]];
      [object setLibrary:[self library]];
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
- (int)addObjects:(NSArray *)newObjects {
  id items = [newObjects objectEnumerator];
  id item;
  int count = 0;
  while (item = [items nextObject]) {
    count += ([self addObject:item]) ? 1 : 0;
  }
  return count;
}

#pragma mark -
- (BOOL)updateObject:(id<SparkLibraryObject>)object {
  NSParameterAssert([self containsObject:object]);
  id old = [self objectWithId:[object uid]];
  if (old && (old != object)) {
    [_objects setObject:object forKey:[object uid]];
    [object setLibrary:[self library]];
    return YES;
  }
  return NO;
}

#pragma mark -
- (void)removeObject:(id<SparkLibraryObject>)object {
  if (object) {
    [_objects removeObjectForKey:[object uid]];
    [object setLibrary:nil];
  }
}
- (void)removeObjects:(NSArray *)newObjects {
  id items = [newObjects objectEnumerator];
  id item;
  while (item = [items nextObject]) {
    [self removeObject:item];
  }
}

#pragma mark -
- (void)loadObjects:(NSArray *)newObjects {
  id items = [newObjects objectEnumerator];
  id item;
  while (item = [items nextObject]) {
    [self loadObject:item];
  }
}

- (void)loadObject:(NSMutableDictionary *)item {
  id object = nil;
  @try {
    [item setObject:[self library] forKey:@"_SparkLibrary_"];
    if (object = SparkDeserializeObject(item)) {
      [self addObject:object];
    } else {
      DLog(@"Unable to load object: %@", item);
    }
  }
  @catch (id exception) {
    SKLogException(exception);
    [object release];
  }
}

#pragma mark -
- (unsigned int)version {
  return _version;
}

- (id)propertyList {
  NSMutableDictionary *plist = [NSMutableDictionary dictionary];
  NSMutableArray *objects = [NSMutableArray array];
  id items = [[_objects allValues] objectEnumerator];
  id item;
  while (item = [items nextObject]) {
    @try {
      [objects addObject:SparkSerializeObject(item)];
    }
    @catch (id exception) {
      NSLog(@"Unable to save object: %@", item);
      SKLogException(exception);
    }
  }
  [plist setObject:objects forKey:kSparkLibraryObjectsKey];
  [plist setObject:SKUInt([self libraryVersion]) forKey:kSparkLibraryVersionKey];
  return plist;
}

#pragma mark -
#pragma mark UID Management
- (unsigned)nextUid {
  return ++_uid;
}

- (unsigned int)currentId {
  return _uid;
}

- (void)setCurrentUid:(unsigned int)uid {
  _uid = uid;
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

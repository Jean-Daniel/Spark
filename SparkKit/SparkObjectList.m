//
//  SparkObjectList.m
//  SparkKit
//
//  Created by Fox on 01/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkObjectList.h>

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/ShadowMacros.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKAppKitExtensions.h>

#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectsLibrary.h>

static NSString * kSparkObjectListKeys = @"ObjectList";

@interface SparkObjectList (PrivateMethods)
- (NSArray *)objectsUid;
@end

@implementation SparkObjectList

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  SparkObjectList* copy = [super copyWithZone:zone];
  [copy->_objects addObjectsFromArray:_objects];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:[self objectsUid] forKey:kSparkObjectListKeys];
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    _objects = [[NSMutableArray alloc] init];
    id sharedLibrary = [self contentsLibrary];
    id uids = [[coder decodeObjectForKey:kSparkObjectListKeys] objectEnumerator];
    [_objects addObjectsFromArray:[sharedLibrary objectsWithIds:uids]];
    [_objects removeObject:[NSNull null]]; /* ==> Remove key not found placeholder */
  }
  return self;
}

#pragma mark Serialization.
- (id)initFromPropertyList:(id)plist {
  if (self = [super initFromPropertyList:plist]) {
    _objects = [[NSMutableArray alloc] init];
    id sharedLibrary = [self contentsLibrary];
    id uids = [plist objectForKey:kSparkObjectListKeys];
    [_objects addObjectsFromArray:[sharedLibrary objectsWithIds:uids]];
    [_objects removeObject:[NSNull null]]; /* ==> Remove key not found placeholder */
  }
  return self;
}

- (NSMutableDictionary *)propertyList {
  NSMutableDictionary *dico = [super propertyList];
  [dico setObject:[self objectsUid] forKey:kSparkObjectListKeys];
  return dico;
}

#pragma mark -
+ (NSString *)defaultIconName {
  return @"SparkList";
}

#pragma mark -
+ (id)list {
  return [[[self alloc] init] autorelease];
}
+ (id)listWithName:(NSString *)name {
  return [[[self alloc] initWithName:name] autorelease];
}
+ (id)listWithName:(NSString *)name icon:(NSImage *)icon {
  return [[[self alloc] initWithName:name icon:icon] autorelease];
}
+ (id)listFromPropertyList:(id)plist {
  return [[[self alloc] initFromPropertyList:plist] autorelease];
}

- (id)init {
  if (self = [super init]) {
    _objects = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  [_objects release];
  [super dealloc];
}

- (id)objectsLibrary {
  return [[self library] listLibrary];
}

#pragma mark -
- (SparkObjectsLibrary *)contentsLibrary {
  return nil;
}
- (Class)contentType {
  return [SparkLibraryObject class];
}

- (NSArray *)objects {
  return [NSArray arrayWithArray:_objects];
}

- (unsigned)count {
  return [_objects count];
}

- (unsigned)indexOfObject:(SparkLibraryObject *)object {
  NSParameterAssert(object != nil);
  NSParameterAssert([object uid] != nil);
  unsigned index;
  for (index = 0; index < [_objects count]; index++) {
    if ([object isEqualToLibraryObject:[_objects objectAtIndex:index]]) {
      return index;
    }
  }
  return NSNotFound;
}

- (BOOL)containsObject:(SparkLibraryObject *)object {  
  return [self indexOfObject:object] != NSNotFound;
}

- (void)addObject:(SparkLibraryObject *)anObject {
  unsigned idx = NSNotFound;
  if ([anObject uid] == nil) {
    [[self contentsLibrary] addObject:anObject];
  } /* AddObject notification is called and the object can be added
      to the current list so we check if it is the case */
  idx = [self indexOfObject:anObject];
  if (NSNotFound != idx) {
    if ([_objects objectAtIndex:idx] != anObject)
      [_objects replaceObjectAtIndex:idx withObject:anObject];
  } else {
    [_objects addObject:anObject];
  }
}

- (void)addObjects:(NSArray *)objects {
  id items = [objects objectEnumerator];
  id object;
  while (object = [items nextObject]) {
    [self addObject:object];
  }
}

- (void)addObjectsWithUids:(NSArray *)objects {
  [self addObjects:[[self contentsLibrary] objectsWithIds:objects]];
}

- (void)removeObject:(SparkLibraryObject *)object {
  int index = [self indexOfObject:object];
  if (NSNotFound != index)
    [_objects removeObjectAtIndex:index];
}

- (void)removeObjects:(NSArray *)objects {
  id items = [objects objectEnumerator];
  id object;
  while (object = [items nextObject]) {
    [self removeObject:object];
  }
}

#pragma mark -
#pragma mark Indexes Methods
- (void)insertObject:(SparkLibraryObject *)anObject atIndex:(unsigned)index {
  unsigned idx = NSNotFound;
  if ([anObject uid] == nil) {
    [[self contentsLibrary] addObject:anObject];
  }
  idx = [self indexOfObject:anObject];
  if (NSNotFound != idx) {
    if ([_objects objectAtIndex:idx] != anObject)
      [_objects replaceObjectAtIndex:idx withObject:anObject];
  } else {
    [_objects insertObject:anObject atIndex:index];
  }
}

- (void)replaceObjectAtIndex:(unsigned)index withObject:(SparkLibraryObject *)object {
  [_objects replaceObjectAtIndex:index withObject:object];
}

- (void)removeObjectAtIndex:(unsigned)index {
  [_objects removeObjectAtIndex:index];
}


#pragma mark -
- (NSImage *)icon {
  if ([super icon])
    return [super icon];
  else
    return [NSImage imageNamed:[[self class] defaultIconName] inBundle:SKCurrentBundle()];
}

#pragma mark -
- (BOOL)isEditable {
  return YES;
}

- (BOOL)isCustomizable {
  return YES;
}

#pragma mark -
- (NSArray *)objectsUid {
  NSMutableArray *keys = [[NSMutableArray alloc] initWithCapacity:[self count]];
  id objects = [_objects objectEnumerator];
  id object;
  while (object = [objects nextObject]) {
    [keys addObject:[object uid]];
  }
  return [keys autorelease];
}

@end

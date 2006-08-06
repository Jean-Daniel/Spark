/*
 *  SparkObjectSet.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkObjectSet.h>

#import <libkern/OSAtomic.h>
#import <ShadowKit/SKCFContext.h>
#import <ShadowKit/SKEnumerator.h>
#import <ShadowKit/SKSerialization.h>
#import <ShadowKit/SKAppKitExtensions.h>

#import <SparkKit/SparkLibrary.h>

/* Notifications */
NSString * const kSparkNotificationObject = @"SparkNotificationObject";
NSString * const kSparkNotificationUpdatedObject = @"SparkUpdatedObject";

NSString* const kSparkLibraryWillAddObjectNotification = @"SparkLibraryWillAddObject";
NSString* const kSparkLibraryDidAddObjectNotification = @"SparkLibraryDidAddObject";

NSString* const kSparkLibraryWillUpdateObjectNotification = @"kSparkLibraryWillUpdateObject";
NSString* const kSparkLibraryDidUpdateObjectNotification = @"SparkLibraryDidUpdateObject";

NSString* const kSparkLibraryWillRemoveObjectNotification = @"kSparkLibraryWillRemoveObject";
NSString* const kSparkLibraryDidRemoveObjectNotification = @"SparkLibraryDidRemoveObject";

#define kSparkLibraryVersion2_0		(UInt32)0x200
static
const unsigned int kSparkObjectSetCurrentVersion = kSparkLibraryVersion2_0;

/* Library Keys */
static
NSString * const kSparkLibraryVersionKey = @"SparkVersion";
static
NSString * const kSparkObjectsKey = @"SparkObjects";

NSComparisonResult SparkObjectCompare(SparkObject *obj1, SparkObject *obj2, void *source) {
  if ([obj1 uid] < kSparkLibraryReserved) {
    if ([obj2 uid] < kSparkLibraryReserved) {
      /* obj1 and obj2 are reserved objects */
      return [obj1 uid] - [obj2 uid];
    } else {
      /* obj1 reserved and obj2 standard */
      return NSOrderedAscending;
    }
  } else if ([obj2 uid] < kSparkLibraryReserved) {
    /* obj2 reserved and obj1 standard */
    return NSOrderedDescending;
  } else {
    /* obj1 and obj2 are standard */
    return [[obj1 name] caseInsensitiveCompare:[obj2 name]];
  }
}

#pragma mark -
@implementation SparkObjectSet

+ (id)objectsLibraryWithLibrary:(SparkLibrary *)aLibrary {
  return [[[self alloc] initWithLibrary:aLibrary] autorelease];
}

- (id)init {
  if (self = [self initWithLibrary:nil]) {
  }
  return self;
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary {
  NSParameterAssert(aLibrary);
  if (self = [super init]) {
    [self setLibrary:aLibrary];
    sp_uid = kSparkLibraryReserved;
    sp_objects = NSCreateMapTable(NSIntMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
  }
  return self;
}

- (void)dealloc {
  if (sp_objects)
    NSFreeMapTable(sp_objects);
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {Objects: %u}",
    [self class], self, [self count]];
}

#pragma mark -
- (SparkLibrary *)library {
  return sp_library;
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  sp_library = aLibrary;
}

#pragma mark -
- (UInt32)count {
  return sp_objects ? NSCountMapTable(sp_objects) : 0;
}

- (NSArray *)objects {
  return sp_objects ? NSAllMapTableValues(sp_objects) : [NSArray array];
}
- (NSEnumerator *)objectEnumerator {
  return SKMapTableEnumerator(sp_objects, NO);
}

- (BOOL)containsObject:(SparkObject *)object {
  return object ? NSMapMember(sp_objects, (void *)[object uid], NULL, NULL) : NO;
}

- (id)objectForUID:(UInt32)uid {
  return uid ? (id)NSMapGet(sp_objects, (void *)uid) : nil;
}

#pragma mark -
- (void)postNotification:(NSString *)name object:(SparkObject *)object {
  [[NSNotificationCenter defaultCenter] postNotificationName:name
                                                      object:self
                                                    userInfo:object ? [NSDictionary dictionaryWithObject:object
                                                                                                  forKey:kSparkNotificationObject] : nil];
}

- (BOOL)addObject:(SparkObject *)object {
  NSParameterAssert(object != nil);
  @try {
    if (![self containsObject:object]) {
      if (![object uid]) {
        [object setUID:[self nextUID]];
      } else if ([object uid] > sp_uid) {
        sp_uid = [object uid];
      }
      // Will add object
      [self postNotification:kSparkLibraryWillAddObjectNotification object:object];
      NSMapInsert(sp_objects, (void *)[object uid], object);
      [object setLibrary:[self library]];
      // Did add object
      [self postNotification:kSparkLibraryDidAddObjectNotification object:object];
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
- (int)addObjectsFromArray:(NSArray *)objects {
  int count = 0;
  SparkObject *item = nil;
  NSEnumerator *items = [objects objectEnumerator];
  while (item = [items nextObject]) {
    count += ([self addObject:item]) ? 1 : 0;
  }
  return count;
}

#pragma mark -
- (BOOL)updateObject:(SparkObject *)object {
  NSParameterAssert([self containsObject:object]);
  SparkObject *old = [self objectForUID:[object uid]];
  if (old && (old != object)) {
    // Will update
    [self postNotification:kSparkLibraryWillUpdateObjectNotification object:old];
    NSMapInsert(sp_objects, (void *)[object uid], object);
    [object setLibrary:[self library]];
    // Did update
    [[NSNotificationCenter defaultCenter] postNotificationName:kSparkLibraryDidUpdateObjectNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        object, kSparkNotificationObject,
                                                        old, kSparkNotificationUpdatedObject, nil]];
    return YES;
  }
  return NO;
}

#pragma mark -
- (void)removeObject:(SparkObject *)object {
  if (object && [self containsObject:object]) {
    [object retain];
    // Will remove
    [self postNotification:kSparkLibraryWillRemoveObjectNotification object:object];
    [object setLibrary:nil];
    NSMapRemove(sp_objects, (void *)[object uid]);
    // Did remove
    [self postNotification:kSparkLibraryDidRemoveObjectNotification object:object];
    [object release];
  }
}
- (void)removeObjectsInArray:(NSArray *)objects {
  SparkObject *item = nil;
  NSEnumerator *items = [objects objectEnumerator];
  while (item = [items nextObject]) {
    [self removeObject:item];
  }
}

- (NSDictionary *)serialize:(SparkObject *)anObject error:(OSStatus *)error {
  return SKSerializeObject(anObject, error);
}

- (NSFileWrapper *)fileWrapper:(NSError **)outError {
  NSMutableArray *objects = [[NSMutableArray alloc] init];
  NSMutableDictionary *plist = [[NSMutableDictionary alloc] init];
  [plist setObject:SKUInt(kSparkObjectSetCurrentVersion) forKey:kSparkLibraryVersionKey];
  
  SparkObject *object;
  NSEnumerator *enumerator = [self objectEnumerator];
  while (object = [enumerator nextObject]) {
    NSDictionary *serialize = [self serialize:object error:NULL];
    if (serialize && [NSPropertyListSerialization propertyList:serialize isValidForFormat:SparkLibraryFileFormat]) {
      [objects addObject:serialize];
    } else {
      DLog(@"Error while serializing object: %@", object);
    }
  }
  
  [plist setObject:objects forKey:kSparkObjectsKey];
  [objects release];
  
  NSData *data = [NSPropertyListSerialization dataFromPropertyList:plist format:SparkLibraryFileFormat errorDescription:nil];
  [plist release];
  
  return [[[NSFileWrapper alloc] initRegularFileWithContents:data] autorelease];
}

- (SparkObject *)deserialize:(NSDictionary *)plist error:(OSStatus *)error {
  return SKDeserializeObject(plist, error);
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError {
  NSData *data = [fileWrapper regularFileContents];
  require(data, bail);
  
  NSDictionary *plist = [NSPropertyListSerialization propertyListFromData:data 
                                                         mutabilityOption:NSPropertyListImmutable
                                                                   format:nil errorDescription:nil];
  require(plist, bail);
  
  NSArray *objects = [plist objectForKey:kSparkObjectsKey];
  require(objects, bail);
  
  NSDictionary *serialize;
  NSEnumerator *enumerator = [objects objectEnumerator];
  while (serialize = [enumerator nextObject]) {
    OSStatus err;
    SparkObject *object = [self deserialize:serialize error:&err];
    /* If class not found */
    if (!object && kSKClassNotFoundError == err) {
      object = [[SparkPlaceHolder alloc] initWithSerializedValues:serialize];
      [object autorelease];
    }
    if (object) {
      [self addObject:object];
    } else {
      DLog(@"Invalid object: %@", serialize);
    }
  }
  
  return YES;
bail:
  return NO;
}

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

@end

#pragma mark -
@implementation SparkPlaceHolder

static NSImage *__SparkWarningImage = nil;
+ (void)initialize {
  if ([SparkPlaceHolder class] == self) {
    __SparkWarningImage = [NSImage imageNamed:@"Warning" inBundle:SKCurrentBundle()];
  }
}

- (id)initWithName:(NSString *)name icon:(NSImage *)icon {
  if (self = [super initWithName:name icon:nil]) {
    [self setIcon:__SparkWarningImage];
  }
  return self;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    sp_plist = [plist copy];
  }
  return self;
}

- (void)dealloc {
  [sp_plist release];
  [super dealloc];
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if (sp_plist) {
    [plist addEntriesFromDictionary:sp_plist];
    return YES;
  }
  return NO;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
  DLog(@"-[%@ %@]", [self class], NSStringFromSelector([invocation selector]));
  if ([[invocation methodSignature] methodReturnLength] > 0) {
    char buffer[32];
    bzero(buffer, 32);
    [invocation setReturnValue:buffer];
  }
}

@class SparkAction, SparkTrigger, SparkList;
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
  if ([self respondsToSelector:sel])
    return [super methodSignatureForSelector:sel];
  if ([[SparkAction class] instancesRespondToSelector:sel])
    return [[SparkAction class] instanceMethodSignatureForSelector:sel];
  if ([[SparkTrigger class] instancesRespondToSelector:sel])
    return [[SparkTrigger class] instanceMethodSignatureForSelector:sel];
  if ([[SparkApplication class] instancesRespondToSelector:sel])
    return [[SparkApplication class] instanceMethodSignatureForSelector:sel];
  if ([[SparkList class] instancesRespondToSelector:sel])
    return [[SparkList class] instanceMethodSignatureForSelector:sel];
  return nil;
}

//+ (BOOL)respondsToSelector:(SEL)aSelector {
//}

@end

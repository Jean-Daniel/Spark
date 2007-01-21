/*
 *  SparkObjectSet.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkFunctions.h>
#import <SparkKit/SparkIconManager.h>

#import <libkern/OSAtomic.h>
#import <ShadowKit/SKCFContext.h>
#import <ShadowKit/SKEnumerator.h>
#import <ShadowKit/SKSerialization.h>
#import <ShadowKit/SKAppKitExtensions.h>

/* Notifications */
NSString* const SparkObjectSetWillAddObjectNotification = @"SparkObjectSetWillAddObject";
NSString* const SparkObjectSetDidAddObjectNotification = @"SparkObjectSetDidAddObject";

NSString* const SparkObjectSetWillUpdateObjectNotification = @"SparkObjectSetWillUpdateObject";
NSString* const SparkObjectSetDidUpdateObjectNotification = @"SparkObjectSetDidUpdateObject";

NSString* const SparkObjectSetWillRemoveObjectNotification = @"SparkObjectSetWillRemoveObject";
NSString* const SparkObjectSetDidRemoveObjectNotification = @"SparkObjectSetDidRemoveObject";

#define kSparkObjectSetVersion_2_0		0x200UL
#define kSparkObjectSetVersion_2_1		0x201UL

static
const unsigned int kSparkObjectSetCurrentVersion = kSparkObjectSetVersion_2_1;

/* Library Keys */
static
NSString * const kSparkObjectSetVersionKey = @"SparkVersion";
static
NSString * const kSparkObjectSetObjectsKey = @"SparkObjects";

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

- (NSUndoManager *)undoManager {
  return [[self library] undoManager];
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
  return object ? [self containsObjectWithUID:[object uid]] : NO;
}
- (BOOL)containsObjectWithUID:(UInt32)uid {
  return NSMapMember(sp_objects, (void *)uid, NULL, NULL);
}

- (id)objectForUID:(UInt32)uid {
  return uid ? (id)NSMapGet(sp_objects, (void *)uid) : nil;
}

#pragma mark -
- (void)sp_checkUID:(SparkObject *)anObject {
  if (![anObject uid]) {
    [anObject setUID:[self nextUID]];
  } else if ([anObject uid] > sp_uid) {
    sp_uid = [anObject uid];
  }
}

- (void)sp_addObject:(SparkObject *)object {
  NSMapInsert(sp_objects, (void *)[object uid], object);
  [object setLibrary:[self library]];
}

- (BOOL)addObject:(SparkObject *)object {
  NSParameterAssert(object != nil);
  NSParameterAssert(![self containsObject:object]);
  @try {
    if (![self containsObject:object]) {
    {
      UInt32 uid = [object uid], luid = [self currentUID];
      /* Update Object UID */
      [self sp_checkUID:object];
      /* Check change and prepare undo */
      if (uid != [object uid])
        [[[self undoManager] prepareWithInvocationTarget:object] setUID:uid];
      if (luid != [self currentUID])
        [[[self undoManager] prepareWithInvocationTarget:self] setCurrentUID:luid];
      [[self undoManager] registerUndoWithTarget:self selector:@selector(removeObject:) object:object];
    } 
      // Will add object
      SparkLibraryPostNotification([self library], SparkObjectSetWillAddObjectNotification, self, object);
      [self sp_addObject:object];
      // Did add object
      SparkLibraryPostNotification([self library], SparkObjectSetDidAddObjectNotification, self, object);
      return YES;
    }
  } @catch (id exception) {
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
    /* Register undo => [self updateObject:old]; */
    [[self undoManager] registerUndoWithTarget:self selector:@selector(updateObject:) object:old];
    
    // Will update
    SparkLibraryPostUpdateNotification([self library], SparkObjectSetWillUpdateObjectNotification, self, old, object);
    // Update
    [old setLibrary:nil];
    NSMapInsert(sp_objects, (void *)[object uid], object);
    [object setLibrary:[self library]];
    // Did update
    SparkLibraryPostUpdateNotification([self library], SparkObjectSetDidUpdateObjectNotification, self, old, object);
    return YES;
  }
  return NO;
}

#pragma mark -
- (void)removeObject:(SparkObject *)object {
  if (object && [self containsObject:object]) {
    /* Register undo => [self addObject:object]; */
    [[self undoManager] registerUndoWithTarget:self selector:@selector(addObject:) object:object];
    
    [object retain];
    // Will remove
    SparkLibraryPostNotification([self library], SparkObjectSetWillRemoveObjectNotification, self, object);
    // Remove
    [object setLibrary:nil];
    NSMapRemove(sp_objects, (void *)[object uid]);
    // Did remove
    SparkLibraryPostNotification([self library], SparkObjectSetDidRemoveObjectNotification, self, object);
    
    [object release];
  }
}
- (void)removeObjectWithUID:(UInt32)uid {
  SparkObject *object = [self objectForUID:uid];
  if (object)
    [self removeObject:object];
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
  [plist setObject:SKUInt(kSparkObjectSetCurrentVersion) forKey:kSparkObjectSetVersionKey];
  
  SparkObject *object;
  OSStatus err = noErr;
  NSEnumerator *enumerator = [self objectEnumerator];
  while (object = [enumerator nextObject]) {
    NSDictionary *serialize = [self serialize:object error:&err];
    if (serialize && [NSPropertyListSerialization propertyList:serialize isValidForFormat:SparkLibraryFileFormat]) {
      [objects addObject:serialize];
    } else {
      DLog(@"Error while serializing object: %@", object);
      if (noErr != err && outError)
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
    }
  }
  
  [plist setObject:objects forKey:kSparkObjectSetObjectsKey];
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
  
  /* Remove all */
  SparkObject *sobject = nil;
  NSMapEnumerator sobjects = NSEnumerateMapTable(sp_objects);
  while (NSNextMapEnumeratorPair(&sobjects, NULL, (void **)&sobject)) {
    [sobject setLibrary:nil];
  }
  NSEndMapTableEnumeration(&sobjects);
  
  /* Reset map and uid */
  NSResetMapTable(sp_objects);
  sp_uid = kSparkLibraryReserved;
  
  NSDictionary *plist = [NSPropertyListSerialization propertyListFromData:data 
                                                         mutabilityOption:NSPropertyListImmutable
                                                                   format:nil errorDescription:nil];
  require(plist, bail);
  
  UInt32 version = [[plist objectForKey:kSparkObjectSetVersionKey] unsignedIntValue];
  /* Update object set */
  SparkIconManager *icons = nil;
  if (version < kSparkObjectSetVersion_2_1 && SparkGetCurrentContext() == kSparkEditorContext)
      icons = [[self library] iconManager];
  
  NSArray *objects = [plist objectForKey:kSparkObjectSetObjectsKey];
  require(objects, bail);
  
  /* Disable undo */
  [[self undoManager] disableUndoRegistration];
  
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
    if (object && ![self containsObject:object]) {
      /* Avoid notifications */
      [self sp_checkUID:object];
      [self sp_addObject:object];
      
      /* Update old set */
      if (icons && [object hasIcon] && [object shouldSaveIcon]) {
        [icons setIcon:[object icon] forObject:object];
      }
    } else {
      DLog(@"Invalid object: %@", serialize);
    }
  }
  
  /* enable undo */
  [[self undoManager] enableUndoRegistration];
  
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
    __SparkWarningImage = [[NSImage imageNamed:@"Warning" inBundle:SKCurrentBundle()] retain];
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

#pragma mark -
- (NSDictionary *)values {
  return sp_plist;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if (sp_plist) {
    [plist addEntriesFromDictionary:sp_plist];
    return YES;
  }
  return NO;
}

- (BOOL)shouldSaveIcon {
  return NO;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
  DLog(@"-[%@ %@]", [self class], NSStringFromSelector([invocation selector]));
  if ([[invocation methodSignature] methodReturnLength] > 0) {
    char buffer[32];
    bzero(buffer, 32);
    /* setReturnValue auto compute the value size */
    [invocation setReturnValue:buffer];
  }
}

@class SparkApplication, SparkAction, SparkTrigger, SparkList;
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

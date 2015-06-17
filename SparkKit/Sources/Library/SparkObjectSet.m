/*
 *  SparkObjectSet.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkFunctions.h>
#import <SparkKit/SparkIconManager.h>

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkApplication.h>

#import <WonderBox/WBEnumerator.h>
#import <WonderBox/WBSerialization.h>
#import <WonderBox/NSImage+WonderBox.h>

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
const NSUInteger kSparkObjectSetCurrentVersion = kSparkObjectSetVersion_2_1;

/* Library Keys */
static
NSString * const kSparkObjectSetVersionKey = @"SparkVersion";

static
NSString * const kSparkObjectSetObjectsKey = @"SparkObjects";

NSComparisonResult SparkObjectCompare(SparkObject *obj1, SparkObject *obj2, void *source) {
  if ([obj1 uid] < kSparkLibraryReserved) {
    if ([obj2 uid] < kSparkLibraryReserved) {
      /* obj1 and obj2 are reserved objects */
      return (NSComparisonResult)[obj1 uid] - [obj2 uid];
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
@implementation SparkObjectSet {
@private
  SparkUID sp_uid;
  NSMutableDictionary *sp_objects;
}

+ (instancetype)objectsSetWithLibrary:(SparkLibrary *)aLibrary {
  return [[self alloc] initWithLibrary:aLibrary];
}

- (instancetype)init {
  if (self = [self initWithLibrary:nil]) {
  }
  return self;
}

- (instancetype)initWithLibrary:(SparkLibrary *)aLibrary {
  NSParameterAssert(aLibrary);
  if (self = [super init]) {
    _library = aLibrary;
    sp_uid = kSparkLibraryReserved;
    sp_objects = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {Objects: %lu}",
    [self class], self, (unsigned long)[self count]];
}

#pragma mark -

- (void)setLibrary:(SparkLibrary *)aLibrary {
  if (_library != aLibrary) {
    /* Invalidate all entries */
    [[self objects] makeObjectsPerformSelector:@selector(setLibrary:)
                                    withObject:nil];
    [sp_objects removeAllObjects];
    _library = aLibrary;
  }
}

- (NSUndoManager *)undoManager {
  return self.library.undoManager;
}

#pragma mark -
- (NSUInteger)count {
  return sp_objects.count;
}

- (NSArray *)objects {
  return [sp_objects allValues];
}

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, BOOL *stop))block {
  [sp_objects enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    block(obj, stop);
  }];
}

- (BOOL)containsObject:(SparkObject *)object {
  return object ? [self containsObjectWithUID:object.uid] : NO;
}

- (BOOL)containsObjectWithUID:(SparkUID)uid {
  return [sp_objects objectForKey:@(uid)] != nil;
}

- (id)objectWithUID:(SparkUID)uid {
  return [sp_objects objectForKey:@(uid)];
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
  [sp_objects setObject:object forKey:@(object.uid)];
  [object setLibrary:[self library]];
}

- (BOOL)addObject:(SparkObject *)object {
  NSParameterAssert(object != nil);
  NSParameterAssert(![self containsObject:object]);
  @try {
    if (![self containsObject:object]) {
      // Will add object
      SparkLibraryPostNotification([self library], SparkObjectSetWillAddObjectNotification, self, object);
      
    {
      SparkUID uid = [object uid], luid = [self currentUID];
      /* Update Object UID */
      [self sp_checkUID:object];
      /* Check change and prepare undo */
      if (uid != [object uid])
        [[[self undoManager] prepareWithInvocationTarget:object] setUID:uid];
      if (luid != [self currentUID])
        [[[self undoManager] prepareWithInvocationTarget:self] setCurrentUID:luid];
      [[self undoManager] registerUndoWithTarget:self selector:@selector(removeObject:) object:object];
    } 
    
      [self sp_addObject:object];
    
      // Did add object
      SparkLibraryPostNotification([self library], SparkObjectSetDidAddObjectNotification, self, object);
      return YES;
    }
  } @catch (id exception) {
    SPXLogException(exception);
  }
  return NO;
}
- (NSUInteger)addObjectsFromArray:(NSArray *)objects {
  NSUInteger count = 0;
  SparkObject *item = nil;
  NSEnumerator *items = [objects objectEnumerator];
  while (item = [items nextObject]) {
    count += ([self addObject:item]) ? 1 : 0;
  }
  return count;
}

//#pragma mark -
//- (BOOL)updateObject:(SparkObject *)object {
//  NSParameterAssert([self containsObject:object]);
//  SparkObject *old = [self objectWithUID:[object uid]];
//  if (old && (old != object)) {
//    // Will update
//    SparkLibraryPostUpdateNotification([self library], SparkObjectSetWillUpdateObjectNotification, self, old, object);
//    
//    /* Register undo => [self updateObject:old]; */
//    [[self undoManager] registerUndoWithTarget:self selector:@selector(updateObject:) object:old];
//    
//    // Update
//    [old setLibrary:nil];
//    [self sp_addObject:object];
//    // Did update
//    SparkLibraryPostUpdateNotification([self library], SparkObjectSetDidUpdateObjectNotification, self, old, object);
//    return YES;
//  }
//  return NO;
//}

#pragma mark -
- (void)removeObject:(SparkObject *)object {
  if (object && [self containsObject:object]) {
    // Will remove
    SparkLibraryPostNotification([self library], SparkObjectSetWillRemoveObjectNotification, self, object);
    
    /* Register undo => [self addObject:object]; */
    [[self undoManager] registerUndoWithTarget:self selector:@selector(addObject:) object:object];

    // Remove
    object.library = nil;
    [sp_objects removeObjectForKey:@(object.uid)];
    // Did remove
    SparkLibraryPostNotification([self library], SparkObjectSetDidRemoveObjectNotification, self, object);
  }
}

- (void)removeObjectWithUID:(SparkUID)uid {
  SparkObject *object = [self objectWithUID:uid];
  if (object)
    [self removeObject:object];
}

- (void)removeObjectsInArray:(NSArray *)objects {
  for (SparkObject *item in objects)
    [self removeObject:item];
}

- (NSDictionary *)serialize:(SparkObject *)anObject error:(OSStatus *)error {
  return WBSerializeObject(anObject, error);
}

- (NSFileWrapper *)fileWrapper:(__autoreleasing NSError **)outError {
  NSMutableArray *objects = [[NSMutableArray alloc] init];
  NSMutableDictionary *plist = [[NSMutableDictionary alloc] init];
  [plist setObject:@(kSparkObjectSetCurrentVersion) forKey:kSparkObjectSetVersionKey];

  [self enumerateObjectsUsingBlock:^(SparkObject *obj, BOOL *stop) {
    OSStatus err = noErr;
    if (obj.uid > kSparkLibraryReserved) {
      NSDictionary *serialize = [self serialize:obj error:&err];
      if (serialize && [NSPropertyListSerialization propertyList:serialize isValidForFormat:SparkLibraryFileFormat]) {
        [objects addObject:serialize];
      } else {
        SPXDebug(@"Error while serializing object: %@", obj);
        if (noErr != err && outError)
          *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
      }
    }
  }];
  [plist setObject:objects forKey:kSparkObjectSetObjectsKey];
  NSData *data = [NSPropertyListSerialization dataFromPropertyList:plist
                                                            format:SparkLibraryFileFormat
                                                  errorDescription:nil];

  return [[NSFileWrapper alloc] initRegularFileWithContents:data];
}

- (SparkObject *)deserialize:(NSDictionary *)plist error:(OSStatus *)error {
  return WBDeserializeObject(plist, error);
}

#define spx_error(condition, var, error) do { \
  if (!(condition)) { \
    if (var) *var = error; \
    return NO; \
  } \
} while (0)

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(__autoreleasing NSError **)outError {
  NSData *data = [fileWrapper regularFileContents];
  spx_error(data, outError, [NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:nil]);
  
  /* Remove all */
  NSArray *values = [sp_objects allValues];
  /* Reset map and uid */
  [sp_objects removeAllObjects];
  
  /* reinsert reserved objects */
  for (SparkObject *sobject in values) {
    if (sobject.uid > kSparkLibraryReserved)
      sobject.library = nil;
    else
      [self sp_addObject:sobject];
  }
  
  sp_uid = kSparkLibraryReserved;
  
  NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:data
                                                                  options:NSPropertyListImmutable
                                                                   format:NULL
                                                                    error:outError];
  if (!plist)
    return NO;
  
  NSUInteger version = [[plist objectForKey:kSparkObjectSetVersionKey] integerValue];
  /* Update object set */
  SparkIconManager *icons = nil;
  if (version < kSparkObjectSetVersion_2_1 && SparkGetCurrentContext() == kSparkContext_Editor)
      icons = [[self library] iconManager];
  
  NSArray *objects = [plist objectForKey:kSparkObjectSetObjectsKey];
  spx_error(objects, outError, [NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:nil]);
  
  /* Disable undo */
	[self.library disableNotifications];
  [self.undoManager disableUndoRegistration];

  for (NSDictionary *serialized in objects) {
    OSStatus err;
    SparkObject *object = [self deserialize:serialized error:&err];
    /* If class not found */
    if (!object && kWBClassNotFoundError == err)
      object = [[SparkPlaceHolder alloc] initWithSerializedValues:serialized];

    if (object && ![self containsObject:object]) {
      /* Avoid notifications */
      [self sp_checkUID:object];
      [self sp_addObject:object];

      /* Update old set */
      if (icons && [object hasIcon] && [object shouldSaveIcon]) {
        [icons setIcon:object.icon forObject:object];
      } else if ([object hasIcon] && ![object shouldSaveIcon]) {
        /* Updated version of plugin no longer save icon. */
        [self.library.iconManager setIcon:nil forObject:object];
      }
    } else {
      SPXDebug(@"Invalid object: %@", serialized);
    }
  }
  
  /* enable undo */
  [self.undoManager enableUndoRegistration];
  [self.library enableNotifications];
  return YES;
}

#pragma mark -
#pragma mark UID Management
- (SparkUID)nextUID {
  sp_uid++;
  return sp_uid;
}

- (SparkUID)currentUID {
  return sp_uid;
}

- (void)setCurrentUID:(SparkUID)uid {
  sp_uid = uid;
}

@end

#pragma mark -
@implementation SparkPlaceHolder {
  NSDictionary *sp_plist;
}

static NSImage *__SparkWarningImage = nil;
+ (void)initialize {
  if ([SparkPlaceHolder class] == self) {
    __SparkWarningImage = [NSImage imageNamed:@"Warning" inBundle:kSparkKitBundle];
  }
}

- (instancetype)initWithName:(NSString *)name icon:(NSImage *)icon {
  if (self = [super initWithName:name icon:nil]) {
    [self setIcon:__SparkWarningImage];
  }
  return self;
}

- (instancetype)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    sp_plist = [plist copy];
  }
  return self;
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
  SPXDebug(@"-[%@ %@]", [self class], NSStringFromSelector([invocation selector]));
  if ([[invocation methodSignature] methodReturnLength] > 0) {
    char buffer[32] = {};
    /* setReturnValue auto compute the value size */
    [invocation setReturnValue:buffer];
  }
}

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

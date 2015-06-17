/*
 *  SparkObject.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkObject.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkFunctions.h>
#import <SparkKit/SparkIconManager.h>

#import <WonderBox/WBObjCRuntime.h>

#import "SparkLibraryPrivate.h"

static
NSString* const kSparkObjectUIDKey = @"SparkObjectUID";
static
NSString* const kSparkObjectNameKey = @"SparkObjectName";
static
NSString* const kSparkObjectIconKey = @"SparkObjectIcon";

@interface SparkObject ()
- (instancetype)initFromPropertyList:(NSDictionary *)plist;
- (instancetype)initWithSerializedValues_:(NSDictionary *)plist;
@end

@implementation SparkObject {
  NSImage *_icon;
}

+ (NSSet *)keyPathsForValuesAffectingName {
  return [NSSet setWithObject:@"representation"];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
	return ![key isEqualToString:@"representation"];
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
  NSParameterAssert([coder isKindOfClass:[SparkLibraryArchiver class]]);
	[coder encodeInt32:_uid forKey:kSparkObjectUIDKey];
  [coder encodeObject:_name forKey:kSparkObjectNameKey];
  return;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  NSParameterAssert([coder isKindOfClass:[SparkLibraryUnarchiver class]]);
  NSParameterAssert([(SparkLibraryUnarchiver *)coder library]);

  if (self = [super init]) {
    _library = [(SparkLibraryUnarchiver *)coder library];

    _uid = [coder decodeInt32ForKey:kSparkObjectUIDKey];
    _name = [coder decodeObjectForKey:kSparkObjectNameKey];
  }
  return self;
}

#pragma mark NSCopying
- (instancetype)copyWithZone:(NSZone *)zone {
  SparkObject* copy = [[[self class] allocWithZone:zone] init];
  copy->_uid = _uid;
  copy->_name = _name;
  copy->_icon = _icon;
	copy->_library = nil; // the copy is not attached to a library
  return copy;
}

#pragma mark -
- (instancetype)initWithSerializedValues_:(NSDictionary *)plist {
  BOOL compat = NO;
  NSString *name = [plist objectForKey:kSparkObjectNameKey];
  if (!name) {
    compat = YES;
    name = [plist objectForKey:@"Name"];
  }
  
  NSImage *icon = nil;
  /* If editor, load icon */
  if (kSparkContext_Editor == SparkGetCurrentContext()) {
    NSData *bitmap = [plist objectForKey:kSparkObjectIconKey];
    if (!bitmap && compat)
      bitmap = [plist objectForKey:@"Icon"];
    if (bitmap)
      icon = [[NSImage alloc] initWithData:bitmap];
  }
  self = [self initWithName:name icon:icon];
  
  if (self) {
    NSNumber *value = [plist objectForKey:kSparkObjectUIDKey];
    if (!value && compat)
      value = [plist objectForKey:@"UID"];
    [self setUID:value ? (SparkUID)[value unsignedIntegerValue] : 0];
  }
  return self;
}

/* Compatibility */
- (NSMutableDictionary *)propertyList {
  return [NSMutableDictionary dictionary];
}
- (instancetype)initFromPropertyList:(NSDictionary *)plist {
  return [self initWithSerializedValues_:plist];
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  [plist setObject:@(_uid) forKey:kSparkObjectUIDKey];
  if (_name)
    [plist setObject:_name forKey:kSparkObjectNameKey];
  /* Compatibility */
  if (WBRuntimeInstanceImplementsSelector([self class], @selector(propertyList))) {
    id dico = [self propertyList];
    if (dico) {
      [plist addEntriesFromDictionary:dico];
    }
  }
  return YES;
}

- (instancetype)initWithSerializedValues:(NSDictionary *)plist {
  /* Compatibility */
  if (WBRuntimeInstanceImplementsSelector([self class], @selector(initFromPropertyList:))) {
    self = [self initFromPropertyList:plist];
  } else {
    self = [self initWithSerializedValues_:plist];
  }
  return self;
}

#pragma mark -
#pragma mark Static Initializers
+ (instancetype)object {
  return [[self alloc] init];
}

+ (instancetype)objectWithName:(NSString *)name {
  return [[self alloc] initWithName:name];
}

+ (instancetype)objectWithName:(NSString *)name icon:(NSImage *)icon {
  return [[self alloc] initWithName:name icon:icon];
}

#pragma mark -
#pragma mark Init & Dealloc Methods
- (instancetype)init {
  return [self initWithName:nil icon:nil];
}

- (instancetype)initWithName:(NSString *)name {
  return [self initWithName:name icon:nil];
}

- (instancetype)initWithName:(NSString *)name icon:(NSImage *)icon {
  if (self = [super init]) {
    [self setName:name];
    [self setIcon:icon];
  }
  return self;
}

- (NSComparisonResult)compare:(SparkObject *)anObject {
  return (NSComparisonResult)[self uid] - [anObject uid];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {uid:%u name:%@}", [self class], self, _uid, _name];
}

- (NSUInteger)hash {
  return _uid;
}
- (BOOL)isEqual:(id)object {
  return ([object class] == [self class]) && ([object uid] == [self uid]);
}

#pragma mark -
#pragma mark Icon
- (NSImage *)icon {
  if (!_icon && [self shouldSaveIcon]) {
    _icon = [self.library.iconManager iconForObject:self];
    if (!_icon) {
      _icon = [self iconCacheMiss];
      if (_icon) {
        /* Icon cache miss recovery */
        [self.library.iconManager setIcon:_icon forObject:self];
      }
    }
  }
  return _icon;
}
- (void)setIcon:(NSImage *)icon {
  if (_icon != icon && [self shouldSaveIcon]) {
    [self.library.iconManager setIcon:icon forObject:self];
  }
  [self willChangeValueForKey:@"representation"];
  SPXSetterRetain(_icon, icon);
  [self didChangeValueForKey:@"representation"];
}
- (BOOL)hasIcon {
  return _icon != nil;
}
- (BOOL)shouldSaveIcon {
  return YES;
}

- (NSImage *)iconCacheMiss {
  return nil;
}

#pragma mark -
- (id)representation {
  return self;
}
- (void)setRepresentation:(NSString *)rep {
	/* set representation is supposed to be used only by the editor */
	[self.library.undoManager registerUndoWithTarget:self
                                          selector:@selector(setRepresentation:)
                                            object:[self name]];
	[self setName:rep];  
}

@end

//@implementation SparkObject (SparkExport)
//
//- (id)initFromExternalRepresentation:(NSDictionary *)rep {
//  if (self = [super init]) {
//    [self setName:[rep objectForKey:@"name"]];
//  }
//  return self;
//}
//
//- (NSMutableDictionary *)externalRepresentation {
//  return [NSMutableDictionary dictionaryWithObjectsAndKeys:[self name], @"name", nil];
//}
//
//@end

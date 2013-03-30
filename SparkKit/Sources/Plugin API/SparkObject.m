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
- (id)sp_initWithSerializedValues:(NSDictionary *)plist NS_METHOD_FAMILY(init);
@end

@implementation SparkObject

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
	return ![key isEqualToString:@"representation"];
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
  NSParameterAssert([coder isKindOfClass:[SparkLibraryArchiver class]]);
	[coder encodeInt32:sp_uid forKey:kSparkObjectUIDKey];
  [coder encodeObject:sp_name forKey:kSparkObjectNameKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  NSParameterAssert([coder isKindOfClass:[SparkLibraryUnarchiver class]]);
  NSParameterAssert([(SparkLibraryUnarchiver *)coder library]);
  
  NSString *name = [coder decodeObjectForKey:kSparkObjectNameKey];
  if (self = [self initWithName:name icon:nil]) {
    [self setUID:[coder decodeInt32ForKey:kSparkObjectUIDKey]];
    [self setLibrary:[(SparkLibraryUnarchiver *)coder library]];
  }
  return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
  SparkObject* copy = (id)NSCopyObject(self, 0, zone);
  copy->sp_uid = sp_uid;
  copy->sp_name = [sp_name retain];
  copy->sp_icon = [sp_icon retain];
	copy->sp_library = nil; // the copy is not attached to a library
  return copy;
}

#pragma mark -
- (id)sp_initWithSerializedValues:(NSDictionary *)plist {
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
  [icon release];
  
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
- (id)initFromPropertyList:(NSDictionary *)plist {
  return [self sp_initWithSerializedValues:plist];
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  [plist setObject:@(sp_uid) forKey:kSparkObjectUIDKey];
  if (sp_name)
    [plist setObject:sp_name forKey:kSparkObjectNameKey];
  /* Compatibility */
  if (WBRuntimeInstanceImplementsSelector([self class], @selector(propertyList))) {
    id dico = [self propertyList];
    if (dico) {
      [plist addEntriesFromDictionary:dico];
    }
  }
  return YES;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  /* Compatibility */
  if (WBRuntimeInstanceImplementsSelector([self class], @selector(initFromPropertyList:))) {
    self = [self initFromPropertyList:plist];
  } else {
    self = [self sp_initWithSerializedValues:plist];
  }
  return self;
}

#pragma mark -
#pragma mark Static Initializers
+ (id)object {
  return [[[self alloc] init] autorelease];
}

+ (id)objectWithName:(NSString *)name {
  return [[[self alloc] initWithName:name] autorelease];
}

+ (id)objectWithName:(NSString *)name icon:(NSImage *)icon {
  return [[[self alloc] initWithName:name icon:icon] autorelease];
}

#pragma mark -
#pragma mark Init & Dealloc Methods
- (id)init {
  return [self initWithName:nil icon:nil];
}

- (id)initWithName:(NSString *)name {
  return [self initWithName:name icon:nil];
}

- (id)initWithName:(NSString *)name icon:(NSImage *)icon {
  if (self = [super init]) {
    [self setName:name];
    [self setIcon:icon];
  }
  return self;
}

- (void)dealloc {
  [sp_icon release];
  [sp_name release];
  [super dealloc];
}

- (NSComparisonResult)compare:(SparkObject *)anObject {
  return (NSComparisonResult)[self uid] - [anObject uid];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {uid:%u name:%@}",
    [self class], self, sp_uid, sp_name];
}

- (NSUInteger)hash {
  return sp_uid;
}
- (BOOL)isEqual:(id)object {
  return ([object class] == [self class]) && ([object uid] == [self uid]);
}

#pragma mark -
#pragma mark Icon
- (NSImage *)icon {
  if (!sp_icon && [self shouldSaveIcon]) {
    sp_icon = [[[self library] iconManager] iconForObject:self];
    if (!sp_icon) {
      sp_icon = [self iconCacheMiss];
      if (sp_icon) {
        /* Icon cache miss recovery */
        [[[self library] iconManager] setIcon:sp_icon forObject:self];
      }
    }
    [sp_icon retain];
  }
  return sp_icon;
}
- (void)setIcon:(NSImage *)icon {
  if (sp_icon != icon && [self shouldSaveIcon]) {
    [[[self library] iconManager] setIcon:icon forObject:self];
  }
  [self willChangeValueForKey:@"representation"];
  SPXSetterRetain(sp_icon, icon);
  [self didChangeValueForKey:@"representation"];
}
- (BOOL)hasIcon {
  return sp_icon != nil;
}
- (BOOL)shouldSaveIcon {
  return YES;
}

- (NSImage *)iconCacheMiss {
  return nil;
}

#pragma mark -
- (SparkUID)uid {
  return sp_uid;
}

- (NSString *)name {
  return sp_name;
}
- (void)setName:(NSString *)name {
  [self willChangeValueForKey:@"representation"];
  SPXSetterCopy(sp_name, name);
  [self didChangeValueForKey:@"representation"];
}

- (id)representation {
  return self;
}
- (void)setRepresentation:(NSString *)rep {
	/* set representation is supposed to be used only by the editor */
	[[[self library] undoManager] registerUndoWithTarget:self
																							selector:@selector(setRepresentation:)
																								object:[self name]];
	[self setName:rep];  
}


- (void)setUID:(SparkUID)uid {
  sp_uid = uid;
}

- (SparkLibrary *)library {
  return sp_library;
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  sp_library = aLibrary;
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

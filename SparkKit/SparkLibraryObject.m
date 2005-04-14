//
//  SparkLibraryObject.m
//  Spark
//
//  Created by Fox on Fri Jan 23 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "SparkLibraryObject.h"
#import "Spark_Private.h"
#import "ShadowMacros.h"

static NSString* const kSparkLibraryObjectUIDKey = @"UID";
static NSString* const kSparkLibraryObjectNameKey = @"Name";
static NSString* const kSparkLibraryObjectIconKey = @"Icon";

@implementation SparkLibraryObject

static BOOL loadUI = YES;

+ (void)initialize {
  static BOOL tooLate = NO;
  if (!tooLate ) {
    [self exposeBinding:@"name"];
    [self exposeBinding:@"icon"];
    tooLate = YES;
  }
}

#pragma mark -
#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:_uid forKey:kSparkLibraryObjectUIDKey];
  if (nil != _name)
    [coder encodeObject:_name forKey:kSparkLibraryObjectNameKey];
  if (_icon)
    [coder encodeObject:[_icon TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:1] forKey:kSparkLibraryObjectIconKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super init]) {
    [self setUid:[coder decodeObjectForKey:kSparkLibraryObjectUIDKey]];
    [self setIcon:[coder decodeObjectForKey:kSparkLibraryObjectIconKey]];
    [self setName:[coder decodeObjectForKey:kSparkLibraryObjectNameKey]];
  }
  return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
  SparkLibraryObject* copy = [[[self class] allocWithZone:zone] init];
  copy->_uid = _uid;
  [copy setName:_name];
  [copy setIcon:_icon];
  return copy;
}

#pragma mark SparkLibraryObject
- (id)uid {
  return _uid;
}
- (void)setUid:(id)uid {
  if (_uid != uid) {
    [_uid release];
    _uid = [uid copy];
  }
}

- (NSMutableDictionary *)propertyList {
  NSMutableDictionary *dico = [NSMutableDictionary dictionary];
  [dico setObject:_uid forKey:kSparkLibraryObjectUIDKey];
  if (_name)
    [dico setObject:_name forKey:kSparkLibraryObjectNameKey];
  if (_icon) {
    [dico setObject:[_icon TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:1] forKey:kSparkLibraryObjectIconKey];
  }
  return dico;
}
- (id)initFromPropertyList:(NSDictionary *)plist {
  if (self = [super init]) {
    [self setLibrary:[plist objectForKey:@"_SparkLibrary_"]];
    [self setUid:[plist objectForKey:kSparkLibraryObjectUIDKey]];
    id name = [plist objectForKey:kSparkLibraryObjectNameKey];
    if (name)
      [self setName:name];
    else {
      [self release];
      self = nil;
    }
    if (loadUI) {
      id icon = [[NSImage alloc] initWithData:[plist objectForKey:kSparkLibraryObjectIconKey]];
      [self setIcon:icon];
      [icon release];
    }
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

+ (id)objectFromPropertyList:(NSDictionary *)plist {
  return [[[self alloc] initFromPropertyList:plist] autorelease];
}

#pragma mark -
#pragma mark Init & Dealloc Methods
- (id)initWithName:(NSString *)name {
  if (self = [self init]) {
    [self setName:name];
  }
  return self; 
}

- (id)initWithName:(NSString *)name icon:(NSImage *)icon {
  if (self = [self initWithName:name]) {
    [self setIcon:icon];
  }
  return self;
}

- (void)dealloc {
  [_uid release];
  [_icon release];
  [_name release];
  [super dealloc];
}

#pragma mark -
#pragma mark Public Methods
- (NSComparisonResult)compare:(SparkLibraryObject *)anObject {
  NSParameterAssert(nil != anObject);
  return [(NSNumber *)_uid compare:[anObject uid]];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {uid:%@ name:%@ icon:%@}",
    [self className], self,
    _uid, _name, _icon];
}

- (BOOL)isEqualToLibraryObject:(SparkLibraryObject *)object {
  return ([[object uid] isEqualToNumber:_uid]) && ([object class] == [self class]);
}

#pragma mark -
#pragma mark Accessors
+ (BOOL)loadUI {
  return loadUI;
}
+ (void)setLoadUI:(BOOL)flag {
  loadUI = flag;
}

- (NSImage *)icon {
  return _icon;
}
- (void)setIcon:(NSImage *)icon {
  if (_icon != icon) { 
    [_icon release];
    _icon = [icon retain];
  }
}

- (NSString *)name {
  return _name;
}
- (void)setName:(NSString *)name {
  if (_name != name) { 
    [_name release];
    _name = [name copy];
  }
}

- (SparkLibrary *)library {
  return _library;
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  _library = aLibrary;
}

- (SparkObjectsLibrary *)objectsLibrary {
  return nil; /* Must be overriding. */
}

@end

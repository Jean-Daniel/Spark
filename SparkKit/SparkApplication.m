//
//  SparkApplication.m
//  SparkKit
//
//  Created by Grayfox on 16/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkApplicationLibrary.h>

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKImageUtils.h>
#import <ShadowKit/SKApplication.h>
#import <ShadowKit/SKAppKitExtensions.h>

static NSString * const kSparkApplicationKey = @"SparkApplication";

#pragma mark -
@interface SKApplication (SparkSerialization) <SparkSerialization>
- (id)initFromPropertyList:(id)plist;
- (id)propertyList;
@end

@implementation SparkApplication

#pragma mark -
#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:_application forKey:kSparkApplicationKey];
  return;
}
- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    _application = [[coder decodeObjectForKey:kSparkApplicationKey] retain];
  }
  return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
  SparkApplication* copy = [super copyWithZone:zone];
  copy->_application = [_application copy];
  return copy;
}

#pragma mark SparkSerialization
- (NSMutableDictionary *)propertyList {
  id plist = [super propertyList];
  if ([_application identifier])
    [plist setObject:[_application propertyList] forKey:kSparkApplicationKey];
  return plist;
}
- (id)initFromPropertyList:(NSDictionary *)plist {
  if (self = [super initFromPropertyList:plist]) {
    _application = [[SKApplication alloc] initFromPropertyList:[plist objectForKey:kSparkApplicationKey]];
  }
  return self;
}

#pragma mark -
#pragma mark Init & Dealloc Methods
- (id)init {
  if (self = [super init]) {
    _application = [[SKApplication alloc] init];
  }
  return self;
}

- (id)initWithPath:(NSString *)path {
  if (self = [super init]) {
    [self setPath:path];
    if (!_application) {
      DLog(@"Invalid app at path: %@", path);
      [self release];
      self = nil;
    }
  }
  return self;
}

- (void)dealloc {
  [_application release];
  [super dealloc];
}

#pragma mark -
#pragma mark Accessors
- (NSString *)path {
  return [_application path];
}
- (void)setPath:(NSString *)path {
  if (_application) {
    [_application release];
  }
  _application = [[SKApplication alloc] initWithPath:path];
  if (_application) {
    [self setName:[_application name]];
    [self setIcon:SKResizedIcon([[NSWorkspace sharedWorkspace] iconForFile:path], NSMakeSize(16, 16))];
    [_application setName:nil];
  }
}

- (NSString *)identifier {
  return [_application identifier];
}

- (NSString *)signature {
  return ([_application idType] == kSKApplicationOSType) ? [_application identifier] : nil;
}
- (void)setSignature:(NSString *)signature {
  [_application setIdentifier:signature type:kSKApplicationOSType];
}

- (NSString *)bundleIdentifier {
  return ([_application idType] == kSKApplicationBundleIdentifier) ? [_application identifier] : nil;
}
- (void)setBundleIdentifier:(NSString *)identifier {
  [_application setIdentifier:identifier type:kSKApplicationBundleIdentifier];
}

- (SparkObjectsLibrary *)objectsLibrary {
  return [[self library] applicationLibrary];
}

@end

#pragma mark -
static NSString * const kSKApplicationName = @"Name";
static NSString * const kSKApplicationIdType = @"IDType";
static NSString * const kSKApplicationIdentifier = @"Identifier";

@implementation SKApplication (SparkSerialization)

- (id)initFromPropertyList:(id)plist {
  if (self = [super init]) {
    [self setName:[plist objectForKey:kSKApplicationName]];
    [self setIdentifier:[plist objectForKey:kSKApplicationIdentifier]
                   type:[[plist objectForKey:kSKApplicationIdType] intValue]];
  }
  return self;
}

- (id)propertyList {
  return [NSDictionary dictionaryWithObjectsAndKeys:
    SKInt([self idType]), kSKApplicationIdType,
    [self identifier], kSKApplicationIdentifier,
    [self name], kSKApplicationName, /* if name is nil, it is just ignored */
    nil];
}

@end

#pragma mark -
@implementation _SparkSystemApplication

+ (id)application {
  return [[[self alloc] init] autorelease];
}

- (id)init {
  if (self = [super init]) {
    [self setName:NSLocalizedStringFromTableInBundle(@"SYSTEM_APP_NAME",
                                                     nil, SKCurrentBundle(),
                                                     @"Default Application")];
    [self setIcon:[NSImage imageNamed:@"SystemApplication" inBundle:SKCurrentBundle()]];
  }
  return self;
}

- (id)initFromPropertyList:(id)plist {
  if (self = [super initFromPropertyList:plist]) {
    [self setName:NSLocalizedStringFromTableInBundle(@"SYSTEM_APP_NAME",
                                                     nil, SKCurrentBundle(),
                                                     @"Default Application")];
    [self setIcon:[NSImage imageNamed:@"SystemApplication" inBundle:SKCurrentBundle()]];
  }
  return self;
}

- (NSString *)identifier {
  return [self signature];
}

- (NSString *)signature {
  return SKFileTypeForHFSTypeCode('****');
}
- (void)setBundleIdentifier:(NSString *)identifier {}
- (void)setSignature:(NSString *)sign {}
- (void)setPath:(NSString *)path {}

@end
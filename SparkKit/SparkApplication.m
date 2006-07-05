//
//  SparkApplication.m
//  SparkKit
//
//  Created by Grayfox on 16/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkApplication.h>

#import <ShadowKit/SKImageUtils.h>
#import <ShadowKit/SKApplication.h>

static NSString * const kSparkApplicationKey = @"SparkApplication";

#pragma mark -
@interface SKApplication (SparkSerialization)
- (BOOL)serialize:(NSMutableDictionary *)plist;
- (id)initWithSerializedValues:(NSDictionary *)plist;
@end

@implementation SparkApplication

#pragma mark -
#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:sp_application forKey:kSparkApplicationKey];
  return;
}
- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    sp_application = [[coder decodeObjectForKey:kSparkApplicationKey] retain];
  }
  return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
  SparkApplication* copy = [super copyWithZone:zone];
  copy->sp_application = [sp_application copy];
  return copy;
}

#pragma mark SparkSerialization
- (BOOL)serialize:(NSMutableDictionary *)plist {
  [super serialize:plist];
  if ([sp_application identifier])
    return [sp_application serialize:plist];
  return YES;
}
- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    sp_application = [[SKApplication alloc] initWithSerializedValues:plist];
  }
  return self;
}

#pragma mark -
#pragma mark Init & Dealloc Methods
- (id)init {
  if (self = [super init]) {
    sp_application = [[SKApplication alloc] init];
  }
  return self;
}

- (id)initWithPath:(NSString *)path {
  if (self = [super init]) {
    [self setPath:path];
    if (!sp_application) {
      DLog(@"Invalid app at path: %@", path);
      [self release];
      self = nil;
    }
  }
  return self;
}

- (void)dealloc {
  [sp_application release];
  [super dealloc];
}

#pragma mark -
#pragma mark Accessors
- (NSString *)path {
  return [sp_application path];
}
- (void)setPath:(NSString *)path {
  if (sp_application) {
    [sp_application release];
  }
  sp_application = [[SKApplication alloc] initWithPath:path];
  if (sp_application) {
    [self setName:[sp_application name]];
    [self setIcon:SKResizedIcon([[NSWorkspace sharedWorkspace] iconForFile:path], NSMakeSize(16, 16))];
    [sp_application setName:nil];
  }
}

- (NSString *)identifier {
  return [sp_application identifier];
}

- (NSString *)signature {
  return ([sp_application idType] == kSKApplicationOSType) ? [sp_application identifier] : nil;
}
- (void)setSignature:(NSString *)signature {
  [sp_application setIdentifier:signature type:kSKApplicationOSType];
}

- (NSString *)bundleIdentifier {
  return ([sp_application idType] == kSKApplicationBundleIdentifier) ? [sp_application identifier] : nil;
}
- (void)setBundleIdentifier:(NSString *)identifier {
  [sp_application setIdentifier:identifier type:kSKApplicationBundleIdentifier];
}

@end

#pragma mark -
static NSString * const kSKApplicationName = @"Name";
static NSString * const kSKApplicationIdType = @"IDType";
static NSString * const kSKApplicationIdentifier = @"Identifier";

@implementation SKApplication (SparkSerialization)

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super init]) {
    [self setName:[plist objectForKey:kSKApplicationName]];
    [self setIdentifier:[plist objectForKey:kSKApplicationIdentifier]
                   type:[[plist objectForKey:kSKApplicationIdType] intValue]];
  }
  return self;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  [plist setObject:SKInt([self idType]) forKey:kSKApplicationIdType];
  [plist setObject:[self identifier] forKey:kSKApplicationIdentifier];
  if ([self name])
    [plist setObject:[self name] forKey:kSKApplicationName];
  return YES;
}

@end

#pragma mark -
//@implementation _SparkSystemApplication
//
//+ (id)application {
//  return [[[self alloc] init] autorelease];
//}
//
//- (id)init {
//  if (self = [super init]) {
//    [self setName:NSLocalizedStringFromTableInBundle(@"SYSTEM_APP_NAME",
//                                                     nil, SKCurrentBundle(),
//                                                     @"Default Application")];
//    [self setIcon:[NSImage imageNamed:@"SystemApplication" inBundle:SKCurrentBundle()]];
//  }
//  return self;
//}
//
//- (id)initFromPropertyList:(id)plist {
//  if (self = [super initFromPropertyList:plist]) {
//    [self setName:NSLocalizedStringFromTableInBundle(@"SYSTEM_APP_NAME",
//                                                     nil, SKCurrentBundle(),
//                                                     @"Default Application")];
//    [self setIcon:[NSImage imageNamed:@"SystemApplication" inBundle:SKCurrentBundle()]];
//  }
//  return self;
//}
//
//- (NSString *)identifier {
//  return [self signature];
//}
//
//- (NSString *)signature {
//  return SKFileTypeForHFSTypeCode('****');
//}
//- (void)setBundleIdentifier:(NSString *)identifier {}
//- (void)setSignature:(NSString *)sign {}
//- (void)setPath:(NSString *)path {}
//
//@end

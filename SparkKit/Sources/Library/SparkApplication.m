/*
 *  SparkApplication.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkShadowKit.h>

#import <ShadowKit/SKImageUtils.h>
#import <ShadowKit/SKApplication.h>
#import <ShadowKit/SKAppKitExtensions.h>

static NSString * const kSparkApplicationKey = @"SparkApplication";

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
    /* Update name and icon */
    NSString *path = [sp_application path];
    if (path) {
      NSString *name = [[NSFileManager defaultManager] displayNameAtPath:path];
      if (name)
        [self setName:name];
      /* Reset icon, it will be lazy load later */
      [self setIcon:nil];
    }
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

- (BOOL)isEqual:(id)object {
  if (self == object)
    return YES;
  else if ([object isKindOfClass:[SparkApplication class]])
    return [sp_application isEqual:((SparkApplication *)object)->sp_application];
  else return NO;
}
- (unsigned)hash {
  return [sp_application hash];
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
    [sp_application setName:nil];
    /* Reset icon data */
    [self setIcon:nil];
  }
}

/* Loading workspace icon is slow, so use lazy loading */
- (NSImage *)icon {
  if (![super icon]) {
    //NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[sp_application path]];
    NSString *path = [sp_application path];
    NSImage *icon = path ? SKResizedIcon([[NSWorkspace sharedWorkspace] iconForFile:[sp_application path]], NSMakeSize(32, 32)) : nil;
    if (!icon) {
      icon = [NSImage imageNamed:@"Application" inBundle:SKCurrentBundle()];
    }
    [self setIcon:icon];
  }
  return [super icon];
}

//- (NSString *)identifier {
//  return [sp_application identifier];
//}

- (OSType)signature {
  return [sp_application signature];
}
//- (void)setSignature:(NSString *)signature {
//  [sp_application setIdentifier:signature type:kSKApplicationOSType];
//}
//
- (NSString *)bundleIdentifier {
  return [sp_application bundleIdentifier];
}
//- (void)setBundleIdentifier:(NSString *)identifier {
//  [sp_application setIdentifier:identifier type:kSKApplicationBundleIdentifier];
//}

@end

#pragma mark -
static
NSString * const kSKApplicationIdType = @"SKApplicationType";
static
NSString * const kSKApplicationIdentifier = @"SKApplicationIdentifier";

@implementation SKApplication (SparkSerialization)

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super init]) {
    /* Compatibility with Library version 1.0 */
    NSString *identifier;
    SKApplicationIdentifier type;
    if ([plist objectForKey:@"SparkApplication"]) {
      plist = [plist objectForKey:@"SparkApplication"];
      identifier = [plist objectForKey:@"Identifier"];
      type = [[plist objectForKey:@"IDType"] intValue];
    } else {
      identifier = [plist objectForKey:kSKApplicationIdentifier];
      type = [[plist objectForKey:kSKApplicationIdType] intValue];
    }
    
    [self setIdentifier:identifier type:type];
  }
  return self;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([self identifier]) {
    [plist setObject:SKInt([self idType]) forKey:kSKApplicationIdType];
    [plist setObject:[self identifier] forKey:kSKApplicationIdentifier];
  }
  return YES;
}

@end

@implementation SKAliasedApplication (SparkSerialization)

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    NSData *alias = [[self alias] data];
    if (alias)
      [plist setObject:alias forKey:@"SKApplicationAlias"];
    return YES;
  }
  return NO;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    NSData *alias = [plist objectForKey:@"SKApplicationAlias"];
    if (alias) {
      sk_alias = [[SKAlias alloc] initWithData:alias];
    }
  }
  return self;
}

@end

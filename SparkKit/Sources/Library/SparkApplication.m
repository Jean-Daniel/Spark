/*
 *  SparkApplication.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkShadowKit.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkPrivate.h>

#import <ShadowKit/SKAlias.h>
#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKLSFunctions.h>
#import <ShadowKit/SKApplication.h>
#import <ShadowKit/SKProcessFunctions.h>
#import <ShadowKit/SKAppKitExtensions.h>

static
NSString * const kSparkApplicationKey = @"SparkApplication";
static
NSString * const kSparkApplicationFlagsKey = @"SparkApplicationFlags";

NSString * const SparkApplicationDidChangeEnabledNotification = @"SparkApplicationDidChangeEnabled";

@interface SparkSystemApplication : SparkApplication

+ (id)systemApplication;

@end

@implementation SparkApplication

+ (id)systemApplication {
  return [SparkSystemApplication systemApplication];
}

#pragma mark -
#pragma mark NSCoding
- (UInt32)encodeFlags {
  UInt32 flags = 0;
  if (sp_appFlags.disabled) flags |= 1 << 0;
  return flags;
}
- (void)decodeFlags:(UInt32)flags {
  if (flags & (1 << 0)) sp_appFlags.disabled = 1;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:sp_application forKey:kSparkApplicationKey];
  [coder encodeInt32:[self encodeFlags] forKey:kSparkApplicationFlagsKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    [self decodeFlags:[coder decodeInt32ForKey:kSparkApplicationFlagsKey]];
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
  if ([super serialize:plist]) {
    [plist setObject:SKUInteger([self encodeFlags]) forKey:kSparkApplicationFlagsKey];
    if ([sp_application identifier])
      return [sp_application serialize:plist];
    return YES;
  }
  return NO;
}
- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    sp_application = [[SKApplication alloc] initWithSerializedValues:plist];
    [self decodeFlags:SKIntegerValue([plist objectForKey:kSparkApplicationFlagsKey])];
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
- (NSUInteger)hash {
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
  if (![self hasIcon]) {
    NSImage *icon = nil;
    NSString *path = [sp_application path];
    if (path)
      icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
    /* Try to set workspace icon */
    if (icon)
      [self setIcon:icon];
    /* If failed and cached icon invalid, set default icon */
    if (![self hasIcon])
      [self setIcon:[NSImage imageNamed:@"Application" inBundle:kSparkKitBundle]];    
  }
  return [super icon];
}

- (BOOL)shouldSaveIcon {
  return NO;
}

- (OSType)signature {
  return [sp_application signature];
}

- (NSString *)bundleIdentifier {
  return [sp_application bundleIdentifier];
}

- (SKApplication *)application {
  return sp_application;
}

- (BOOL)isEditable {
  return [self uid] != kSparkApplicationSystemUID;
}

- (BOOL)isEnabled {
  /* System application cannot be disabled */
  if ([self uid] == kSparkApplicationSystemUID)
    return YES;
  return !sp_appFlags.disabled;
}
- (void)setEnabled:(BOOL)flag {
  bool disabled = SKFlagTestAndSet(sp_appFlags.disabled, !flag);
  if (disabled != sp_appFlags.disabled) {
    [[[[self library] undoManager] prepareWithInvocationTarget:self] setEnabled:sp_appFlags.disabled];
    /* post notification */
    SparkLibraryPostNotification([self library], SparkApplicationDidChangeEnabledNotification, self, nil);
  }
}

@end

#pragma mark -
@implementation SparkSystemApplication

#pragma mark SparkSerialization
- (BOOL)serialize:(NSMutableDictionary *)plist {
  return NO;
}
- (id)initWithSerializedValues:(NSDictionary *)plist {
  return nil;
}

#pragma mark -
#pragma mark Init & Dealloc Methods
+ (id)systemApplication {
  if (self = [SparkSystemApplication objectWithName:NSLocalizedStringFromTableInBundle(@"System", nil,
                                                                                       kSparkKitBundle,
                                                                                       @"System Application Name")]) {
    
  }
  return self;
}

- (id)initWithPath:(NSString *)path {
  return nil;
}

- (BOOL)isEqual:(id)object {
  if (self == object)
    return YES;
  else if ([object isKindOfClass:[SparkApplication class]])
    return [self uid] == [object uid];
  else return NO;
}
- (NSUInteger)hash {
  return 0;
}

#pragma mark -
#pragma mark Accessors
- (SparkUID)uid {
  return kSparkApplicationSystemUID;
}

- (NSString *)path {
  return nil;
}
- (void)setPath:(NSString *)path {
}

- (NSImage *)icon {
  if (![self hasIcon]) {
    [self setIcon:[NSImage imageNamed:@"SparkSystem" inBundle:kSparkKitBundle]];
  }
  return [super icon];
}

- (BOOL)shouldSaveIcon {
  return NO;
}

- (OSType)signature {
  return 0;
}

- (NSString *)bundleIdentifier {
  return nil;
}

- (SKApplication *)application {
  return nil;
}

- (BOOL)isEditable {
  return NO;
}
- (BOOL)isEnabled {
  return YES;
}
- (void)setEnabled:(BOOL)flag {
  /* does nothing */
}

@end

#pragma mark SparkLibrary Extension
@implementation SparkLibrary (SparkLibraryPrivate)

- (SparkApplication *)applicationForProcess:(ProcessSerialNumber *)psn {
  NSParameterAssert(psn);
  if (kNoProcess == psn->lowLongOfPSN && kNoProcess == psn->highLongOfPSN)
    return nil;
  
  SparkApplication *result = nil;
  /* Try signature */
  OSType sign = SKProcessGetSignature(psn);
  if (sign && kUnknownType != sign) {
    SparkApplication *app;
    NSEnumerator *apps = [[self applicationSet] objectEnumerator];
    while (app = [apps nextObject]) {
      if ([app signature] == sign) {
        result = app;
        break;
      }
    }
  }
  /* Try bundle identifier */
  if (!result) {
    NSString *bundle = (id)SKProcessCopyBundleIdentifier(psn);
    if (bundle) {
      SparkApplication *app;
      NSEnumerator *apps = [[self applicationSet] objectEnumerator];
      while (app = [apps nextObject]) {
        if ([[app bundleIdentifier] isEqualToString:bundle]) {
          result = app;
          break;
        }
      }
      [bundle release];
    }
  }
  return result;
}

- (SparkApplication *)frontApplication {
  ProcessSerialNumber front;
  if (noErr == GetFrontProcess(&front))
    return [self applicationForProcess:&front];
  return nil;
}

@end

@implementation SparkApplication (SparkExport)

- (id)initFromExternalRepresentation:(id)rep {
  SKApplicationIdentifier aid = kSKApplicationBundleIdentifier;
  NSString *value = [rep objectForKey:@"identifier"];
  if (!value) {
    value = [rep objectForKey:@"signature"];
    aid = kSKApplicationOSType;
  }
  if (!value) {
    [self release];
    return nil;
  } 
  SKApplication *app = [SKApplication applicationWithName:nil identifier:value idType:aid];
  if (app) {
    NSString *name = [app name];
    if (!name) name = [rep objectForKey:@"name"];
    
    if (self = [super initWithName:name icon:nil]) {
      sp_application = [app retain];
    }
  }
  return self;
}

- (id)externalRepresentation {
  NSMutableDictionary *plist = [NSMutableDictionary dictionary];
  
  SKApplication *app = [self application];
  NSString *path = [app path];
  switch ([app idType]) {
    case kSKApplicationOSType:
      [plist setObject:[app identifier] forKey:@"signature"];
      if (path) {
        NSString *bundle = (id)SKLSCopyBundleIdentifierForPath((CFStringRef)path);
        if (bundle) {
          [plist setObject:bundle forKey:@"identifier"];
          [bundle release];
        }
      }
        break;
    case kSKApplicationBundleIdentifier:
      [plist setObject:[app identifier] forKey:@"identifier"];
      if (path) {
        OSType creator = SKLSGetSignatureForPath((CFStringRef)path);
        if (creator && creator != kUnknownType)
          [plist setObject:SKStringForOSType(creator) forKey:@"signature"];
      }
        break;
    case kSKApplicationUndefinedType:
      plist = nil;
      break;
  }  
  if (plist && [self name]) {
    [plist setObject:[self name] forKey:@"name"];
  }
  return plist;
}

@end

#pragma mark -
#pragma mark ShadowKit Extension
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
      type = SKIntegerValue([plist objectForKey:kSKApplicationIdType]);
    }
    
    if (kSKApplicationUndefinedType != type)
      [self setIdentifier:identifier type:type];
    
    [self setName:[plist objectForKey:@"SKApplicationName"]];
  }
  return self;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([self identifier]) {
    if ([self name])
      [plist setObject:[self name] forKey:@"SKApplicationName"];
    if (kSKApplicationUndefinedType != [self idType]) {
      [plist setObject:SKInteger([self idType]) forKey:kSKApplicationIdType];
      [plist setObject:[self identifier] forKey:kSKApplicationIdentifier];
    }
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
    NSData *data = [plist objectForKey:@"SKApplicationAlias"];
    if (data) {
      SKAlias *alias = [[SKAlias alloc] initWithData:data];
      [self setAlias:alias];
      [alias release];
    }
  }
  return self;
}

@end


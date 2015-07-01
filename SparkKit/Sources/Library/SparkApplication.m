/*
 *  SparkApplication.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkPrivate.h>

#import <WonderBox/WBFunctions.h>
#import <WonderBox/WBLSFunctions.h>
#import <WonderBox/NSImage+WonderBox.h>

static
NSString * const kSparkApplicationKey = @"SparkApplication";

static
NSString * const kSparkApplicationURLKey = @"SparkApplicationURL";

static
NSString * const kSparkApplicationBundleIdentifierKey = @"SparkApplicationBundleIdentifier";

static
NSString * const kSparkApplicationFlagsKey = @"SparkApplicationFlags";

NSString * const SparkApplicationDidChangeEnabledNotification = @"SparkApplicationDidChangeEnabled";

@interface SparkSystemApplication : SparkApplication

@end

@interface SparkApplication ()
- (instancetype)initWithCoder:(NSCoder *)coder;
- (instancetype)initWithSerializedValues:(NSDictionary *)plist;
@end

@implementation SparkApplication {
@private
  struct _sp_appFlags {
    unsigned int disabled:1;
    unsigned int reserved:31;
  } sp_appFlags;
}

+ (SparkApplication *)systemApplication {
  return [SparkSystemApplication objectWithName:NSLocalizedStringFromTableInBundle(@"System", nil,
                                                                                   kSparkKitBundle,
                                                                                   @"System Application Name")];
}

#pragma mark -
#pragma mark NSCoding
- (NSUInteger)encodeFlags {
  NSUInteger flags = 0;
  if (sp_appFlags.disabled) flags |= 1 << 0;
  return flags;
}

- (void)decodeFlags:(NSUInteger)flags {
  if (flags & (1 << 0)) sp_appFlags.disabled = 1;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:_URL forKey:kSparkApplicationURLKey];
  [coder encodeInteger:[self encodeFlags] forKey:kSparkApplicationFlagsKey];
  return;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    [self decodeFlags:[coder decodeIntegerForKey:kSparkApplicationFlagsKey]];
    _URL = [coder decodeObjectForKey:kSparkApplicationURLKey];
    if (!_URL) {
      WBApplication *application = [coder decodeObjectForKey:kSparkApplicationKey];
      // TODO: copy bundle identifier and path
      _bundleIdentifier = application.bundleIdentifier;
      NSString *path = application.path;
      if (path)
        _URL = [NSURL fileURLWithPath:path];
    }
  }
  return self;
}

#pragma mark NSCopying
- (instancetype)copyWithZone:(NSZone *)zone {
  SparkApplication* copy = [super copyWithZone:zone];
  copy->_URL = _URL;
  copy->_bundleIdentifier = _bundleIdentifier;
  return copy;
}

#pragma mark SparkSerialization
- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    [plist setObject:@([self encodeFlags]) forKey:kSparkApplicationFlagsKey];
    [plist setObject:_URL.absoluteString forKey:kSparkApplicationURLKey];
    [plist setObject:_bundleIdentifier forKey:kSparkApplicationBundleIdentifierKey];
    return YES;
  }
  return NO;
}

- (instancetype)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    _bundleIdentifier = plist[kSparkApplicationBundleIdentifierKey];
    if (!_bundleIdentifier) {
      // Import old style application.
      _bundleIdentifier = plist[@"WBApplicationBundleID"];
      OSType sign = [plist[@"WBApplicationSignature"] unsignedIntValue];
      if (!_bundleIdentifier && sign) {
        CFURLRef ref = NULL;
        if (noErr == LSFindApplicationForInfo(sign, NULL, NULL, NULL, &ref)) {
          _URL = SPXCFURLBridgingRelease(ref);
          _bundleIdentifier = [NSBundle bundleWithURL:_URL].bundleIdentifier;
        }
      }
      if (!_bundleIdentifier)
        return nil;
      if (!_URL) {
        _URL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:_bundleIdentifier];
        if (!_URL)
          return nil;
      }
    } else {
      NSString *url = plist[kSparkApplicationURLKey];
      _URL = url ? [NSURL URLWithString:url] : nil;
    }
    [self decodeFlags:[plist[kSparkApplicationFlagsKey] integerValue]];
    /* Update name and icon */
    if (_URL) {
      NSString *name = nil;
      if ([_URL getResourceValue:&name forKey:NSURLLocalizedNameKey error:NULL])
        self.name = name;
      /* Reset icon, it will be lazy load later */
      self.icon = nil;
    }
  }
  return self;
}

#pragma mark -
#pragma mark Init & Dealloc Methods
- (instancetype)initWithURL:(NSURL *)anURL {
  if (self = [super initWithName:nil icon:nil]) {
    self.URL = anURL;
    if (!_bundleIdentifier) {
      SPXDebug(@"Invalid app at path: %@", anURL);
      return nil;
    }
  }
  return self;
}

- (BOOL)isEqual:(id)object {
  if (self == object)
    return YES;
  else if ([object isKindOfClass:[SparkApplication class]])
    return [_bundleIdentifier isEqual:((SparkApplication *)object)->_bundleIdentifier];
  else return NO;
}

- (NSUInteger)hash {
  return [_bundleIdentifier hash];
}

#pragma mark -
#pragma mark Accessors
- (void)setURL:(NSURL *)anURL {
  _URL = anURL;
  _bundleIdentifier = SPXCFToNSString(_URL ? WBLSCopyBundleIdentifierForURL(SPXNSToCFURL(_URL)) : nil);

  NSString *name = nil;
  if ([_URL getResourceValue:&name forKey:NSURLNameKey error:NULL])
    self.name = name;
  else
    self.name = [_URL lastPathComponent];
  /* Reset icon data */
  self.icon = nil;
}

/* Loading workspace icon is slow, so use lazy loading */
- (NSImage *)icon {
  if (![self hasIcon]) {
    /* Try to set workspace icon */
    if (_URL)
      self.icon = [[NSWorkspace sharedWorkspace] iconForFile:[_URL path]];

    /* If failed and cached icon invalid, set default icon */
    if (![self hasIcon])
      self.icon = [NSImage imageNamed:@"Application" inBundle:kSparkKitBundle];
  }
  return [super icon];
}

- (BOOL)shouldSaveIcon {
  return NO;
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
  bool disabled = SPXFlagTestAndSet(sp_appFlags.disabled, !flag);
  if (disabled != sp_appFlags.disabled) {
    [[self.library.undoManager prepareWithInvocationTarget:self] setEnabled:sp_appFlags.disabled];
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

- (instancetype)initWithSerializedValues:(NSDictionary *)plist {
  return nil;
}

#pragma mark -
#pragma mark Init & Dealloc Methods
- (instancetype)initWithPath:(NSString *)path {
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

//@implementation SparkApplication (SparkExport)
//
//- (id)initFromExternalRepresentation:(id)rep {
//  WBApplicationIdentifier aid = kWBApplicationBundleIdentifier;
//  NSString *value = [rep objectForKey:@"identifier"];
//  if (!value) {
//    value = [rep objectForKey:@"signature"];
//    aid = kWBApplicationOSType;
//  }
//  if (!value) {
//    [self release];
//    return nil;
//  } 
//  WBApplication *app = [WBApplication applicationWithName:nil identifier:value idType:aid];
//  if (app) {
//    NSString *name = [app name];
//    if (!name) name = [rep objectForKey:@"name"];
//    
//    if (self = [super initWithName:name icon:nil]) {
//      _application = [app retain];
//    }
//  }
//  return self;
//}
//
//- (id)externalRepresentation {
//  NSMutableDictionary *plist = [NSMutableDictionary dictionary];
//  
//  WBApplication *app = [self application];
//  NSString *path = [app path];
//  switch ([app idType]) {
//    case kWBApplicationOSType:
//      [plist setObject:[app identifier] forKey:@"signature"];
//      if (path) {
//        NSString *bundle = (id)WBLSCopyBundleIdentifierForPath((CFStringRef)path);
//        if (bundle) {
//          [plist setObject:bundle forKey:@"identifier"];
//          [bundle release];
//        }
//      }
//        break;
//    case kWBApplicationBundleIdentifier:
//      [plist setObject:[app identifier] forKey:@"identifier"];
//      if (path) {
//        OSType creator = WBLSGetSignatureForPath((CFStringRef)path);
//        if (creator && creator != kUnknownType)
//          [plist setObject:WBStringForOSType(creator) forKey:@"signature"];
//      }
//        break;
//    case kWBApplicationUndefinedType:
//      plist = nil;
//      break;
//  }  
//  if (plist && [self name]) {
//    [plist setObject:[self name] forKey:@"name"];
//  }
//  return plist;
//}
//
//@end

#pragma mark -
#pragma mark ShadowKit Extension
static
NSString * const kWBApplicationNameKey = @"WBApplicationName";

static
NSString * const kWBApplicationBundleIDKey = @"WBApplicationBundleID";
static
NSString * const kWBApplicationSignatureKey = @"WBApplicationSignature";

@implementation WBApplication (SparkSerialization)

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super init]) {
    /* Compatibility with Library version 1.0 */
    if (plist[@"SparkApplication"] || plist[@"SKApplicationType"]) {
      NSUInteger type = 0;
      NSString *identifier = nil;  
      if (plist[@"SparkApplication"]) {
        plist = plist[@"SparkApplication"];
        identifier = plist[@"Identifier"];
        type = [plist[@"IDType"] integerValue];
      } else {
        identifier = plist[@"SKApplicationIdentifier"];
        type = [plist[@"SKApplicationType"] integerValue];
      }
      
      switch (type) {
        case 1:
          [self setSignature:WBOSTypeFromString(identifier)];
          break;
        case 2:
          [self setBundleIdentifier:identifier];
          break;
      }
    } else {
      /* Current version */
      NSString *bundle = plist[kWBApplicationBundleIDKey];
      OSType sign = [plist[kWBApplicationSignatureKey] unsignedIntValue];
      
      [self setSignature:sign bundleIdentifier:bundle];
    }
    
    [self setName:plist[kWBApplicationNameKey]];
  }
  return self;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([self isValid]) {
    if ([self name])
      [plist setObject:[self name] forKey:kWBApplicationNameKey];
    
    OSType sign = [self signature];
    NSString *bundle = [self bundleIdentifier];
    if (bundle) [plist setObject:bundle forKey:kWBApplicationBundleIDKey];
    if (sign) [plist setObject:@(sign) forKey:kWBApplicationSignatureKey];
  }
  return YES;
}

@end

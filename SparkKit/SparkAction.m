//
//  SparkAction.m
//  SparkKit
//
//  Created by Fox on 31/08/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkAction.h>
#import <HotKeyToolKit/HotKeyToolKit.h>
#import <ShadowKit/SKImageUtils.h>

#import <SparkKit/SparkActionLibrary.h>
#import <SparkKit/SparkActionLoader.h>
#import <SparkKit/SparkConstantes.h>
#import <SparkKit/Spark_Private.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkHotKey.h>


#define ICON_SIZE		16

static NSString * const kSparkActionVersionKey = @"Version";
static NSString * const kSparkActionIsCustomKey = @"IsCustom";
static NSString * const kSparkActionCategorieKey = @"Categorie";
static NSString * const kSparkActionShortDescriptionKey = @"ShortDescription";

const int kSparkActionVersion_1_0 = 0x100;

#pragma mark -
@implementation SparkAction

#pragma mark -
#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeBytes:(const uint8_t *)&sk_saflags length:sizeof(sk_saflags) forKey:@"SAFlags"];
  [coder encodeInt:sk_version forKey:kSparkActionVersionKey];
  if (nil != sk_categorie)
    [coder encodeObject:sk_categorie forKey:kSparkActionCategorieKey];
  if (nil != sk_shortDesc)
    [coder encodeObject:sk_shortDesc forKey:kSparkActionShortDescriptionKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    unsigned length;
    const uint8_t *buffer = [coder decodeBytesForKey:@"SAFlags" returnedLength:&length];
    memcpy(&sk_saflags, buffer, MIN(length, sizeof(sk_saflags)));
    sk_version = [coder decodeIntForKey:kSparkActionVersionKey];
    [self setCategorie:[coder decodeObjectForKey:kSparkActionCategorieKey]];
    [self setShortDescription:[coder decodeObjectForKey:kSparkActionShortDescriptionKey]];
  }
  return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
  SparkAction* copy = [super copyWithZone:zone];
  copy->sk_saflags = sk_saflags;
  copy->sk_version = sk_version;
  [copy setCategorie:sk_categorie];
  [copy setShortDescription:sk_shortDesc];
  return copy;
}

#pragma mark SparkSerialization
- (NSMutableDictionary *)propertyList {
  NSMutableDictionary *dico = [super propertyList];
  
  [dico setObject:SKBool(sk_saflags.custom) forKey:kSparkActionIsCustomKey];
  
  if ([self version])
    [dico setObject:SKInt([self version]) forKey:kSparkActionVersionKey];
  
  if (nil != sk_categorie)
    [dico setObject:sk_categorie forKey:kSparkActionCategorieKey];
  if (nil != sk_shortDesc)
    [dico setObject:sk_shortDesc forKey:kSparkActionShortDescriptionKey];
  
  return dico;
}
- (id)initFromPropertyList:(NSDictionary *)plist {
  if (self = [super initFromPropertyList:plist]) {
    id version = [plist objectForKey:kSparkActionVersionKey];
    [self setVersion:(nil != version) ? [version intValue] : kSparkActionVersion_1_0];
    
    if ([SparkLibraryObject loadUI]) {
      [self setCategorie:[plist objectForKey:kSparkActionCategorieKey]];
      [self setShortDescription:[plist objectForKey:kSparkActionShortDescriptionKey]];
    }
    
    [self setCustom:[[plist objectForKey:kSparkActionIsCustomKey] boolValue]];
//    if (![self categorie]) {
//      id plugin = [[SparkActionLoader sharedLoader] plugInForAction:self];
//      if (plugin) {
//        [self setCategorie:[plugin name]];
//      }
//    }
  }
  return self;
}


#pragma mark -
#pragma mark Init & Dealloc Methods
- (id)init {
  if (self= [super init]) {
    id plugin = [[SparkActionLoader sharedLoader] plugInForAction:self];
    if (plugin) {
      [self setCategorie:[plugin name]];
    }
  }
  return self;
}

- (void)dealloc {
  [sk_shortDesc release];
  [sk_categorie release];
  [super dealloc];
}

#pragma mark -
#pragma mark Public Methods
- (SparkAlert *)check {
  return nil;
}

- (SparkAlert *)execute {
  NSBeep();
  return nil;
}

#pragma mark -
#pragma mark Accessors
- (NSImage *)icon {
  id image;
  if (image = [super icon]) {
    return image;
  } else {
    id bundle = [NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier];
    image = [[NSImage alloc] initByReferencingFile:[bundle pathForImageResource:@"ActionIcon"]];
    return [image autorelease];
  }
}

- (void)setIcon:(NSImage *)icon {
  [super setIcon:SKResizedIcon(icon, NSMakeSize(ICON_SIZE, ICON_SIZE))];
}

- (int)version {
  return sk_version;
}
- (void)setVersion:(int)newVersion {
  sk_version = newVersion;
}

- (NSString *)categorie {
  if (!sk_categorie) {
    id plugin = [[SparkActionLoader sharedLoader] plugInForAction:self];
    if (plugin) {
      [self setCategorie:[plugin name]];
    }
  }
  return sk_categorie;
}
- (void)setCategorie:(NSString *)categorie {
  if (sk_categorie != categorie) { 
    [sk_categorie release];
    sk_categorie = [categorie copy];
  }
}

- (NSString *)shortDescription {
  return sk_shortDesc;
}
- (void)setShortDescription:(NSString *)desc {
  if (sk_shortDesc != desc) { 
    [sk_shortDesc release];
    sk_shortDesc = [desc copy];
  }
}

- (NSTimeInterval)repeatInterval {
  return 0;
}

- (SparkObjectsLibrary *)objectsLibrary {
  return [[self library] actionLibrary];
}

@end

#pragma mark -
@implementation SparkAction (Private)

- (SparkAlert *)hotKeyShouldExecuteAction:(SparkHotKey *)hotkey {
  return [self execute];
}

- (BOOL)isInvalid {
  return sk_saflags.invalid;
}
- (void)setInvalid:(BOOL)flag {
  sk_saflags.invalid = flag ? 1 : 0;
}

- (BOOL)isCustom {
  return sk_saflags.custom;
}

- (void)setCustom:(BOOL)custom {
  sk_saflags.custom = custom ? 1 : 0;
}

@end

#pragma mark -
#pragma mark Key Repeat Support Implementation

inline NSTimeInterval SparkGetDefaultKeyRepeatInterval() {
  return HKGetSystemKeyRepeatInterval();
}

@interface HKHotKeyManager (Private)
- (void)_hotKeyPressed:(HKHotKey *)key;
@end

@implementation SparkHotKeyManager

- (void)_hotKeyPressed:(HKHotKey *)key {
  id sparkKey = [key target];
  id action = [sparkKey currentAction];
  [key setKeyRepeat:(action) ? [action repeatInterval] : 0];
  [super _hotKeyPressed:key];
}

@end

#pragma mark -
@implementation _SparkIgnoreAction 

+ (id)action {
  return [[[self alloc] init] autorelease];
}

- (id)init {
  if (self = [super init]) {
    [self setName:NSLocalizedStringFromTableInBundle(@"IGNORE_ACTION_NAME",
                                                     nil, SKCurrentBundle(),
                                                     @"Ignore Action Name")];
    [self setIcon:[NSImage imageNamed:@"IgnoreAction" inBundle:SKCurrentBundle()]];
  }
  return self;
}

- (id)initFromPropertyList:(id)plist {
  if (self = [super initFromPropertyList:plist]) {
    [self setName:NSLocalizedStringFromTableInBundle(@"IGNORE_ACTION_NAME",
                                                     nil, SKCurrentBundle(),
                                                     @"Ignore Action Name")];
    [self setIcon:[NSImage imageNamed:@"IgnoreAction" inBundle:SKCurrentBundle()]];
  }
  return self;
}

- (BOOL)isCustom {
  return YES;
}

- (SparkAlert *)hotKeyShouldExecuteAction:(SparkHotKey *)hotkey {
  [hotkey sendKeystroke];
  return nil;
}

- (NSString *)categorie {
  return NSLocalizedStringFromTableInBundle(@"IGNORE_ACTION_CATEGORIE",
                                            nil, SKCurrentBundle(),
                                            @"Ignore Action categorie");
}
- (void)setCategorie:(NSString *)categorie {}

- (NSString *)shortDescription {
  return NSLocalizedStringFromTableInBundle(@"IGNORE_ACTION_DESC",
                                            nil, SKCurrentBundle(),
                                            @"Ignore Action description");
}
- (void)setShortDescription:(NSString *)description {}

@end
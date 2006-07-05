//
//  SparkAction.m
//  SparkKit
//
//  Created by Fox on 31/08/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "SparkPrivate.h"
#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkActionLoader.h>

#import <ShadowKit/SKImageUtils.h>
#import <ShadowKit/SKAppKitExtensions.h>

#define ICON_SIZE		16

static NSString * const kSparkActionVersionKey = @"Version";
static NSString * const kSparkActionIsCustomKey = @"IsCustom";
static NSString * const kSparkActionCategorieKey = @"Categorie";
static NSString * const kSparkActionShortDescriptionKey = @"ShortDescription";

#pragma mark -
@implementation SparkAction

#pragma mark -
#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  
  UInt32 flags = 0;
  if (sp_saFlags.invalid) flags |= 1 << 0;
  if (sp_saFlags.custom) flags |= 1 << 1;
  [coder encodeInt:flags forKey:@"SAFlags"];
  [coder encodeInt:sp_version forKey:kSparkActionVersionKey];
  if (nil != sp_categorie)
    [coder encodeObject:sp_categorie forKey:kSparkActionCategorieKey];
  if (nil != sp_description)
    [coder encodeObject:sp_description forKey:kSparkActionShortDescriptionKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    UInt32 flags = [coder decodeIntForKey:@"SAFlags"];
    if (flags & (1 << 0)) sp_saFlags.invalid = 1;
    if (flags & (1 << 1)) sp_saFlags.custom = 1;
    sp_version = [coder decodeIntForKey:kSparkActionVersionKey];
    [self setCategorie:[coder decodeObjectForKey:kSparkActionCategorieKey]];
    [self setShortDescription:[coder decodeObjectForKey:kSparkActionShortDescriptionKey]];
  }
  return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
  SparkAction* copy = [super copyWithZone:zone];
  copy->sp_saFlags = sp_saFlags;
  copy->sp_version = sp_version;
  [copy setCategorie:sp_categorie];
  [copy setShortDescription:sp_description];
  return copy;
}

#pragma mark SparkSerialization
- (BOOL)serialize:(NSMutableDictionary *)plist {
  [super serialize:plist];
  [plist setObject:SKBool(sp_saFlags.custom) forKey:kSparkActionIsCustomKey];
  
  if ([self version])
    [plist setObject:SKInt([self version]) forKey:kSparkActionVersionKey];
  
  if (nil != sp_categorie)
    [plist setObject:sp_categorie forKey:kSparkActionCategorieKey];
  if (nil != sp_description)
    [plist setObject:sp_description forKey:kSparkActionShortDescriptionKey];
  
  return YES;
}
- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    id version = [plist objectForKey:kSparkActionVersionKey];
    [self setVersion:(nil != version) ? [version intValue] : kSparkActionVersion_1_0];
    
    [self setCategorie:[plist objectForKey:kSparkActionCategorieKey]];
    [self setShortDescription:[plist objectForKey:kSparkActionShortDescriptionKey]];
    
    [self setCustom:[[plist objectForKey:kSparkActionIsCustomKey] boolValue]];
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
  [sp_description release];
  [sp_categorie release];
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
  return sp_version;
}
- (void)setVersion:(int)newVersion {
  sp_version = newVersion;
}

- (NSString *)categorie {
  if (!sp_categorie) {
    id plugin = [[SparkActionLoader sharedLoader] plugInForAction:self];
    if (plugin) {
      [self setCategorie:[plugin name]];
    }
  }
  return sp_categorie;
}
- (void)setCategorie:(NSString *)categorie {
  SKSetterCopy(sp_categorie, categorie);
}

- (NSString *)shortDescription {
  return sp_description;
}
- (void)setShortDescription:(NSString *)desc {
  SKSetterCopy(sp_description, desc);
}

- (NSTimeInterval)repeatInterval {
  return 0;
}

@end

#pragma mark -
@implementation SparkAction (Private)

- (SparkAlert *)hotKeyShouldExecuteAction:(SparkHotKey *)hotkey {
  return [self execute];
}

- (BOOL)isInvalid {
  return sp_saFlags.invalid;
}
- (void)setInvalid:(BOOL)flag {
  SKSetFlag(sp_saFlags.invalid, flag);
}

- (BOOL)isCustom {
  return sp_saFlags.custom;
}

- (void)setCustom:(BOOL)flag {
  SKSetFlag(sp_saFlags.custom, flag);
}

@end

/*
#pragma mark -
@interface _SparkIgnoreAction : SparkAction {
  
}
+ (id)action;

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

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
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
*/

/*
 *  SparkAction.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SparkPrivate.h"
#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkEvent.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkEntryManager.h>
#import <SparkKit/SparkActionLoader.h>

#import WBHEADER(WBSerialization.h)

static NSString * const kSparkActionFlagsKey = @"SAFlags";
static NSString * const kSparkActionVersionKey = @"SAVersion";
static NSString * const kSparkActionCategorieKey = @"SACategorie";
static NSString * const kSparkActionDescriptionKey = @"SADescription";

#pragma mark -
@implementation SparkAction

#pragma mark Current Event
+ (BOOL)currentEventIsARepeat {
  return [[SparkEvent currentEvent] isARepeat];
}
+ (NSTimeInterval)currentEventTime {
  SparkEvent *current = [SparkEvent currentEvent];
  return current ? [current eventTime] : 0;
}

#pragma mark -
#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  
  UInt32 flags = 0;
  if (sp_saFlags.invalid) flags |= 1 << 0;
  [coder encodeBool:flags forKey:kSparkActionFlagsKey];
	WBEncodeInteger(coder, sp_version, kSparkActionVersionKey);
  if (nil != sp_categorie)
    [coder encodeObject:sp_categorie forKey:kSparkActionCategorieKey];
  if (nil != sp_description)
    [coder encodeObject:sp_description forKey:kSparkActionDescriptionKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    UInt32 flags = [coder decodeInt32ForKey:kSparkActionFlagsKey];
    if (flags & (1 << 0)) sp_saFlags.invalid = 1;
    sp_version = WBDecodeInteger(coder, kSparkActionVersionKey);
    [self setCategorie:[coder decodeObjectForKey:kSparkActionCategorieKey]];
    [self setActionDescription:[coder decodeObjectForKey:kSparkActionDescriptionKey]];
  }
  return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
  SparkAction* copy = [super copyWithZone:zone];
  copy->sp_saFlags = sp_saFlags;
  copy->sp_version = sp_version;
  
  copy->sp_categorie = [sp_categorie retain];
  copy->sp_description = [sp_description retain];
  return copy;
}

#pragma mark Spark Serialization
- (BOOL)serialize:(NSMutableDictionary *)plist {
  [super serialize:plist];
  if ([self version])
    [plist setObject:WBInteger([self version]) forKey:kSparkActionVersionKey];
  
  if (nil != sp_description)
    [plist setObject:sp_description forKey:kSparkActionDescriptionKey];

  if (nil != sp_categorie)
    [plist setObject:sp_categorie forKey:kSparkActionCategorieKey];

  return YES;
}
- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    NSNumber *version = [plist objectForKey:kSparkActionVersionKey];
    if (!version)
      version = [plist objectForKey:@"Version"];
    [self setVersion:(version) ? WBIntegerValue(version) : 0];
    
    NSString *description = [plist objectForKey:kSparkActionDescriptionKey];
    if (!description)
      description = [plist objectForKey:@"ShortDescription"];
    [self setActionDescription:description];
    
    /* Update categorie */
    if (![self categorie]) {
      [self setCategorie:[plist objectForKey:kSparkActionCategorieKey]];
    }
  }
  return self;
}


#pragma mark -
#pragma mark Init & Dealloc Methods
- (id)init {
  if (self= [super init]) {
    SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] plugInForAction:self];
    if (plugin) {
      [self setCategorie:[plugin name]];
    }
  }
  return self;
}

- (void)dealloc {
  [sp_categorie release];
  [sp_description release];
  [super dealloc];
}

#pragma mark -
#pragma mark Public Methods
- (void)setPropertiesFromAction:(SparkAction *)anAction {
  /* Copy name */
  [self setName:[anAction name]];
}

- (SparkAlert *)actionDidLoad {
  /* Compatibility */
  if ([self respondsToSelector:@selector(check)])
    return [self performSelector:@selector(check)];
  return nil;
}

- (SparkAlert *)performAction {
  if ([self respondsToSelector:@selector(execute)])
    return [self performSelector:@selector(execute)];
  else
    NSBeep();
  return nil;
}

#pragma mark -
#pragma mark Accessors
- (NSUInteger)version {
  return sp_version;
}
- (void)setVersion:(NSUInteger)newVersion {
  sp_version = newVersion;
}

- (NSString *)categorie {
  if (!sp_categorie) {
    SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] plugInForAction:self];
    if (plugin) {
      [self setCategorie:[plugin name]];
    }
  }
  return sp_categorie;
}

- (NSString *)actionDescription {
  return sp_description;
}
- (void)setActionDescription:(NSString *)desc {
  WBSetterCopy(&sp_description, desc);
}

- (BOOL)performOnKeyUp {
  return NO;
}

- (NSTimeInterval)repeatInterval {
  return 0;
}
- (NSTimeInterval)initialRepeatInterval {
  return 0; // system default
}

- (BOOL)needsToBeRunOnMainThread {
  return YES;
}
- (BOOL)supportsConcurrentRequests {
  return NO;
}

- (id)lock {
  return [self class];
}

//#pragma mark -
//@implementation SparkAction (SparkExport)
//
//- (id)initFromExternalRepresentation:(NSDictionary *)rep {
//  if (WBImplementsSelector(self, _cmd)) {
//    if (self = [super initFromExternalRepresentation:rep]) {
//      
//    }
//    return self;
//  } else {
//    return [self initWithSerializedValues:rep];
//  }
//}
//
//- (NSMutableDictionary *)externalRepresentation {
//  if (WBImplementsSelector(self, _cmd)) {
//    NSMutableDictionary *plist = [super externalRepresentation];
//    if (plist) {
//      NSString *value = [self categorie];
//      if (value)
//        [plist setObject:value forKey:@"categorie"];
//    
//      value = [self actionDescription];
//      if (value)
//        [plist setObject:value forKey:@"description"];
//    }
//    return plist;
//  } else {
//    return [[WBSerializeObject(self, NULL) mutableCopy] autorelease];
//  }
//}
//
//@end

#pragma mark -
- (id)duplicate {
  /* Copying fallback when instance does not implements copyWithZone: */
  id copy = nil;
  NSDictionary *plist = WBSerializeObject(self, NULL);
  if (plist)
    copy = WBDeserializeObject(plist, NULL);
  return copy;
}

- (BOOL)isInvalid {
  return sp_saFlags.invalid;
}
- (void)setInvalid:(BOOL)flag {
  WBFlagSet(sp_saFlags.invalid, flag);
}

- (BOOL)isPersistent {
  return NO;
}

- (void)setCategorie:(NSString *)categorie {
  WBSetterCopy(&sp_categorie, categorie);
}

/* Compatibility */
- (NSString *)shortDescription {
  return [self actionDescription];
}
- (void)setShortDescription:(NSString *)desc {
  [self setActionDescription:desc];
}

@end

#pragma mark -
@implementation SparkPlaceHolder (SparkAction)

- (NSString *)categorie {
  return [[self values] objectForKey:kSparkActionCategorieKey];
}
//- (void)setCategorie:(NSString *)categorie {}
//- (BOOL)isRegistred { return NO; }
- (BOOL)isPersistent { return NO; }

- (NSString *)actionDescription {
  return NSLocalizedStringFromTableInBundle(@"Missing Plugin", nil,
                                            kSparkKitBundle, @"Placeholder description");
}
- (void)setActionDescription:(NSString *)description {}

@end


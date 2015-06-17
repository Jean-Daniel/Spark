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
#import <SparkKit/SparkPlugin.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkEntryManager.h>
#import <SparkKit/SparkActionLoader.h>

#import <WonderBox/WBSerialization.h>

static NSString * const kSparkActionFlagsKey = @"SAFlags";
static NSString * const kSparkActionVersionKey = @"SAVersion";
static NSString * const kSparkActionCategorieKey = @"SACategorie";
static NSString * const kSparkActionDescriptionKey = @"SADescription";

@interface SparkAction (Compatibility)
- (SparkAlert *)check;
- (SparkAlert *)execute;
@end

#pragma mark -
@implementation SparkAction {
@private
  struct _sp_saFlags {
    unsigned int invalid:1;
    unsigned int :15;
  } _saFlags;

  NSString *_category;
}

@synthesize category = _category;

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
  if (_saFlags.invalid) flags |= 1 << 0;
  [coder encodeInteger:flags forKey:kSparkActionFlagsKey];
	[coder encodeInteger:_version forKey:kSparkActionVersionKey];
  if (nil != _category)
    [coder encodeObject:_category forKey:kSparkActionCategorieKey];
  if (nil != _actionDescription)
    [coder encodeObject:_actionDescription forKey:kSparkActionDescriptionKey];
  return;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    UInt32 flags = [coder decodeInt32ForKey:kSparkActionFlagsKey];
    if (flags & (1 << 0)) _saFlags.invalid = 1;
    _version = [coder decodeIntegerForKey:kSparkActionVersionKey];
    [self setCategory:[coder decodeObjectForKey:kSparkActionCategorieKey]];
    [self setActionDescription:[coder decodeObjectForKey:kSparkActionDescriptionKey]];
  }
  return self;
}

#pragma mark NSCopying
- (instancetype)copyWithZone:(NSZone *)zone {
  SparkAction* copy = [super copyWithZone:zone];
  copy->_saFlags = _saFlags;
  copy->_version = _version;
  
  copy->_category = _category;
  copy->_actionDescription = _actionDescription;
  return copy;
}

#pragma mark Spark Serialization
- (BOOL)serialize:(NSMutableDictionary *)plist {
  [super serialize:plist];
  if ([self version])
    [plist setObject:@([self version]) forKey:kSparkActionVersionKey];
  
  if (nil != _actionDescription)
    [plist setObject:_actionDescription forKey:kSparkActionDescriptionKey];

  if (nil != _category)
    [plist setObject:_category forKey:kSparkActionCategorieKey];

  return YES;
}

- (instancetype)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    NSNumber *version = [plist objectForKey:kSparkActionVersionKey];
    if (!version)
      version = [plist objectForKey:@"Version"];
    [self setVersion:(version) ? [version integerValue] : 0];
    
    NSString *description = [plist objectForKey:kSparkActionDescriptionKey];
    if (!description)
      description = [plist objectForKey:@"ShortDescription"];
    [self setActionDescription:description];
    
    /* Update categorie */
    if (!self.category) {
      [self setCategory:[plist objectForKey:kSparkActionCategorieKey]];
    }
  }
  return self;
}

#pragma mark -
#pragma mark Init & Dealloc Methods
- (instancetype)init {
  if (self= [super init]) {
    SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] plugInForAction:self];
    if (plugin) {
      [self setCategory:[plugin name]];
    }
  }
  return self;
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
- (NSString *)category {
  if (!_category) {
    SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] plugInForAction:self];
    if (plugin) {
      [self setCategory:[plugin name]];
    }
  }
  return _category;
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
- (instancetype)duplicate {
  /* Copying fallback when instance does not implements copyWithZone: */
  id copy = nil;
  NSDictionary *plist = WBSerializeObject(self, NULL);
  if (plist)
    copy = WBDeserializeObject(plist, NULL);
  return copy;
}

- (BOOL)isInvalid {
  return _saFlags.invalid;
}
- (void)setInvalid:(BOOL)flag {
  SPXFlagSet(_saFlags.invalid, flag);
}

- (BOOL)isPersistent {
  return NO;
}

/* Compatibility */
- (NSString *)categorie {
  return self.category;
}
- (void)setCategorie:(NSString *)categorie {
  self.category = categorie;
}

- (NSString *)shortDescription {
  return self.actionDescription;
}
- (void)setShortDescription:(NSString *)desc {
  self.actionDescription = desc;
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


/*
 *  SparkBuiltInAction.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkBuiltInAction.h>

#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkFunctions.h>

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKAEFunctions.h>
#import <ShadowKit/SKAppKitExtensions.h>
#import <ShadowKit/SKProcessFunctions.h>

static 
NSImage *_SparkSDActionIcon(SparkBuiltInAction *action);
static
NSString *_SparkActionDescription(SparkBuiltInAction *action);

@implementation SparkBuiltInActionPlugin

- (void)loadSparkAction:(SparkBuiltInAction *)action toEdit:(BOOL)flag {
  [self setAction:[action action]];    
}

#pragma mark -
- (OSType)action {
  return [(SparkBuiltInAction *)[self sparkAction] action];
}
- (void)setAction:(OSType)action {
  /* First update action */
  [(SparkBuiltInAction *)[self sparkAction] setAction:action];
  /* Then update placeholder */
  [[uiName cell] setPlaceholderString:_SparkActionDescription([self sparkAction]) ? : @""];
  switch (action) {
    case kSparkSDActionSwitchListStatus:
      [uiLists setHidden:NO];
      [uiLabel setHidden:NO];
      [uiLists setEnabled:YES];
      break;
    default:
      [uiLists setHidden:YES];
      [uiLabel setHidden:YES];
      [uiLists setEnabled:NO];
      break;
  }
}

#pragma mark -
+ (Class)actionClass {
  return [SparkBuiltInAction class];
}

+ (NSString *)plugInName {
  return NSLocalizedStringFromTableInBundle(@"Spark", nil, kSparkKitBundle, @"Spark Built-in Plugin name");
}

+ (NSImage *)plugInIcon {
  return [NSImage imageNamed:@"spark" inBundle:kSparkKitBundle];
}

+ (NSString *)helpFile {
  return nil;
}

+ (NSString *)nibPath {
  return [kSparkKitBundle pathForResource:@"SparkPlugin" ofType:@"nib"];
}

/* default status */
+ (BOOL)isEnabled {
  return NO;
}

+ (NSString *)identifier {
  return @"org.shadowlab.spark.plugin.spark";
}

/* Returns the version string */
+ (NSString *)versionString {
  return @"1.0";
}

@end

#pragma mark -


@implementation SparkBuiltInAction

static
NSImage *SparkDaemonStatusIcon(BOOL status) {
  static NSImage *__enabled = nil, *__disabled = nil;
  if (!__enabled) {
    __enabled = [[NSImage imageNamed:@"enabled" inBundle:kSparkKitBundle] retain];
    __disabled = [[NSImage imageNamed:@"disabled" inBundle:kSparkKitBundle] retain];
  }
  return status ? __enabled : __disabled;
}

- (id)copyWithZone:(NSZone *)aZone {
  SparkBuiltInAction *copy = [super copyWithZone:aZone];
  copy->sp_list = sp_list;
  return copy;
}

- (id)init {
  if (self = [super init]) {
    sp_action = kSparkSDActionLaunchEditor;
  }
  return self;
}

#pragma mark -
- (BOOL)isPersistent {
  return kSparkSDActionSwitchStatus == sp_action;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    if (kSparkSDActionSwitchListStatus == sp_action)
      [plist setObject:SKUInteger(sp_list) forKey:@"SparkListUID"];
    [plist setObject:SKStringForOSType(sp_action) forKey:@"SparkDaemonAction"];
    return YES;
  }
  return NO;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    [self setAction:SKOSTypeFromString([plist objectForKey:@"SparkDaemonAction"])];
    if (kSparkSDActionSwitchListStatus == sp_action)
      sp_list = [[plist objectForKey:@"SparkListUID"] unsignedIntValue];
    /* Update description */
    NSString *desc = _SparkActionDescription(self);
    if (desc)
      [self setActionDescription:desc];
  }
  return self;
}

- (SparkAlert *)actionDidLoad {
  return nil;
}

static
void SparkSDActionToggleDaemonStatus() {
  /* MUST use kCurrentProcess, else the event will be handle in the event loop => dead lock */
  ProcessSerialNumber psn = {0, kCurrentProcess};
  if (psn.lowLongOfPSN != kNoProcess) {
    Boolean status = FALSE;
    AppleEvent aevt = SKAEEmptyDesc();
    
    OSStatus err = SKAECreateEventWithTargetProcess(&psn, kAECoreSuite, kAEGetData, &aevt);
    require_noerr(err, bail);
    
    err = SKAESetStandardAttributes(&aevt);
    require_noerr(err, bail);
    
    err = SKAEAddPropertyObjectSpecifier(&aevt, keyDirectObject, typeBoolean, 'pSta', NULL);
    require_noerr(err, bail);
    
    err = SKAESendEventReturnBoolean(&aevt, &status);
    require_noerr(err, bail);
    SKAEDisposeDesc(&aevt);
    
    err = SKAECreateEventWithTargetProcess(&psn, kAECoreSuite, kAESetData, &aevt);
    require_noerr(err, bail);
    
    err = SKAESetStandardAttributes(&aevt);
    require_noerr(err, bail);
    
    err = SKAEAddPropertyObjectSpecifier(&aevt, keyDirectObject, typeBoolean, 'pSta', NULL);
    require_noerr(err, bail);
    
    err = SKAEAddBoolean(&aevt, keyAEData, !status);
    require_noerr(err, bail);
    
    err = SKAESendEventNoReply(&aevt);
    require_noerr(err, bail);
    
    SparkNotificationDisplayImage(SparkDaemonStatusIcon(!status), -1);
bail:
    SKAEDisposeDesc(&aevt);
  }
}

- (SparkAlert *)performAction {
  switch (sp_action) {
    case kSparkSDActionSwitchStatus:
      SparkSDActionToggleDaemonStatus();
      break;
    case kSparkSDActionLaunchEditor:
      SparkLaunchEditor();
      break;
    default:
      NSBeep();
  }
  return nil;
}

- (BOOL)shouldSaveIcon {
  return NO;
}
/* Icon lazy loading */
- (NSImage *)icon {
  NSImage *icon = [super icon];
  if (!icon) {
    icon = _SparkSDActionIcon(self);
    [super setIcon:icon];
  }
  return icon;
}

#pragma mark -
- (OSType)action {
  return sp_action;
}
- (void)setAction:(OSType)anAction {
  sp_action = anAction;
}

- (SparkList *)list {
  return [[self library] listWithUID:sp_list];
}

@end

#pragma mark -
NSImage *_SparkSDActionIcon(SparkBuiltInAction *action) {
  NSString *icon = nil;
  switch ([action action]) {
    case kSparkSDActionLaunchEditor:
      icon = @"spark-editor";
      break;
    case kSparkSDActionSwitchStatus:
      icon = @"switch-status";
      break;
    case kSparkSDActionSwitchListStatus:
      icon = @"SimpleList";
      break;
  }
  return icon ? [NSImage imageNamed:icon inBundle:kSparkKitBundle] : nil;
}

NSString *_SparkActionDescription(SparkBuiltInAction *action) {
  NSString *str = nil;
  switch ([action action]) {
    case kSparkSDActionLaunchEditor:
      str = NSLocalizedStringFromTableInBundle(@"Open Spark Editor", nil,
                                               kSparkKitBundle, @"Spark Built-in Plugin description");
      break;
    case kSparkSDActionSwitchStatus:
      str = NSLocalizedStringFromTableInBundle(@"Enable/Disable Spark", nil, 
                                               kSparkKitBundle, @"Spark Built-in Plugin description");
      break;
    case kSparkSDActionSwitchListStatus: {
      NSString *name = [[action list] name];
      if (name) {
        NSString *fmt = NSLocalizedStringFromTableInBundle(@"Enable/Disable Spark List \"%@\"", nil, 
                                                           kSparkKitBundle, @"Spark Built-in Plugin description (%@ => list name)");
        str = [NSString stringWithFormat:fmt, name];
      } else {
        str = NSLocalizedStringFromTableInBundle(@"Enable/Disable Spark List ...", nil, 
                                                 kSparkKitBundle, @"Spark Built-in Plugin description");
      }
    }
      break;
  }
  return str;
}


//
//  SparkBuiltInAction.m
//  SparkKit
//
//  Created by Grayfox on 06/11/06.
//  Copyright 2006 Adamentium. All rights reserved.
//

#import <SparkKit/SparkBuiltInAction.h>

#import <SparkKit/SparkFunctions.h>

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKAEFunctions.h>
#import <ShadowKit/SKAppKitExtensions.h>
#import <ShadowKit/SKProcessFunctions.h>

@implementation SparkBuiltInActionPlugin

+ (Class)actionClass {
  return [SparkBuiltInAction class];
}

+ (NSString *)plugInName {
  return @"Spark";
}

+ (NSImage *)plugInIcon {
  return [NSImage imageNamed:@"spark" inBundle:SKCurrentBundle()];
}

+ (NSString *)helpFile {
  return nil;
}

+ (NSString *)nibPath {
  return [SKCurrentBundle() pathForResource:@"SparkPlugin" ofType:@"nib"];
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
static 
NSImage *SparkSDActionIcon(SparkBuiltInAction *action) {
  NSString *icon = nil;
  switch ([action action]) {
    case kSparkSDActionLaunchEditor:
      icon = @"spark";
      break;
    case kSparkSDActionSwitchStatus:
      icon = @"switch-status";
      break;
    case kSparkSDActionSwitchListStatus:
      icon = @"SimpleList";
      break;
  }
  return icon ? [NSImage imageNamed:icon inBundle:[NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier]] : nil;
}

@implementation SparkBuiltInAction

static
NSImage *SparkDaemonStatusIcon(BOOL status) {
  static NSImage *__enabled = nil, *__disabled = nil;
  if (!__enabled) {
    __enabled = [[NSImage imageNamed:@"enabled" inBundle:[NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier]] retain];
    __disabled = [[NSImage imageNamed:@"disabled" inBundle:[NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier]] retain];
  }
  return status ? __enabled : __disabled;
}

- (id)copyWithZone:(NSZone *)aZone {
  SparkBuiltInAction *copy = [super copyWithZone:aZone];
  copy->sp_list = [sp_list retain];
  return copy;
}

- (id)init {
  if (self = [super init]) {
    sp_action = kSparkSDActionLaunchEditor;
  }
  return self;
}

#pragma mark -
- (BOOL)isPermanent {
  return kSparkSDActionSwitchStatus == sp_action;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    [plist setObject:SKStringForOSType(sp_action) forKey:@"SparkDaemonAction"];
    return YES;
  }
  return NO;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    [self setAction:SKOSTypeFromString([plist objectForKey:@"SparkDaemonAction"])];
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
    
    err = SKAEAddMagnitude(&aevt);
    require_noerr(err, bail);
    
    err = SKAEAddPropertyObjectSpecifier(&aevt, keyDirectObject, typeBoolean, 'pSta', NULL);
    require_noerr(err, bail);
    
    err = SKAESendEventReturnBoolean(&aevt, &status);
    require_noerr(err, bail);
    SKAEDisposeDesc(&aevt);
    
    err = SKAECreateEventWithTargetProcess(&psn, kAECoreSuite, kAESetData, &aevt);
    require_noerr(err, bail);
    
    err = SKAEAddMagnitude(&aevt);
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
    icon = SparkSDActionIcon(self);
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

@end


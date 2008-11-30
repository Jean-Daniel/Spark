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

#import WBHEADER(WBAEFunctions.h)
#import WBHEADER(NSImage+WonderBox.h)
#import WBHEADER(WBProcessFunctions.h)
#import WBHEADER(WonderBoxFunctions.h)

#import "SparkLibraryPrivate.h"

#define SparkBuitInPluginVersion @"1.0"

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
		case kSparkSDActionExchangeListStatus:
			[uiLists2 setHidden:NO];
			[uiLists2 setEnabled:YES];
			// fall
    case kSparkSDActionSwitchListStatus:
      [uiLists setHidden:NO];
      [uiLabel setHidden:NO];
      [uiLists setEnabled:YES];
      break;
    default:
      [uiLists setHidden:YES];
      [uiLabel setHidden:YES];
      [uiLists setEnabled:NO];
			
			[uiLists2 setHidden:YES];
			[uiLists2 setEnabled:NO];
      break;
  }
}

#pragma mark -
static
NSInteger _SparkGroupCompare(SparkObject *o1, SparkObject *o2, void *ctxt) {
  return [[o1 name] caseInsensitiveCompare:[o2 name]];
}

/* group list */
- (void)pluginViewWillBecomeVisible {
  // refresh menus
  [uiLists removeAllItems];
  [uiLists2 removeAllItems];
  
  NSArray *groups = [[SparkActiveLibrary() listSet] objects];
  groups = [groups sortedArrayUsingFunction:_SparkGroupCompare context:nil];

  for (NSUInteger idx = 0, count = [groups count]; idx < count; idx++) {
    SparkObject *group = [groups objectAtIndex:idx];
    NSMenuItem *item = [[uiLists menu] addItemWithTitle:[group name] action:nil keyEquivalent:@""];
    //[item setImage:[group icon]];
    item = [[uiLists2 menu] addItemWithTitle:[group name] action:nil keyEquivalent:@""];
    //[item setImage:[group icon]];
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
  return SparkBuitInPluginVersion;
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
    if (kSparkSDActionSwitchListStatus == sp_action || kSparkSDActionExchangeListStatus == sp_action)
      [plist setObject:WBUInteger(sp_list) forKey:@"SparkListUID"];
		if (kSparkSDActionExchangeListStatus == sp_action)
			[plist setObject:WBUInteger(sp_list2) forKey:@"SparkSecondListUID"];
		
    [plist setObject:WBStringForOSType(sp_action) forKey:@"SparkDaemonAction"];
    return YES;
  }
  return NO;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    [self setAction:WBOSTypeFromString([plist objectForKey:@"SparkDaemonAction"])];
    if (kSparkSDActionSwitchListStatus == sp_action || kSparkSDActionExchangeListStatus == sp_action)
      sp_list = WBUIntegerValue([plist objectForKey:@"SparkListUID"]);
    if (kSparkSDActionExchangeListStatus == sp_action)
      sp_list2 = WBUIntegerValue([plist objectForKey:@"SparkSecondListUID"]);
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
void SparkSDActionToggleDaemonStatus(void) {
  /* MUST use kCurrentProcess to direct dispatch, else the event will be handle in the event loop => dead lock */
  ProcessSerialNumber psn = {0, kCurrentProcess};
  if (psn.lowLongOfPSN != kNoProcess) {
    Boolean status = FALSE;
    AppleEvent aevt = WBAEEmptyDesc();
    
    OSStatus err = WBAECreateEventWithTargetProcess(&psn, kAECoreSuite, kAEGetData, &aevt);
    require_noerr(err, bail);
    
    err = WBAESetStandardAttributes(&aevt);
    require_noerr(err, bail);
    
    err = WBAEAddPropertyObjectSpecifier(&aevt, keyDirectObject, typeBoolean, 'pSta', NULL);
    require_noerr(err, bail);
    
    err = WBAESendEventReturnBoolean(&aevt, &status);
    require_noerr(err, bail);
    WBAEDisposeDesc(&aevt);
    
    err = WBAECreateEventWithTargetProcess(&psn, kAECoreSuite, kAESetData, &aevt);
    require_noerr(err, bail);
    
    err = WBAESetStandardAttributes(&aevt);
    require_noerr(err, bail);
    
    err = WBAEAddPropertyObjectSpecifier(&aevt, keyDirectObject, typeBoolean, 'pSta', NULL);
    require_noerr(err, bail);
    
    err = WBAEAddBoolean(&aevt, keyAEData, !status);
    require_noerr(err, bail);
    
    err = WBAESendEventNoReply(&aevt);
    require_noerr(err, bail);
    
    SparkNotificationDisplayImage(SparkDaemonStatusIcon(!status), -1);
  bail:
    WBAEDisposeDesc(&aevt);
  }
}

- (void)toggleStatus {
	
}

- (void)exchangeStatus {
	
}

- (SparkAlert *)performAction {
  switch (sp_action) {
    case kSparkSDActionSwitchStatus:
      SparkSDActionToggleDaemonStatus();
      break;
    case kSparkSDActionLaunchEditor:
      SparkLaunchEditor();
      break;
		case kSparkSDActionSwitchListStatus:
			[self toggleStatus];
		case kSparkSDActionExchangeListStatus:
			[self exchangeStatus];
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

- (SparkList *)otherList {
	return [[self library] listWithUID:sp_list2];
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
		case kSparkSDActionExchangeListStatus:
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
		case kSparkSDActionExchangeListStatus: {
      NSString *name = [[action list] name];
			NSString *name2 = [[action otherList] name];
      if (name && name2) {
        NSString *fmt = NSLocalizedStringFromTableInBundle(@"Exchange '%@' and '%@' status", nil, 
                                                           kSparkKitBundle, @"Spark Built-in Plugin description (%@ => list name, %@ => other list name)");
        str = [NSString stringWithFormat:fmt, name, name2];
      } else {
        str = NSLocalizedStringFromTableInBundle(@"Exchange Spark Group status ...", nil, 
                                                 kSparkKitBundle, @"Spark Built-in Plugin description");
      }
    }
      break;
  }
  return str;
}


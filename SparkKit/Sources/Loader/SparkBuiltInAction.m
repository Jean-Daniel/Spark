/*
 *  SparkBuiltInAction.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkBuiltInAction.h>

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkFunctions.h>
#import <SparkKit/SparkEntryManager.h>

#import <WonderBox/WonderBox.h>

#import "SparkLibraryPrivate.h"

#define SparkBuitInPlugInVersion @"1.0"

static 
NSImage *_SparkSDActionIcon(SparkBuiltInAction *action);

static
NSString *_SparkActionDescription(SparkBuiltInAction *action);

@implementation SparkBuiltInActionPlugIn

#pragma mark -
- (void)loadSparkAction:(SparkBuiltInAction *)action toEdit:(BOOL)flag {
  [self setAction:[action action]];
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  return nil;
}

- (void)configureAction {
  SparkBuiltInAction *action = [self sparkAction];
  [action setAction:[self action]];
  switch (self.action) {
    case SparkPlugInActionExchangeListStatus:
      // set alternate list
      action.alternateList = [uiLists2 selectedItem].representedObject;
      // fall
    case SparkPlugInActionSwitchListStatus:
      // set main list
      action.list = [uiLists selectedItem].representedObject;
      break;
    default:
      break;
  }
}

#pragma mark -
- (void)setAction:(SparkPlugInAction)action {
  /* First update action */
  _action = action;
  /* Then update placeholder */
  [[uiName cell] setPlaceholderString:_SparkActionDescription([self sparkAction]) ? : @""];
  switch (action) {
		case SparkPlugInActionExchangeListStatus:
			[uiLists2 setHidden:NO];
			[uiLists2 setEnabled:YES];
			// fall
    case SparkPlugInActionSwitchListStatus:
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

- (IBAction)selectGroup:(NSPopUpButton *)sender {
  spx_trace_objc();
  //SPXSetterRetain(sp_gpr, [[sender selectedItem] representedObject]);
}
- (IBAction)selectAlternateGroup:(NSPopUpButton *)sender {
  spx_trace_objc();
  //SPXSetterRetain(sp_gpr2, [[sender selectedItem] representedObject]);
}

#pragma mark -
static
NSInteger _SparkGroupCompare(SparkObject *o1, SparkObject *o2, void *ctxt) {
  return [[o1 name] caseInsensitiveCompare:[o2 name]];
}

/* group list */
- (void)plugInViewWillBecomeVisible {
  /* save selection */
  id o1 = [[uiLists selectedItem] representedObject];
  if (!o1)
    o1 = [[self sparkAction] list];
  
  id o2 = [[uiLists2 selectedItem] representedObject];
  if (!o2)
    o2 = [[self sparkAction] alternateList];
  
  // refresh menus
  [uiLists removeAllItems];
  [uiLists2 removeAllItems];
  
  NSArray *groups = [[SparkActiveLibrary() listSet] allObjects];
  groups = [groups sortedArrayUsingFunction:_SparkGroupCompare context:nil];

  for (NSUInteger idx = 0, count = [groups count]; idx < count; idx++) {
    SparkObject *group = [groups objectAtIndex:idx];
    NSMenuItem *item = [[uiLists menu] addItemWithTitle:[group name] action:nil keyEquivalent:@""];
    [item setRepresentedObject:group];
    NSImage *icon = [[group icon] copy];
    [icon setSize:NSMakeSize(14, 14)];
    [item setImage:icon];
    
    item = [[uiLists2 menu] addItemWithTitle:[group name] action:nil keyEquivalent:@""];
    [item setRepresentedObject:group];
    icon = [[group icon] copy];
    [icon setSize:NSMakeSize(14, 14)];
    [item setImage:icon];
  }
  
  /* restore selection */
  if (o1) {
    NSInteger idx = [[uiLists menu] indexOfItemWithRepresentedObject:o1];
    if (idx >= 0)
      [uiLists selectItemAtIndex:idx];
  }
  if (o2) {
    NSInteger idx = [[uiLists2 menu] indexOfItemWithRepresentedObject:o1];
    if (idx >= 0)
      [uiLists2 selectItemAtIndex:idx];
  }
}

#pragma mark -
+ (Class)actionClass {
  return [SparkBuiltInAction class];
}

+ (NSString *)plugInName {
  return NSLocalizedStringFromTableInBundle(@"Spark", nil, SparkKitBundle(), @"Spark Built-in Plugin name");
}

+ (NSImage *)plugInIcon {
  return [NSImage imageNamed:@"spark" inBundle:SparkKitBundle()];
}

+ (NSString *)helpFile {
  return nil;
}

+ (NSString *)nibName {
  return @"SparkPlugin";
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
  return SparkBuitInPlugInVersion;
}

@end

#pragma mark -


@implementation SparkBuiltInAction {
@private
  SparkUID _listUID, _altListUID;
}

static
NSImage *SparkDaemonStatusIcon(BOOL status) {
  static NSImage *__enabled = nil, *__disabled = nil;
  if (!__enabled) {
    __enabled = [NSImage imageNamed:@"enabled" inBundle:SparkKitBundle()];
    __disabled = [NSImage imageNamed:@"disabled" inBundle:SparkKitBundle()];
  }
  return status ? __enabled : __disabled;
}

- (id)copyWithZone:(NSZone *)aZone {
  SparkBuiltInAction *copy = [super copyWithZone:aZone];
  copy->_list = _list;
  copy->_alternateList = _alternateList;
  return copy;
}

- (instancetype)init {
  if (self = [super init]) {
    _action = SparkPlugInActionLaunchEditor;
  }
  return self;
}

#pragma mark -
- (BOOL)isPersistent {
  return SparkPlugInActionSwitchStatus == _action;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    if (SparkPlugInActionSwitchListStatus == _action || SparkPlugInActionExchangeListStatus == _action)
      [plist setObject:@(_listUID) forKey:@"SparkListUID"];
		if (SparkPlugInActionExchangeListStatus == _action)
			[plist setObject:@(_altListUID) forKey:@"SparkSecondListUID"];
		
    [plist setObject:WBStringForOSType(_action) forKey:@"SparkDaemonAction"];
    return YES;
  }
  return NO;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    [self setAction:WBOSTypeFromString(plist[@"SparkDaemonAction"])];
    if (SparkPlugInActionSwitchListStatus == _action || SparkPlugInActionExchangeListStatus == _action)
      _listUID = (SparkUID)[plist[@"SparkListUID"] integerValue];
    if (SparkPlugInActionExchangeListStatus == _action)
      _altListUID = (SparkUID)[plist[@"SparkSecondListUID"] integerValue];
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

- (void)setLibrary:(SparkLibrary *)aLibrary {
  [super setLibrary:aLibrary];
  if (_listUID)
    [self setList:[aLibrary listWithUID:_listUID]];
  if (_altListUID)
    [self setAlternateList:[aLibrary listWithUID:_altListUID]];
}

static
void SparkSDActionToggleDaemonStatus(void) {
  /* MUST use kCurrentProcess to direct dispatch, else the event will be handle in the event loop => dead lock */
  Boolean status = FALSE;
  AppleEvent aevt = WBAEEmptyDesc();

  OSStatus err = WBAECreateEventWithTarget(WBAECurrentProcessTarget(), kAECoreSuite, kAEGetData, &aevt);
  spx_require_noerr(err, bail);

  err = WBAEAddPropertyObjectSpecifier(&aevt, keyDirectObject, typeBoolean, 'pSta', NULL);
  spx_require_noerr(err, bail);

  err = WBAESendEventReturnBoolean(&aevt, &status);
  spx_require_noerr(err, bail);
  WBAEDisposeDesc(&aevt);

  err = WBAECreateEventWithTarget(WBAECurrentProcessTarget(), kAECoreSuite, kAESetData, &aevt);
  spx_require_noerr(err, bail);

  err = WBAEAddPropertyObjectSpecifier(&aevt, keyDirectObject, typeBoolean, 'pSta', NULL);
  spx_require_noerr(err, bail);

  err = WBAEAddBoolean(&aevt, keyAEData, !status);
  spx_require_noerr(err, bail);

  err = WBAESendEventNoReply(&aevt);
  spx_require_noerr(err, bail);

  SparkNotificationDisplayImage(SparkDaemonStatusIcon(!status), -1);
bail:
  WBAEDisposeDesc(&aevt);
}

- (void)toggleStatus {
  NSInteger enabled = 0;
  for (SparkEntry *entry in _list) {
    if ([entry isEnabled])
      enabled++;
    else
      enabled--;
  }
  
  // if less key enabled than disabled => enable all entries.
  BOOL flag = enabled < 0; 
  SparkEntryManager *manager = [[self library] entryManager];
  for (SparkEntry *entry in _list) {
    if (flag) {
      /* avoid conflict */
      if (![manager activeEntryForTrigger:[entry trigger] application:[entry application]])
        [entry setEnabled:YES];
    } else {
      [entry setEnabled:NO];
    }
  }
}

- (void)exchangeStatus {
	
}

- (SparkAlert *)performAction {
  switch (_action) {
    case SparkPlugInActionSwitchStatus:
      SparkSDActionToggleDaemonStatus();
      break;
    case SparkPlugInActionLaunchEditor:
      SparkLaunchEditor();
      break;
		case SparkPlugInActionSwitchListStatus:
			[self toggleStatus];
		case SparkPlugInActionExchangeListStatus:
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
- (void)setList:(SparkList *)aList {
  _list = aList;
  _listUID = [aList uid];
}

- (void)setAlternateList:(SparkList *)aList {
  _alternateList = aList;
  _altListUID = [aList uid];
}

@end

#pragma mark -
NSImage *_SparkSDActionIcon(SparkBuiltInAction *action) {
  NSString *icon = nil;
  switch ([action action]) {
    case SparkPlugInActionLaunchEditor:
      icon = @"spark-editor";
      break;
    case SparkPlugInActionSwitchStatus:
      icon = @"switch-status";
      break;
    case SparkPlugInActionSwitchListStatus:
		case SparkPlugInActionExchangeListStatus:
      icon = @"SimpleList";
      break;
  }
  return icon ? [NSImage imageNamed:icon inBundle:SparkKitBundle()] : nil;
}

NSString *_SparkActionDescription(SparkBuiltInAction *action) {
  NSString *str = nil;
  switch ([action action]) {
    case SparkPlugInActionLaunchEditor:
      str = NSLocalizedStringFromTableInBundle(@"Open Spark Editor", nil,
                                               SparkKitBundle(), @"Spark Built-in Plugin description");
      break;
    case SparkPlugInActionSwitchStatus:
      str = NSLocalizedStringFromTableInBundle(@"Enable/Disable Spark", nil, 
                                               SparkKitBundle(), @"Spark Built-in Plugin description");
      break;
    case SparkPlugInActionSwitchListStatus: {
      NSString *name = [[action list] name];
      if (name) {
        NSString *fmt = NSLocalizedStringFromTableInBundle(@"Enable/Disable Spark List \"%@\"", nil, 
                                                           SparkKitBundle(), @"Spark Built-in Plugin description (%@ => list name)");
        str = [NSString stringWithFormat:fmt, name];
      } else {
        str = NSLocalizedStringFromTableInBundle(@"Enable/Disable Spark List ...", nil, 
                                                 SparkKitBundle(), @"Spark Built-in Plugin description");
      }
    }
      break;
		case SparkPlugInActionExchangeListStatus: {
      NSString *name = [[action list] name];
			NSString *name2 = [[action alternateList] name];
      if (name && name2) {
        NSString *fmt = NSLocalizedStringFromTableInBundle(@"Exchange '%@' and '%@' status", nil, 
                                                           SparkKitBundle(), @"Spark Built-in Plugin description (%@ => list name, %@ => other list name)");
        str = [NSString stringWithFormat:fmt, name, name2];
      } else {
        str = NSLocalizedStringFromTableInBundle(@"Exchange Spark Group status ...", nil, 
                                                 SparkKitBundle(), @"Spark Built-in Plugin description");
      }
    }
      break;
  }
  return str;
}


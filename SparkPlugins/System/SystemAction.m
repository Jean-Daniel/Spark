/*
 *  SystemAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "SystemAction.h"

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKAEFunctions.h>
#import <ShadowKit/SKIOKitFunctions.h>

static NSString * const 
kFastUserSwitcherPath = @"/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession";
static NSString * const 
kScreenSaverEngine = @"/System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine";

NSString * const
kSystemActionBundleIdentifier = @"org.shadowlab.spark.system";

static 
void SystemFastLogOut(void);

static 
NSString * const kSystemActionKey = @"SystemAction";
static
NSString * const kSystemConfirmKey = @"SystemConfirm";

@implementation SystemAction

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  SystemAction* copy = [super copyWithZone:zone];
  copy->sa_action = sa_action;
  copy->sa_saFlags = sa_saFlags;
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:[self action] forKey:kSystemActionKey];
  [coder encodeBool:sa_saFlags.confirm forKey:kSystemConfirmKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    [self setAction:[coder decodeIntForKey:kSystemActionKey]];
    [self setShouldConfirm:[coder decodeBoolForKey:kSystemConfirmKey]];
  }
  return self;
}

#pragma mark -
#pragma mark Required Methods.
- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    [self setAction:[[plist objectForKey:kSystemActionKey] intValue]];
    [self setShouldConfirm:[[plist objectForKey:kSystemConfirmKey] boolValue]];
    
    /* Update description */
    NSString *description = SystemActionDescription(self);
    if (description)
      [self setActionDescription:description];
  }
  return self;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    [plist setObject:SKInt([self action]) forKey:kSystemActionKey];
    [plist setObject:SKBool([self shouldConfirm]) forKey:kSystemConfirmKey];
    return YES;
  }
  return NO;
}

- (SystemActionType)action {
  return sa_action;
}

- (void)setAction:(SystemActionType)newAction {
  sa_action = newAction;
}

- (SparkAlert *)actionDidLoad {
  switch ([self action]) {
    case kSystemLogOut:
    case kSystemSleep:
    case kSystemRestart:
    case kSystemShutDown:
    case kSystemFastLogOut:
    case kSystemScreenSaver:
      /* Accessibility */
    case kSystemSwitchPolarity:
    case kSystemSwitchGrayscale:
      /* System Event */
    case kSystemEmptyTrash:
//    case kSystemMute:
//    case kSystemEject:
//    case kSystemVolumeUp:
//    case kSystemVolumeDown:
      return nil;
    default:
      return [SparkAlert alertWithMessageText:NSLocalizedStringFromTableInBundle(@"INVALID_ACTION_ALERT",
                                                                                 nil,
                                                                                 kSystemActionBundle,
                                                                                 @"Error When trying to execute but Action unknown ** Title **")
                    informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_ACTION_ALERT_MSG",
                                                                                 nil,
                                                                                 kSystemActionBundle,
                                                                                 @"Error When trying to execute but Action unknown ** Msg **")];
  }
}

- (SparkAlert *)performAction {
  switch ([self action]) {
    case kSystemLogOut:
      [self logout];
      break;
    case kSystemSleep:
      [self sleep];
      break;
    case kSystemRestart:
      [self restart];
      break;
    case kSystemShutDown:
      [self shutDown];
      break;
    case kSystemFastLogOut:
      [self fastLogout];
      break;
    case kSystemScreenSaver:
      [self screenSaver];
      break;
      /* Accessibility */
    case kSystemSwitchPolarity:
      [self togglePolarity];
      break;
    case kSystemSwitchGrayscale:
      [self toggleGray];
      break;
      
    case kSystemEmptyTrash:
      [self emptyTrash];
      break;
      
    default:
      NSBeep();
  }
  return nil;
}

#pragma mark -
extern Boolean CGDisplayUsesForceToGray();
extern void CGDisplayForceToGray(Boolean gray);

extern Boolean CGDisplayUsesInvertedPolarity();
extern void CGDisplaySetInvertedPolarity(Boolean inverted);

- (void)toggleGray {
  CGDisplayForceToGray(!CGDisplayUsesForceToGray());
}

- (void)togglePolarity {
  CGDisplaySetInvertedPolarity(!CGDisplayUsesInvertedPolarity());
}

- (void)emptyTrash {
  AppleEvent aevt = SKAEEmptyDesc();
  
  OSStatus err = SKAECreateEventWithTargetBundleID(CFSTR("com.apple.Finder"), 'fndr', 'empt', &aevt);
  require_noerr(err, bail);
  
  err = SKAEAddPropertyObjectSpecifier(&aevt, keyDirectObject, 'ctrs', 'trsh', NULL);
  require_noerr(err, bail);
  
  SKAEAddSubject(&aevt);
  SKAEAddMagnitude(&aevt);
  
  err = SKAESendEventNoReply(&aevt);
  check_noerr(err);
  
bail:
    SKAEDisposeDesc(&aevt);
}

/*
kAELogOut                     = 'logo',
kAEReallyLogOut               = 'rlgo',
kAEShowRestartDialog          = 'rrst',
kAEShowShutdownDialog         = 'rsdn'
 */

- (void)logout {
  ProcessSerialNumber psn = {0, kSystemProcess};
  SKAESendSimpleEventToProcess(&psn, kCoreEventClass, [self shouldConfirm] ? kAELogOut : kAEReallyLogOut);
}
- (void)restart {
  ProcessSerialNumber psn = {0, kSystemProcess};
  SKAESendSimpleEventToProcess(&psn, kCoreEventClass, [self shouldConfirm] ? kAEShowRestartDialog : 'rest');
}

- (void)shutDown {
  ProcessSerialNumber psn = {0, kSystemProcess};
  SKAESendSimpleEventToProcess(&psn, kCoreEventClass, [self shouldConfirm] ? kAEShowShutdownDialog : 'shut');
}

- (BOOL)shouldConfirm {
  return sa_saFlags.confirm;
}
- (void)setShouldConfirm:(BOOL)flag {
  SKSetFlag(sa_saFlags.confirm, flag);
}

- (void)sleep {
  ProcessSerialNumber psn = {0, kSystemProcess};
  SKAESendSimpleEventToProcess(&psn, kCoreEventClass, 'slep');
}
- (void)fastLogout {
  SystemFastLogOut();
}

- (void)screenSaver {
  if (SKSystemMajorVersion() >= 10 && SKSystemMinorVersion() >= 4) {
    FSRef engine;
    if ([kScreenSaverEngine getFSRef:&engine]) {
      LSLaunchFSRefSpec spec;
      memset(&spec, 0, sizeof(spec));
      spec.appRef = &engine;
      spec.launchFlags = kLSLaunchDefaults;
      LSOpenFromRefSpec(&spec, nil);
    }
  }
}

@end

static 
void SystemFastLogOut() {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:kFastUserSwitcherPath];
  [task setArguments:[NSArray arrayWithObject:@"-suspend"]];
  [task launch];
  [task waitUntilExit];
  [task release];
}

#pragma mark -
@interface PowerAction : SparkAction {
}
@end

@implementation PowerAction

SK_INLINE
OSType SystemActionFromFlag(int flag) {
  switch (flag) {
    case 0:
      return kSystemLogOut;
    case 1:
      return kSystemSleep;
    case 2:
      return kSystemRestart;
    case 3:
      return kSystemShutDown;
    case 4:
      return kSystemFastLogOut;
    case 5:
      return kSystemScreenSaver;
  }
  return 0;
}
- (id)initWithSerializedValues:(NSDictionary *)plist {
  [self release];
  SystemAction *action;
  if (action = [[SystemAction alloc] initWithSerializedValues:plist]) {
    [action setAction:SystemActionFromFlag([[plist objectForKey:@"PowerAction"] intValue])];
    [action setShouldConfirm:YES];
  }
  return action;
}

@end

NSString *SystemActionDescription(SystemAction *anAction) {
  NSString *desc = nil;
  switch ([anAction action]) {
    case kSystemLogOut:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_LOGOUT", nil, kSystemActionBundle,
                                                @"LogOut * Action Description *");
      break;
    case kSystemSleep:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_SLEEP", nil, kSystemActionBundle,
                                                @"Sleep * Action Description *");
      break;
    case kSystemRestart:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_RESTART", nil, kSystemActionBundle,
                                                @"Restart * Action Description *");
      break;
    case kSystemShutDown:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_SHUTDOWN", nil, kSystemActionBundle,
                                                @"ShutDown * Action Description *");
      break;
    case kSystemFastLogOut:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_FAST_LOGOUT", nil, kSystemActionBundle,
                                                @"Fast Logout * Action Description *");
      break;
    case kSystemScreenSaver:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_SCREEN_SAVER", nil, kSystemActionBundle,
                                                @"Screen Saver * Action Description *");
      break;
    case kSystemSwitchGrayscale:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_SWITCH_GRAYSCALE", nil, kSystemActionBundle,
                                                @"Switch Grayscale * Action Description *");
      break;
    case kSystemSwitchPolarity:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_SWITCH_POLARITY", nil, kSystemActionBundle,
                                                @"Switch Polarity * Action Description *");
      break;
    case kSystemEmptyTrash:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_EMPTY_TRASH", nil, kSystemActionBundle,
                                                @"Empty trash * Action Description *");
      break;
      //    case kSystemMute:
      //      desc = NSLocalizedStringFromTableInBundle(@"DESC_SOUND_MUTE", nil, kSystemActionBundle,
      //                                                @"Mute * Action Description *");
      //      break;
      //    case kSystemEject:
      //      desc = NSLocalizedStringFromTableInBundle(@"DESC_EJECT", nil, kSystemActionBundle,
      //                                                @"Eject * Action Description *");
      //      break;
      //    case kSystemVolumeUp:
      //      desc = NSLocalizedStringFromTableInBundle(@"DESC_SOUND_UP", nil, kSystemActionBundle,
      //                                                @"Sound up * Action Description *");
      //      break;
      //    case kSystemVolumeDown:
      //      desc = NSLocalizedStringFromTableInBundle(@"DESC_SOUND_DOWN", nil, kSystemActionBundle,
      //                                                @"Sound down * Action Description *");
      //      break;
    default:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_ERROR", nil, kSystemActionBundle,
                                                @"Error * Action Description *");
  }
  return desc;
}


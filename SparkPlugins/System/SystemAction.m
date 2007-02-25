/*
 *  SystemAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "SystemAction.h"

#import "SoundView.h"
#import "AudioOutput.h"

/* getuid() */
#include <unistd.h>

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKLSFunctions.h>
#import <ShadowKit/SKAEFunctions.h>
#import <ShadowKit/SKAppKitExtensions.h>

static NSString * const 
kFastUserSwitcherPath = @"/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession";
static NSString * const 
kScreenSaverEngine = @"/System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine";

NSString * const
kSystemActionBundleIdentifier = @"org.shadowlab.spark.system";

static 
void SystemFastLogOut(void);
static 
void SystemSwitchToUser(uid_t uid);

static
NSString * const kSystemFlagsKey = @"SystemFlags";
static 
NSString * const kSystemActionKey = @"SystemAction";

static
NSString * const kSystemUserUIDKey = @"SystemUserUID";
static
NSString * const kSystemUserNameKey = @"SystemUserName";

@implementation SystemAction

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  SystemAction* copy = [super copyWithZone:zone];
  copy->sa_action = sa_action;
  copy->sa_saFlags = sa_saFlags;
  return copy;
}

- (UInt32)encodeFlags {
  UInt32 flags = 0;
  if (sa_saFlags.notify) flags |= 1 << 0;
  if (sa_saFlags.confirm) flags |= 1 << 1;
  return flags;
}

- (void)decodeFlags:(UInt32)flags {
  if (flags & 1 << 0) sa_saFlags.notify = 1; /* bit 0 */
  if (flags & 1 << 1) sa_saFlags.confirm = 1; /* bit 1 */
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:[self action] forKey:kSystemActionKey];
  [coder encodeInt:[self encodeFlags] forKey:kSystemFlagsKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    [self setAction:[coder decodeIntForKey:kSystemActionKey]];
    [self decodeFlags:[coder decodeIntForKey:kSystemFlagsKey]];
  }
  return self;
}

#pragma mark -
#pragma mark Required Methods.
- (id)init {
  if (self = [super init]) {
    [self setVersion:0x100];
  }
  return self;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    [self setAction:[[plist objectForKey:kSystemActionKey] intValue]];
    [self decodeFlags:[[plist objectForKey:kSystemFlagsKey] unsignedIntValue]];
    
    if (kSystemSwitch == [self action]) {
      [self setUserName:[plist objectForKey:kSystemUserNameKey]];
      [self setUserID:[[plist objectForKey:kSystemUserUIDKey] unsignedIntValue]];
    }
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
    [plist setObject:SKUInt([self encodeFlags]) forKey:kSystemFlagsKey];
    
    if (kSystemSwitch == [self action] && [self userID] && [self userName]) {
      [plist setObject:SKUInt([self userID]) forKey:kSystemUserUIDKey];
      [plist setObject:[self userName] forKey:kSystemUserNameKey];
    }
    return YES;
  }
  return NO;
}

- (BOOL)shouldSaveIcon {
  return NO;
}
/* Icon lazy loading */
- (NSImage *)icon {
  NSImage *icon = [super icon];
  if (!icon) {
    icon = SystemActionIcon(self);
    [super setIcon:icon];
  }
  return icon;
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
    case kSystemSwitch:
    case kSystemScreenSaver:
      /* Accessibility */
    case kSystemSwitchPolarity:
    case kSystemSwitchGrayscale:
      /* System Event */
    case kSystemEmptyTrash:
    case kSystemKeyboardViewer:
      /* Sound */
    case kSystemVolumeUp:
    case kSystemVolumeDown:
    case kSystemVolumeMute:
      return nil;
    default:
      return [SparkAlert alertWithMessageText:NSLocalizedStringFromTableInBundle(@"INVALID_ACTION_ALERT",
                                                                                 nil,
                                                                                 kSystemActionBundle,
                                                                                 @"Error When trying to execute but Action unknown ** Title **")
                    informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_ACTION_ALERT_MSG",
                                                                                 nil,
                                                                                 kSystemActionBundle,
                                                                                 @"Error When trying to execute but Action unknown ** Msg **"), [self name]];
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
    case kSystemSwitch:
      [self switchSession];
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
    case kSystemKeyboardViewer:
      [self launchKeyboardViewer];
      
      break;
      /* Sound */
    case kSystemVolumeUp:
      [self volumeUp];
      break;
    case kSystemVolumeDown:
      [self volumeDown];
      break;
    case kSystemVolumeMute:
      [self toggleMute];
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
  
  OSStatus err = SKAECreateEventWithTargetSignature(kSparkFinderSignature, 'fndr', 'empt', &aevt);
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

- (void)launchKeyboardViewer {
  NSString *path = SKLSFindApplicationForBundleIdentifier(@"com.apple.KeyboardViewerServer");
  if (!path)
    path = @"/System/Library/Components/KeyboardViewer.component/Contents/SharedSupport/KeyboardViewerServer.app";
  if (path)
    SKLSLaunchApplicationAtPath((CFStringRef)path, kCFURLPOSIXPathStyle, kLSLaunchDefaults); 
  else
    NSBeep();
}

- (uid_t)userID {
  return sa_uid;
}
- (void)setUserID:(uid_t)uid {
  sa_uid = uid;
}

- (NSString *)userName {
  return sa_uname;
}
- (void)setUserName:(NSString *)aName {
  SKSetterRetain(sa_uname, aName);
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

- (BOOL)shouldNotify {
  return sa_saFlags.notify;
}
- (void)setShouldNotify:(BOOL)flag {
  SKSetFlag(sa_saFlags.notify, flag);
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
- (void)switchSession {
  if (0 == sa_uid) 
    SystemFastLogOut();
  else if (getuid() != sa_uid)
    SystemSwitchToUser(sa_uid);
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

#pragma mark -
#pragma mark Sound Management
static
SoundView *_SASharedSoundView() {
  static SoundView *shared = nil;
  if (!shared) {
    shared = [[SoundView alloc] initWithFrame:NSMakeRect(0, 0, 161, 156)];
  }
  return shared;
}

static NSSound *_SASharedSound() {
  static NSSound *beep = nil;
  if (!beep) {
    NSString *path = [[NSBundle bundleForClass:[SystemAction class]] pathForSoundResource:@"volume"];
    if (path)
      beep = [[NSSound alloc] initWithContentsOfFile:path byReference:YES];
  }
  return beep;
}

- (void)notifySoundChangeForDevice:(AudioDeviceID)device {
  if ([self shouldNotify]) {
    Boolean mute;
    UInt32 level = 0;
    SoundView *view = _SASharedSoundView();
    OSStatus err = AudioOutputIsMuted(device, &mute);
    if (noErr == err) {
      [view setMuted:mute];
      err = AudioOutputVolumeGetLevel(device, &level);
    }
    if (noErr == err) {
      [view setLevel:level];
      if (!mute && level > 0) {
        if (![SparkAction currentEventIsARepeat] ||
            ([SparkAction currentEventTime] - sa_start > 1)) {
          /* When repeat, play one beep per second */
          sa_start = [SparkAction currentEventTime];
          NSSound *sound = _SASharedSound();
          if (![sound isPlaying])
            [sound play];
        }
      }
      SparkNotificationDisplay(view, -1);
    }
  }
}

- (void)volumeUp {
  AudioDeviceID device;
  OSStatus err = AudioOutputGetSystemDevice(&device);
  if (noErr == err) {
    Boolean mute;
    err = AudioOutputIsMuted(device, &mute);
    if (noErr == err && mute)
      err = AudioOutputSetMuted(device, FALSE);
    if (noErr == err)
      err = AudioOutputVolumeUp(device, NULL);
  }
  if (noErr == err)
    [self notifySoundChangeForDevice:device];
}

- (void)volumeDown {
  AudioDeviceID device;
  OSStatus err = AudioOutputGetSystemDevice(&device);
  if (noErr == err) {
    Boolean mute;
    err = AudioOutputIsMuted(device, &mute);
    if (noErr == err && mute)
      err = AudioOutputSetMuted(device, FALSE);
    if (noErr == err)
      err = AudioOutputVolumeDown(device, NULL);
  }
  if (noErr == err)
    [self notifySoundChangeForDevice:device];
}

- (void)toggleMute {
  Boolean mute;
  AudioDeviceID device;
  OSStatus err = AudioOutputGetSystemDevice(&device);
  if (noErr == err) 
    err = AudioOutputIsMuted(device, &mute);
  if (noErr == err)
    err = AudioOutputSetMuted(device, !mute);
  [self notifySoundChangeForDevice:device];
}

- (NSTimeInterval)repeatInterval {
  switch (sa_action) {
    case kSystemVolumeUp:
    case kSystemVolumeDown:
      return SparkGetDefaultKeyRepeatInterval();
    default:
      return 0;
  }
}

@end

#pragma mark -
static 
void SystemFastLogOut() {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:kFastUserSwitcherPath];
  [task setArguments:[NSArray arrayWithObject:@"-suspend"]];
  [task launch];
  [task waitUntilExit];
  [task release];
}

static 
void SystemSwitchToUser(uid_t uid) {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:kFastUserSwitcherPath];
  [task setArguments:[NSArray arrayWithObjects:@"-switchToUserID", [NSString stringWithFormat:@"%u", uid], nil]];
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
      return kSystemSwitch;
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
    
    [action setVersion:0x100];
    [action setActionDescription:SystemActionDescription(action)];
  }
  return action;
}

@end

#pragma mark -
NSImage *SystemActionIcon(SystemAction *anAction) {
  NSString *icon = nil;
  switch ([anAction action]) {
    case kSystemLogOut:
      icon = @"SysLogout";
      break;
    case kSystemSwitch:
      icon = [anAction userID] ? @"SysSwitch" : @"SysLogout";
      break;
    case kSystemSleep:
      icon = @"SysSleep";
      break;
    case kSystemRestart:
      icon = @"SysRestart";
      break;
    case kSystemShutDown:
      icon = @"SysShutdown";
      break;
    case kSystemScreenSaver:
      icon = @"SysScreenSaver";
      break;
    case kSystemSwitchGrayscale:
      icon = @"SysSwitchGrayscale";
      break;
    case kSystemSwitchPolarity:
      icon = @"SysSwitchPolarity";
      break;
    case kSystemEmptyTrash:
      icon = @"SysTrash";
      break;
    case kSystemKeyboardViewer:
      icon = @"SysKeyboard";
      break;
      /* Sound */
    case kSystemVolumeUp:
      icon = @"SysVolumeUp";
      break;
    case kSystemVolumeDown:
      icon = @"SysVolumeDown";
      break;
    case kSystemVolumeMute:
      icon = @"SysMute";
      break;
  }
  return icon ? [NSImage imageNamed:icon inBundle:kSystemActionBundle] : nil;
}

NSString *SystemActionDescription(SystemAction *anAction) {
  NSString *desc = nil;
  NSString *confirm = [anAction shouldConfirm] ? 
    NSLocalizedStringFromTableInBundle(@"...", nil, kSystemActionBundle,
                                       @"Should confirm dots * Action description *") : nil;
  
  switch ([anAction action]) {
    case kSystemSleep:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_SLEEP", nil, kSystemActionBundle,
                                                @"Sleep * Action Description *");
      break;
    case kSystemLogOut:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_LOGOUT", nil, kSystemActionBundle,
                                                @"LogOut * Action Description *");
      if (confirm)
        desc = [desc stringByAppendingString:confirm];
        break;
    case kSystemRestart:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_RESTART", nil, kSystemActionBundle,
                                                @"Restart * Action Description *");
      if (confirm)
        desc = [desc stringByAppendingString:confirm];
      break;
    case kSystemShutDown:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_SHUTDOWN", nil, kSystemActionBundle,
                                                @"ShutDown * Action Description *");
      if (confirm)
        desc = [desc stringByAppendingString:confirm];
      break;
    case kSystemSwitch:
      if ([anAction userID]) {
        NSString *loc = NSLocalizedStringFromTableInBundle(@"DESC_FAST_SWITCH", nil, kSystemActionBundle,
                                                           @"Switch to * Action Description * (%@ => user name)");
        desc = [NSString stringWithFormat:loc, [anAction userName]];
      } else {
        desc = NSLocalizedStringFromTableInBundle(@"DESC_FAST_LOGOUT", nil, kSystemActionBundle,
                                                  @"Fast Logout * Action Description *");
      }
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
    case kSystemKeyboardViewer:
      desc = @"Keyboard Viewer";
      break;
      /* Sound */
    case kSystemVolumeUp:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_VOLUME_UP", nil, kSystemActionBundle,
                                                @"Volume Up * Action Description *");
      break;
    case kSystemVolumeDown:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_VOLUME_DOWN", nil, kSystemActionBundle,
                                                @"Volume Down * Action Description *");
      break;
    case kSystemVolumeMute:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_VOLUME_MUTE", nil, kSystemActionBundle,
                                                @"Volume Mute * Action Description *");
      break;
    default:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_INVALID", nil, kSystemActionBundle,
                                                @"Invalid Action * Action Description *");
  }
  return desc;
}


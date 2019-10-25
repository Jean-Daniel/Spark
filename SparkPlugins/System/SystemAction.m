/*
 *  SystemAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "SystemAction.h"

#import "SoundView.h"
#import "AudioOutput.h"

/* getuid() */
#include <unistd.h>

#import <WonderBox/WonderBox.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

static NSString * const 
kFastUserSwitcherPath = @"/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession";

static NSString * const 
kScreenSaverEngine = @"/System/Library/CoreServices/ScreenSaverEngine.app";

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

@implementation SystemAction {
  /* Switch data */
  NSTimeInterval sa_start;
  struct _sa_saFlags {
    unsigned int notify:1;
    unsigned int confirm:1;
    unsigned int feedback:1;
    unsigned int reserved:29;
  } sa_saFlags;
}

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  SystemAction* copy = [super copyWithZone:zone];
  copy->_action = _action;
  copy->_userID = _userID;
  copy->_userName = _userName;
  copy->sa_saFlags = sa_saFlags;
  return copy;
}

- (UInt32)encodeFlags {
  UInt32 flags = 0;
  if (sa_saFlags.notify) flags |= 1 << 0;
  if (sa_saFlags.confirm) flags |= 1 << 1;
  if (sa_saFlags.feedback) flags |= 1 << 2;
  return flags;
}

- (void)decodeFlags:(UInt32)flags {
  if (flags & 1 << 0) sa_saFlags.notify = 1; /* bit 0 */
  if (flags & 1 << 1) sa_saFlags.confirm = 1; /* bit 1 */
  if (flags & 1 << 2) sa_saFlags.feedback = 1; /* bit 1 */
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
    [self setAction:[plist[kSystemActionKey] intValue]];
    [self decodeFlags:[plist[kSystemFlagsKey] unsignedIntValue]];
    
    if (kSystemSwitch == [self action]) {
      [self setUserName:plist[kSystemUserNameKey]];
      [self setUserID:[plist[kSystemUserUIDKey] unsignedIntValue]];
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
    [plist setObject:@([self action]) forKey:kSystemActionKey];
    [plist setObject:@([self encodeFlags]) forKey:kSystemFlagsKey];
    
    if (kSystemSwitch == [self action] && [self userID] && [self userName]) {
      [plist setObject:@([self userID]) forKey:kSystemUserUIDKey];
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
    case kSystemEject:
    case kSystemEmptyTrash:
    case kSystemKeyboardViewer:
      /* Sound */
    case kSystemVolumeUp:
    case kSystemVolumeDown:
    case kSystemVolumeMute:
    case kSystemBrightnessUp:
    case kSystemBrightnessDown:
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
      
    case kSystemEject:
      WBHIDPostSystemDefinedEvent(kWBHIDEjectKey);
      break;
    case kSystemEmptyTrash:
      [self emptyTrash];
      break;
    case kSystemKeyboardViewer:
      [HKKeyMap showKeyboardViewer];
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
      /* Brightness */
    case kSystemBrightnessUp:
      [self brightnessUp];
      break;
    case kSystemBrightnessDown:
      [self brightnessDown];
      break;
  }
  return nil;
}

- (BOOL)needsToBeRunOnMainThread {
  return NO;
}
- (BOOL)supportsConcurrentRequests {
  return YES;
}

#pragma mark -
extern Boolean CGDisplayUsesForceToGray(void);
extern void CGDisplayForceToGray(Boolean gray);

extern Boolean CGDisplayUsesInvertedPolarity(void);
extern void CGDisplaySetInvertedPolarity(Boolean inverted);

- (void)toggleGray {
  CGDisplayForceToGray(!CGDisplayUsesForceToGray());
}

- (void)togglePolarity {
  CGDisplaySetInvertedPolarity(!CGDisplayUsesInvertedPolarity());
}

- (void)emptyTrash {
  AppleEvent aevt = WBAEEmptyDesc();
  
  OSStatus err = WBAECreateEventWithTargetBundleID(SPXNSToCFString(kSparkFinderBundleIdentifier), 'fndr', 'empt', &aevt);
  spx_require_noerr(err, bail);
  
  err = WBAEAddPropertyObjectSpecifier(&aevt, keyDirectObject, 'ctrs', 'trsh', NULL);
  spx_require_noerr(err, bail);
  
//  err = WBAESetStandardAttributes(&aevt);
//  spx_require_noerr(err, bail);
  
  err = WBAESendEventNoReply(&aevt);
  assert(err == noErr);
  
bail:
    WBAEDisposeDesc(&aevt);
}

/*
kAELogOut                     = 'logo',
kAEReallyLogOut               = 'rlgo',
kAEShowRestartDialog          = 'rrst',
kAEShowShutdownDialog         = 'rsdn'
 */

- (void)logout {
  WBAESendSimpleEventToTarget(WBAESystemTarget(), kCoreEventClass, [self shouldConfirm] ? kAELogOut : kAEReallyLogOut);
}
- (void)restart {
  WBAESendSimpleEventToTarget(WBAESystemTarget(), kCoreEventClass, [self shouldConfirm] ? kAEShowRestartDialog : 'rest');
}

- (void)shutDown {
  WBAESendSimpleEventToTarget(WBAESystemTarget(), kCoreEventClass, [self shouldConfirm] ? kAEShowShutdownDialog : 'shut');
}

- (BOOL)shouldNotify {
  return sa_saFlags.notify;
}
- (void)setShouldNotify:(BOOL)flag {
  SPXFlagSet(sa_saFlags.notify, flag);
}
- (BOOL)playFeedback {
  return sa_saFlags.feedback && [self shouldNotify];
}
- (void)setPlayFeedback:(BOOL)flag {
  SPXFlagSet(sa_saFlags.feedback, flag);
}
- (BOOL)shouldConfirm {
  return sa_saFlags.confirm;
}
- (void)setShouldConfirm:(BOOL)flag {
  SPXFlagSet(sa_saFlags.confirm, flag);
}

- (void)sleep {
  WBAESendSimpleEventToTarget(WBAESystemTarget(), kCoreEventClass, 'slep');
}
- (void)switchSession {
  if (0 == _userID)
    SystemFastLogOut();
  else if (getuid() != _userID)
    SystemSwitchToUser(_userID);
}

- (void)screenSaver {
  NSError *error = nil;
  NSURL *url = [NSURL fileURLWithPath:kScreenSaverEngine];
  if (![[NSWorkspace sharedWorkspace] launchApplicationAtURL:url options:NSWorkspaceLaunchDefault configuration:@{} error:&error]) {
    spx_log_error("failed to launch screen saver engine: %@", error);
  }
}

#pragma mark -
#pragma mark Sound Management
static
NSImage *_SASharedSoundImage(void) {
  static NSImage *shared = nil;
  if (!shared) {
    shared = [NSImage imageWithSize:CGSizeMake(170, 170) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
      CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
      _SAAudioAddVolumeImage(ctxt, false);
      CGContextSetGrayFillColor(ctxt, 0, 1);
      CGContextFillPath(ctxt);
      return YES;
    }];
    shared.template = YES;
  }
  return shared;
}

static
NSImage *_SASharedSoundMuteImage(void) {
  static NSImage *shared = nil;
  if (!shared) {
    shared = [NSImage imageWithSize:CGSizeMake(170, 170) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
      CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
      _SAAudioAddVolumeImage(ctxt, true);
      CGContextSetGrayFillColor(ctxt, 0, 1);
      CGContextFillPath(ctxt);
      return YES;
    }];
    shared.template = YES;
  }
  return shared;
}

static NSSound *_SASharedSound(void) {
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
    dispatch_async(dispatch_get_main_queue(), ^{
      NSImage *image;
      Boolean mute;
      UInt32 level = 0;
      OSStatus err = AudioOutputIsMuted(device, &mute);
      if (noErr == err && mute) {
        image = _SASharedSoundMuteImage();
      } else {
        err = AudioOutputVolumeGetLevel(device, &level);
        image = level > 0 ? _SASharedSoundImage() : _SASharedSoundMuteImage();
      }
      if (noErr == err) {
        if ([self playFeedback] && !mute && level > 0) {
          if (![SparkAction currentEventIsARepeat] ||
              ([SparkAction currentEventTime] - self->sa_start > 1)) {
            /* When repeat, play one beep per second */
            self->sa_start = [SparkAction currentEventTime];
            NSSound *sound = _SASharedSound();
            if (![sound isPlaying])
              [sound play];
          }
        }
        SparkNotificationDisplayImageWithLevel(image, (CGFloat)level / 16., -1);
      }
    });
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
  Boolean mute = FALSE;
  AudioDeviceID device;
  OSStatus err = AudioOutputGetSystemDevice(&device);
  if (noErr == err) 
    err = AudioOutputIsMuted(device, &mute);
  if (noErr == err)
    err = AudioOutputSetMuted(device, !mute);
  [self notifySoundChangeForDevice:device];
}

#pragma mark Brightness

static 
CFStringRef kSystemBrightnessKey = CFSTR("brightness");

static
NSImage *_SASharedBrightnessImage(void) {
  static NSImage *shared = nil;
  if (!shared) {
    shared = [NSImage imageWithSize:NSMakeSize(170, 170) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
      CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
      // Draw in solid black as we create a template image.
      CGContextSetGrayFillColor(ctxt, 0, 1);

      // Draw the sun center.
      CGContextAddEllipseInRect(ctxt, CGRectMake(61, 74, 48, 48));
      CGContextAddEllipseInRect(ctxt, CGRectMake(67, 80, 36, 36));
      CGContextEOFillPath(ctxt);

      CGContextTranslateCTM(ctxt, 85, 98);

      // Draw the sun radius.
      for (int idx = 0; idx < 8; ++idx) {
        CGContextMoveToPoint(ctxt, 35, 3);
        CGContextAddArc(ctxt, 53, 0, 3, M_PI_2, -M_PI_2, 1);
        CGContextAddArc(ctxt, 35, 0, 3, -M_PI_2, M_PI_2, 1);
        CGContextFillPath(ctxt);

        CGContextRotateCTM(ctxt, M_PI_4);
      }

      return YES;
    }];
    shared.template = YES;
  }
  return shared;
}

- (void)notifyBrightnessLevel:(CGFloat)level {
  if ([self shouldNotify]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      SparkNotificationDisplayImageWithLevel(_SASharedBrightnessImage(), level, -1);
    });
  }
}

+ (BOOL)supportBrightness {
  float value = 0;
  return kCGErrorSuccess == WBIODisplayGetFloatParameter(kSystemBrightnessKey, &value);
}

- (void)brightnessUp {
  float value = 0;
  OSStatus err = WBIODisplayGetFloatParameter(kSystemBrightnessKey, &value);
  if (noErr == err) {
    value *= 16;
    if (value < 16)
      value = roundf(value + 1) / 16.f;
    else
      value = 1;
    err = WBIODisplaySetFloatParameter(kSystemBrightnessKey, value);
    
    if (noErr == err)
      [self notifyBrightnessLevel:value];
  }
}

- (void)brightnessDown {
  float value = 0;
  OSStatus err = WBIODisplayGetFloatParameter(kSystemBrightnessKey, &value);
  if (noErr == err) {
    value *= 16;
    if (value > 0)
      value = roundf(value - 1) / 16.f;
    else
      value = 0;
    err = WBIODisplaySetFloatParameter(kSystemBrightnessKey, value);
    
    if (noErr == err)
      [self notifyBrightnessLevel:value];
  }
}


- (NSTimeInterval)repeatInterval {
  switch (_action) {
    case kSystemVolumeUp:
    case kSystemVolumeDown:
    case kSystemBrightnessUp:
    case kSystemBrightnessDown:
      return SparkGetDefaultKeyRepeatInterval();
    default:
      return 0;
  }
}

@end

#pragma mark -
typedef int CGSSessionID;
WB_EXPORT CGError CGSCreateLoginSession(CGSSessionID *outSession) __attribute__((weak));

static 
void SystemFastLogOut(void) {
  if (CGSCreateLoginSession) {
    CGSCreateLoginSession(NULL);
  } else {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:kFastUserSwitcherPath];
    [task setArguments:@[@"-suspend"]];
    [task launch];
    [task waitUntilExit];
  }
}

static 
void SystemSwitchToUser(uid_t uid) {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:kFastUserSwitcherPath];
  [task setArguments:@[@"-switchToUserID", [NSString stringWithFormat:@"%u", uid]]];
  [task launch];
  [task waitUntilExit];
}

#pragma mark -
@interface PowerAction : SparkAction {
}
@end

@implementation PowerAction

WB_INLINE
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
  SystemAction *action = [[SystemAction alloc] initWithSerializedValues:plist];
  if (action) {
    [action setAction:SystemActionFromFlag([plist[@"PowerAction"] intValue])];
    [action setShouldConfirm:YES];
    
    [action setVersion:0x100];
    [action setActionDescription:SystemActionDescription(action)];
    
    if (![action shouldSaveIcon]) {
      [action setIcon:nil];
    }
  }
  return (id)action;
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
    case kSystemEject:
      icon = @"SysEject";
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
      /* Brightness */
    case kSystemBrightnessUp:
    case kSystemBrightnessDown:
      icon = @"SysBrightness";
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
    case kSystemEject:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_EJECT", nil, kSystemActionBundle,
                                                @"Eject - Action Description");
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
      /* Brightness */
    case kSystemBrightnessUp:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_BRIGHTNESS_UP", nil, kSystemActionBundle,
                                                @"Brightness Up * Action Description *");      
      break;
    case kSystemBrightnessDown:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_BRIGHTNESS_DOWN", nil, kSystemActionBundle,
                                                @"Brightness Down * Action Description *");
      break;
    default:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_INVALID", nil, kSystemActionBundle,
                                                @"Invalid Action * Action Description *");
  }
  return desc;
}


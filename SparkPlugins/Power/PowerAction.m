//
//  PowerAction.m
//  Spark
//
//  Created by Fox on Wed Feb 18 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "PowerAction.h"
#import "PowerActionPlugin.h"
#import <ApplicationServices/ApplicationServices.h>

#define SYSTEM_EVENT		@"/System/Library/CoreServices/System Events.app"
#define kFastUserSwitcherPath		@"/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
#define kScreenSaverEngine			@"/System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine"

static void PowerFastLogOut();

static NSString* const kPowerActionKey = @"PowerAction";

@implementation PowerAction

#pragma mark Protocols Implementation

- (id)copyWithZone:(NSZone *)zone {
  PowerAction* copy = [super copyWithZone:zone];
  copy->_powerAction = _powerAction;
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:_powerAction forKey:kPowerActionKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    [self setPowerAction:[coder decodeIntForKey:kPowerActionKey]];
  }
  return self;
}

#pragma mark -
#pragma mark Required Methods.
- (id)initFromPropertyList:(id)plist {
  if (self = [super initFromPropertyList:plist]) {
    [self setPowerAction:[[plist objectForKey:kPowerActionKey] intValue]];
  }
  return self;
}

- (NSMutableDictionary *)propertyList {
  NSMutableDictionary *dico = [super propertyList];
  [dico setObject:SKInt([self powerAction]) forKey:kPowerActionKey];
  return dico;
}

- (int)powerAction {
  return _powerAction;
}

- (void)setPowerAction:(int)newAction {
  if (_powerAction != newAction) {
    _powerAction = newAction;
  }
}

- (SparkAlert *)check {
  switch ([self powerAction]) {
    case kPowerLogOut:
    case kPowerSleep:
    case kPowerRestart:
    case kPowerShutDown:
    case kPowerFastLogOut:
    case kPowerScreenSaver:
      return nil;
    default:
      return [SparkAlert alertWithMessageText:NSLocalizedStringFromTableInBundle(@"INVALID_ACTION_ALERT",
                                                                                 nil,
                                                                                 kPowerActionBundle,
                                                                                 @"Error When trying to execute but Action unknown ** Title **")
                    informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_ACTION_ALERT_MSG",
                                                                                 nil,
                                                                                 kPowerActionBundle,
                                                                                 @"Error When trying to execute but Action unknown ** Msg **")];
  }
}

- (SparkAlert *)execute {
  SparkAlert *alert = [self check];
  if (alert == nil) {
    switch ([self powerAction]) {
      case kPowerLogOut:
        [self logout];
        break;
      case kPowerSleep:
        [self sleep];
        break;
      case kPowerRestart:
        [self restart];
        break;
      case kPowerShutDown:
        [self shutDown];
        break;
      case kPowerFastLogOut:
        [self fastLogout];
        break;
      case kPowerScreenSaver:
        [self screenSaver];
        break;
    }
  }
  return alert;
}

#pragma mark -
- (void)launchSystemEvent {
  ProcessSerialNumber p = SKGetProcessWithSignature('sevs');
  if ( (p.highLongOfPSN == kNoProcess) && (p.lowLongOfPSN == kNoProcess)) {
    [[NSWorkspace sharedWorkspace] launchApplication:SYSTEM_EVENT showIcon:NO autolaunch:NO];
  }
}

/*
kAELogOut                     = 'logo',
kAEReallyLogOut               = 'rlgo',
kAEShowRestartDialog          = 'rrst',
kAEShowShutdownDialog         = 'rsdn'
 */
- (void)logout {
  ProcessSerialNumber psn = {0, kSystemProcess};
  ShadowAESendSimpleEventToProcess(&psn, kCoreEventClass, kAELogOut);
}

- (void)sleep {
  ProcessSerialNumber psn = {0, kSystemProcess};
  ShadowAESendSimpleEventToProcess(&psn, kCoreEventClass, 'slep');
}

- (void)restart {
  ProcessSerialNumber psn = {0, kSystemProcess};
  ShadowAESendSimpleEventToProcess(&psn, kCoreEventClass, 'rest');
}

- (void)shutDown {
  ProcessSerialNumber psn = {0, kSystemProcess};
  ShadowAESendSimpleEventToProcess(&psn, kCoreEventClass, 'shut');
}

- (void)fastLogout {
  PowerFastLogOut();
}

- (void)screenSaver {
  SInt32 macVersion;
  if (Gestalt(gestaltSystemVersion, &macVersion) == noErr && macVersion >= 0x1040) {
    FSRef engine;
    if ([kScreenSaverEngine getFSRef:&engine]) {
      LSLaunchFSRefSpec spec;
      memset(&spec, 0, sizeof(spec));
      spec.appRef = &engine;
      spec.launchFlags = kLSLaunchDefaults;
      LSOpenFromRefSpec(&spec, nil);
//      LSApplicationParameters parameters;
//      memset(&parameters, 0, sizeof(parameters));
//      parameters.application = &engine;
//      LSOpenApplication(&parameters, nil);
    }
  }
}

@end

static void PowerFastLogOut() {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:kFastUserSwitcherPath];
  [task setArguments:[NSArray arrayWithObject:@"-suspend"]];
  [task launch];
  [task waitUntilExit];
  [task release];
}

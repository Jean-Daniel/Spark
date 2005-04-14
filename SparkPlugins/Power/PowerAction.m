//
//  PowerAction.m
//  Spark
//
//  Created by Fox on Wed Feb 18 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "PowerAction.h"
#import "PowerActionPlugin.h"

#define SYSTEM_EVENT		@"/System/Library/CoreServices/System Events.app"
#define kFastUserSwitcherPath		@"/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"

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
    [self launchSystemEvent];
    switch ([self powerAction]) {
      case kPowerLogOut:
        [self sendAppleEvent:'logo'];
        break;
      case kPowerSleep:
        [self sendAppleEvent:'slep'];
        break;
      case kPowerRestart:
        [self sendAppleEvent:'rest'];
        break;
      case kPowerShutDown:
        [self sendAppleEvent:'shut'];
        break;
      case kPowerFastLogOut:
        PowerFastLogOut();
        break;
    }
  }
  return alert;
}

- (void)launchSystemEvent {
  ProcessSerialNumber p = SKGetProcessWithSignature('sevs');
  if ( (p.highLongOfPSN == kNoProcess) && (p.lowLongOfPSN == kNoProcess)) {
    [[NSWorkspace sharedWorkspace] launchApplication:SYSTEM_EVENT showIcon:NO autolaunch:NO];
  }
}

- (void)sendAppleEvent:(OSType)eventType {
  ShadowAESendSimpleEvent('sevs', 'fndr', eventType);
}

@end

void PowerFastLogOut() {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath:kFastUserSwitcherPath];
  [task setArguments:[NSArray arrayWithObject:@"-suspend"]];
  [task launch];
  [task waitUntilExit];
  [task release];
}

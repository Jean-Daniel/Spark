//
//  PowerActionPlugin.m
//  Spark
//
//  Created by Fox on Wed Feb 18 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#if defined (DEBUG)
#warning Debug defined in PowerAction!
#endif

#import "PowerActionPlugin.h"
#import "PowerAction.h"

NSString * const kPowerActionBundleIdentifier = @"org.shadowlab.spark.power";

@implementation PowerActionPlugin

- (void)bindFields {
  [nameField bind:@"value"
         toObject:self
      withKeyPath:@"sparkAction.name"
          options:[NSDictionary dictionaryWithObjectsAndKeys:
            SKBool(YES), @"NSContinuouslyUpdatesValue",
            [self shortDescription], @"NSNullPlaceholder",
            nil]];
}

- (void)loadSparkAction:(id)sparkAction toEdit:(BOOL)flag {
  [super loadSparkAction:sparkAction toEdit:flag];
  if (flag) {
    [[self undoManager] registerUndoWithTarget:sparkAction selector:@selector(setName:) object:[sparkAction name]];
    [[[self undoManager] prepareWithInvocationTarget:self] setPowerAction:[sparkAction powerAction]];

    [self setPowerAction:[sparkAction powerAction]];
  }
  [self bindFields];
}

- (NSAlert *)controllerShouldConfigureAction {
  return nil;
}

- (void)configureAction {
  PowerAction *powerAction = [self sparkAction];
  /* Set Name */
  if ([[[powerAction name] stringByTrimmingWhitespaceAndNewline] length] == 0)
    [powerAction setName:[self shortDescription]];
  NSString *iconName = nil;
  switch ([self powerAction]) {
    case kPowerLogOut:
    case kPowerFastLogOut:
      iconName = @"LogOut";
      break;
    case kPowerSleep:
      iconName = @"Sleep";
      break;
    case kPowerRestart:
      iconName = @"Restart";
      break;
    case kPowerShutDown:
      iconName = @"ShutDown";
      break;
  }
  if (iconName)
    [powerAction setIcon:[NSImage imageNamed:iconName inBundle:kPowerActionBundle]];
  [powerAction setShortDescription:[self shortDescription]];
}

#pragma mark -
- (int)powerAction {
  return [[self sparkAction] powerAction];
}

- (void)setPowerAction:(int)newAction {
  if ([self powerAction] != newAction) {
    [[self sparkAction] setPowerAction:newAction];
    [nameField unbind:@"value"];
    [self bindFields];
  }
}

- (NSString *)shortDescription {
  id desc = nil;
  switch ([self powerAction]) {
    case kPowerLogOut:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_LOGOUT", nil, kPowerActionBundle,
                                                @"LogOut * Action Description *");
      break;
    case kPowerSleep:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_SLEEP", nil, kPowerActionBundle,
                                                @"Sleep * Action Description *");
      break;
    case kPowerRestart:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_RESTART", nil, kPowerActionBundle,
                                                @"Restart * Action Description *");
      break;
    case kPowerShutDown:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_SHUTDOWN", nil, kPowerActionBundle,
                                                @"ShutDown * Action Description *");
      break;
    case kPowerFastLogOut:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_FAST_LOGOUT", nil, kPowerActionBundle,
                                                @"Fast Logout * Action Description *");
      break;
    default:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_ERROR", nil, kPowerActionBundle,
                                                @"Error * Action Description *");
  }
  return desc;
}

@end

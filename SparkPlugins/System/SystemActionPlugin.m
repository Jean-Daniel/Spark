//
//  SystemActionPlugin.m
//  Spark
//
//  Created by Fox on Wed Feb 18 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#if defined (DEBUG)
#warning Debug defined in SystemAction!
#endif

#import "SystemActionPlugin.h"
#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKAppKitExtensions.h>

volatile int SparkSystemGDBWorkaround = 0;

@implementation SystemActionPlugin

- (void)dealloc {
  ShadowTrace();
  [super dealloc];
}

- (void)awakeFromNib {
  NSMenu *menu = [actionMenu menu];
  if (SKSystemMajorVersion() >= 10 && SKSystemMinorVersion() >= 4) {
    /* Screen saver work only with MAC OS X.4 and later */
    NSMenuItem *item = [NSMenuItem separatorItem];
    [item setTag:-1];
    [menu addItem:item];
    
    item = [[NSMenuItem alloc] initWithTitle:@"Screen Saver" action:nil keyEquivalent:@""];
    [item setTag:kSystemScreenSaver];
    [menu addItem:item];
    [item release];
  }
}

- (void)loadSparkAction:(SystemAction *)sparkAction toEdit:(BOOL)flag {
  if (flag) {
    if ([sparkAction name])
      [nameField setStringValue:[sparkAction name]];
    /* Force update menu + placeholder */
    [self setAction:[sparkAction action]];
  }
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  return [super sparkEditorShouldConfigureAction];
}

- (void)configureAction {
  SystemAction *action = [self sparkAction];
  
  /* Set Name */
  NSString *name = [nameField stringValue];
  if ([[name stringByTrimmingWhitespaceAndNewline] length] == 0)
    [action setName:[self actionDescription]];
  else 
    [action setName:name];
  
  NSString *iconName = nil;
  switch ([self action]) {
    case kSystemLogOut:
    case kSystemFastLogOut:
      iconName = @"LogOut";
      break;
    case kSystemSleep:
      iconName = @"Sleep";
      break;
    case kSystemRestart:
      iconName = @"Restart";
      break;
    case kSystemShutDown:
      iconName = @"ShutDown";
      break;
    case kSystemScreenSaver:
      iconName = @"ScreenSaver";
      break;
    case kSystemSwitchGrayscale:
      iconName = @"SwitchGrayscale";
      break;
    case kSystemSwitchPolarity:
      iconName = @"SwitchPolarity";
      break;
//    case kSystemMute:
//      iconName = @"ScreenSaver";
//      break;
//    case kSystemEject:
//      iconName = @"ScreenSaver";
//      break;
//    case kSystemVolumeUp:
//      iconName = @"ScreenSaver";
//      break;
//    case kSystemVolumeDown:
//      iconName = @"ScreenSaver";
//      break;
  }
  if (iconName)
    [action setIcon:[NSImage imageNamed:iconName inBundle:kSystemActionBundle]];
  [action setActionDescription:[self actionDescription]];
}

#pragma mark -
- (SystemActionType)action {
  return [(SystemAction *)[self sparkAction] action];
}

- (void)setAction:(SystemActionType)newAction {
  if ([self action] != newAction) {
    [(SystemAction *)[self sparkAction] setAction:newAction];
  }
  [[nameField cell] setPlaceholderString:[self actionDescription]];
  switch (newAction) {
    case kSystemLogOut:
    case kSystemRestart:
    case kSystemShutDown:
      [displayBox setHidden:NO];
      break;
    default:
      [displayBox setHidden:YES];
  }
}

- (BOOL)shouldConfirm {
  return [[self sparkAction] shouldConfirm];
}
- (void)setShouldConfirm:(BOOL)flag {
  [[self sparkAction] setShouldConfirm:flag];
}

- (NSString *)actionDescription {
  id desc = nil;
  switch ([self action]) {
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

@end

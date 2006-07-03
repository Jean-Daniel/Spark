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

@implementation SystemActionPlugin

- (void)bindFields {
  [nameField bind:@"value"
         toObject:self
      withKeyPath:@"sparkAction.name"
          options:[NSDictionary dictionaryWithObjectsAndKeys:
            SKBool(YES), @"NSContinuouslyUpdatesValue",
            [self shortDescription], @"NSNullPlaceholder",
            nil]];
}

- (void)awakeFromNib {
  NSMenu *menu = [actionMenu menu];
  SInt32 macVersion;
  if (Gestalt(gestaltSystemVersion, &macVersion) == noErr && macVersion >= 0x1040) {
    NSMenuItem *item = [NSMenuItem separatorItem];
    [item setTag:-1];
    [menu addItem:item];
    
    item = [[NSMenuItem alloc] initWithTitle:@"Screen Saver" action:nil keyEquivalent:@""];
    [item setTag:kSystemScreenSaver];
    [menu addItem:item];
    [item release];
  }
}

- (void)loadSparkAction:(id)sparkAction toEdit:(BOOL)flag {
  [super loadSparkAction:sparkAction toEdit:flag];
  if (flag) {
    [[self undoManager] registerUndoWithTarget:sparkAction selector:@selector(setName:) object:[sparkAction name]];
    [[[self undoManager] prepareWithInvocationTarget:self] setAction:[sparkAction action]];

    [self setAction:[(SystemAction *)sparkAction action]];
  }
  [self bindFields];
}

- (NSAlert *)controllerShouldConfigureAction {
  return nil;
}

- (void)configureAction {
  SystemAction *powerAction = [self sparkAction];
  /* Set Name */
  if ([[[powerAction name] stringByTrimmingWhitespaceAndNewline] length] == 0)
    [powerAction setName:[self shortDescription]];
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
    case kSystemMute:
      iconName = @"ScreenSaver";
      break;
    case kSystemEject:
      iconName = @"ScreenSaver";
      break;
    case kSystemVolumeUp:
      iconName = @"ScreenSaver";
      break;
    case kSystemVolumeDown:
      iconName = @"ScreenSaver";
      break;
  }
  if (iconName)
    [powerAction setIcon:[NSImage imageNamed:iconName inBundle:kSystemActionBundle]];
  [powerAction setShortDescription:[self shortDescription]];
}

#pragma mark -
- (SystemActionType)action {
  return [(SystemAction *)[self sparkAction] action];
}

- (void)setAction:(SystemActionType)newAction {
  if ([self action] != newAction) {
    [(SystemAction *)[self sparkAction] setAction:newAction];
    [nameField unbind:@"value"];
    [self bindFields];
  }
}

- (NSString *)shortDescription {
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
    case kSystemMute:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_SOUND_MUTE", nil, kSystemActionBundle,
                                                @"Mute * Action Description *");
      break;
    case kSystemEject:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_EJECT", nil, kSystemActionBundle,
                                                @"Eject * Action Description *");
      break;
    case kSystemVolumeUp:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_SOUND_UP", nil, kSystemActionBundle,
                                                @"Sound up * Action Description *");
      break;
    case kSystemVolumeDown:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_SOUND_DOWN", nil, kSystemActionBundle,
                                                @"Sound down * Action Description *");
      break;
    default:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_ERROR", nil, kSystemActionBundle,
                                                @"Error * Action Description *");
  }
  return desc;
}

@end

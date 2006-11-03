/*
 *  SystemActionPlugin.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SystemActionPlugin.h"
#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKAppKitExtensions.h>

@implementation SystemActionPlugin

- (void)dealloc {
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
    [self willChangeValueForKey:@"shouldConfirm"];
    if ([sparkAction name])
      [nameField setStringValue:[sparkAction name]];
    /* Force update menu + placeholder */
    [self setAction:[sparkAction action]];
    [self didChangeValueForKey:@"shouldConfirm"];
  } else {
    [self setAction:kSystemLogOut];
    [self setShouldConfirm:YES];
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
    [action setName:SystemActionDescription(action)];
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
    case kSystemEmptyTrash:
      iconName = @"SystemTrash";
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
  [action setActionDescription:SystemActionDescription(action)];
}

#pragma mark -
- (SystemActionType)action {
  return [(SystemAction *)[self sparkAction] action];
}

- (void)setAction:(SystemActionType)newAction {
  if ([self action] != newAction) {
    [(SystemAction *)[self sparkAction] setAction:newAction];
  }
  [[nameField cell] setPlaceholderString:SystemActionDescription([self sparkAction])];
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

@end

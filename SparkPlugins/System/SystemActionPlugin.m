/*
 *  SystemActionPlugin.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#include <unistd.h>

#import "SystemActionPlugin.h"
#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKDSFunctions.h>

@implementation SystemActionPlugin

- (void)dealloc {
  [super dealloc];
}

- (void)awakeFromNib {
  if (SKSystemMajorVersion() >= 10 && SKSystemMinorVersion() >= 4) {
    NSMenu *menu = [ibActions menu];
    /* Screen saver and switch work only with Mac OS X.4 and later */
    NSMenuItem *item = [NSMenuItem separatorItem];
    [item setTag:-1];
    [menu addItem:item];
    
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Screen Saver", nil, kSystemActionBundle,
                                                                                @"Screen Saver Menu Item")
                                      action:nil keyEquivalent:@""];
    [item setTag:kSystemScreenSaver];
    [menu addItem:item];
    [item release];
    
    /* Build user switching menu */
    CFArrayRef users;
    BOOL separator = NO;
    if (noErr == SKDSGetVisibleUsers(&users, kDS1AttrUniqueID, kDS1AttrDistinguishedName, NULL)) {
      CFIndex cnt = CFArrayGetCount(users);
      for (CFIndex idx = 0; idx < cnt; idx++) {
        CFDictionaryRef user = CFArrayGetValueAtIndex(users, idx);
        CFStringRef suid = CFDictionaryGetValue(user, CFSTR(kDS1AttrUniqueID));
        if (suid && (unsigned)CFStringGetIntValue(suid) != getuid()) {
          CFStringRef name = CFDictionaryGetValue(user, CFSTR(kDS1AttrDistinguishedName));
          if (name) {
            if (!separator) {
              separator = YES;
              [[ibUsers menu] insertItem:[NSMenuItem separatorItem] atIndex:0];
              [[ibUsers itemAtIndex:0] setTag:-1];
            }
            item = [[NSMenuItem alloc] initWithTitle:(id)name action:NULL keyEquivalent:@""];
            [item setTag:CFStringGetIntValue(suid)];
            [[ibUsers menu] insertItem:item atIndex:0];
            [item release];
          }
        }
      }
      CFRelease(users);
    }
  }
}

- (void)loadSparkAction:(SystemAction *)sparkAction toEdit:(BOOL)flag {
  [ibName setStringValue:[sparkAction name] ? : @""];
  if (flag) {
    /* Force update menu + placeholder */
    [self setAction:[sparkAction action]];
    
    if (kSystemSwitch == [self action]) {
      [ibUsers selectItemWithTag:[sparkAction userID]];
    }
  } else {
    [self setAction:kSystemLogOut];
    [[self sparkAction] setShouldConfirm:YES];
  }
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  return [super sparkEditorShouldConfigureAction];
}

- (void)configureAction {
  SystemAction *action = [self sparkAction];
  /* Reset */
  [action setUserID:0];
  [action setUserName:nil];
  
  if (kSystemSwitch == [self action]) {
    NSMenuItem *item = [ibUsers selectedItem];
    if ([item tag]) {
      [action setUserID:[item tag]];
      [action setUserName:[item title]];
    }
  }
  
  /* Set Name (should be after other configurations to be accurate) */
  NSString *name = [ibName stringValue];
  if ([[name stringByTrimmingWhitespaceAndNewline] length] == 0)
    [action setName:SystemActionDescription(action)];
  else 
    [action setName:name];
  
  [action setIcon:SystemActionIcon(action)];
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
  [[ibName cell] setPlaceholderString:SystemActionDescription([self sparkAction])];
  switch (newAction) {
    case kSystemLogOut:
    case kSystemRestart:
    case kSystemShutDown:
      /* Confirm */
      [uiOptions selectTabViewItemAtIndex:0];
      break;
    case kSystemSwitch:
      /* Users */
      [uiOptions selectTabViewItemAtIndex:1];
      break;
    case kSystemVolumeUp:
    case kSystemVolumeDown:
    case kSystemVolumeMute:
    case kSystemBrightnessUp:
    case kSystemBrightnessDown:
      /* Display visual */
      [uiOptions selectTabViewItemAtIndex:2];
      break;
    default:
      /* Empty */
      [uiOptions selectTabViewItemAtIndex:3];
  }
}

- (IBAction)changeUser:(id)sender {
  SystemAction *action = [self sparkAction];
  if ([self action] == kSystemSwitch) {
    NSMenuItem *item = [ibUsers selectedItem];
    if ([item tag]) {
      [action setUserID:[item tag]];
      [action setUserName:[item title]];
    } else {
      [action setUserID:0];
      [action setUserName:nil];
    }
    [[ibName cell] setPlaceholderString:SystemActionDescription([self sparkAction])];
  }
}

@end

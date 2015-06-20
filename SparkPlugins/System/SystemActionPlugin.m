/*
 *  SystemActionPlugin.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#include <unistd.h>

#import "SystemActionPlugin.h"

#import <WonderBox/WBODFunctions.h>
#import <WonderBox/NSString+WonderBox.h>

@implementation SystemActionPlugin

- (void)awakeFromNib {
  NSMenu *menu = [ibActions menu];
  /* Check if handle brightness */
  if (![SystemAction supportBrightness]) {
    NSInteger idx = [menu indexOfItemWithTag:kSystemBrightnessUp];
    NSAssert(idx >= 0, @"Invalid menu. Does not contains brightness actions");
    
    [menu removeItemAtIndex:idx + 2];
    [menu removeItemAtIndex:idx + 1];
    [menu removeItemAtIndex:idx];
  }
  
  /* Build user switching menu */
  BOOL separator = NO;
  CFArrayRef users = WBODCopyVisibleUsersAttributes(kODAttributeTypeUniqueID, kODAttributeTypeRecordName, kODAttributeTypeFullName, NULL);
  if (users) {
    for (CFIndex idx = 0, cnt = CFArrayGetCount(users); idx < cnt; idx++) {
      CFDictionaryRef user = CFArrayGetValueAtIndex(users, idx);
      CFStringRef suid = CFDictionaryGetValue(user, kODAttributeTypeUniqueID);
      if (suid && (unsigned)CFStringGetIntValue(suid) != getuid()) {
        CFStringRef name = CFDictionaryGetValue(user, kODAttributeTypeFullName);
        if (!name)
          name = CFDictionaryGetValue(user, kODAttributeTypeRecordName);
        if (name) {
          if (!separator) {
            separator = YES;
            [[ibUsers menu] insertItem:[NSMenuItem separatorItem] atIndex:0];
            [[ibUsers itemAtIndex:0] setTag:-1];
          }
          NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:SPXCFToNSString(name) action:NULL keyEquivalent:@""];
          [item setTag:CFStringGetIntValue(suid)];
          [[ibUsers menu] insertItem:item atIndex:0];
        }
      }
    }

    CFRelease(users);
  }
}

- (void)loadSparkAction:(SystemAction *)sparkAction toEdit:(BOOL)flag {
  [ibName setStringValue:[sparkAction name] ? : @""];
  if (flag) {
    /* Force update menu + placeholder */
    [self setAction:[sparkAction action]];
    
    if (kSystemSwitch == [self action]) {
      NSInteger idx = [ibUsers indexOfItemWithTag:[sparkAction userID]];
      if (idx >= 0)
        [ibUsers selectItemAtIndex:idx];
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
      [action setUserID:(uid_t)[item tag]];
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
  [ibFeedback setHidden:YES]; // default
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
      [ibFeedback setHidden:NO];
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
      [action setUserID:(uid_t)[item tag]];
      [action setUserName:[item title]];
    } else {
      [action setUserID:0];
      [action setUserName:nil];
    }
    [[ibName cell] setPlaceholderString:SystemActionDescription([self sparkAction])];
  }
}

@end

/*
 *  SystemActionPlugin.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#include <unistd.h>

#import "SystemActionPlugin.h"
#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKDSFunctions.h>
#import <ShadowKit/SKFSFunctions.h>

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
    
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Switch to...", nil, kSystemActionBundle,
                                                                                @"Switch to... Menu Item")
                                      action:nil keyEquivalent:@""];
    [item setTag:kSystemSwitch];
    [menu insertItem:item atIndex:1];
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
  if (flag) {
    [self willChangeValueForKey:@"shouldConfirm"];
    if ([sparkAction name])
      [ibName setStringValue:[sparkAction name]];
    
    /* Force update menu + placeholder */
    [self setAction:[sparkAction action]];
    
    if (kSystemSwitch == [self action]) {
      [ibUsers selectItemWithTag:[sparkAction userID]];
    }
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
  /* Reset */
  [action setUserID:0];
  [action setUserName:nil];
  
  /* Set Name */
  NSString *name = [ibName stringValue];
  if ([[name stringByTrimmingWhitespaceAndNewline] length] == 0)
    [action setName:SystemActionDescription(action)];
  else 
    [action setName:name];
  
  if (kSystemSwitch == [self action]) {
    NSMenuItem *item = [ibUsers selectedItem];
    if ([item tag]) {
      [action setUserID:[item tag]];
      [action setUserName:[item title]];
    }
  }
  
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
      [ibUsers setHidden:YES];
      [displayBox setHidden:NO];
      break;
    case kSystemSwitch:
      [ibUsers setHidden:NO];
      [displayBox setHidden:YES];
      break;
    default:
      [ibUsers setHidden:YES];
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

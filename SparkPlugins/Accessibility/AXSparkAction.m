//
//  AXSparkAction.m
//  Spark Plugins
//
//  Created by Jean-Daniel Dupas on 27/11/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import "AXSparkAction.h"

#import "AXSMenu.h"
#import "AXSApplication.h"

@implementation AXSparkAction

- (id)copyWithZone:(NSZone *)aZone {
  AXSparkAction *copy = [super copyWithZone:aZone];
  copy->_menuTitle = [_menuTitle copy];
  copy->_menuItemTitle = [_menuItemTitle copy];
  return copy;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    if (_menuTitle)
      [plist setObject:_menuTitle forKey:@"AXAMenuTitle"];
    if (_menuItemTitle)
      [plist setObject:_menuItemTitle forKey:@"AXAMenuItemTitle"];
    return YES;
  }
  return NO;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    _menuTitle = [plist objectForKey:@"AXAMenuTitle"];
    _menuItemTitle = [plist objectForKey:@"AXAMenuItemTitle"];
  }
  return self;
}

#pragma mark -
- (BOOL)shouldSaveIcon {
  return NO;
}

- (BOOL)performActionInMenu:(AXSMenu *)aMenu {
  if (!aMenu) return NO;
  NSArray *items = [aMenu items];
  for (NSUInteger idx = 0, count = [items count]; idx < count; idx++) {
    AXSMenuItem *item = [items objectAtIndex:idx];
    if ([item submenu]) {
      if ([self performActionInMenu:[item submenu]])
        return YES;
    } else {
      NSString *title = [item title];
      if (title && ([title caseInsensitiveCompare:_menuItemTitle] == NSOrderedSame)) {
      //if (title && [title rangeOfString:_menuItemTitle options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location != NSNotFound) {
        SPXDebug(@"Item found: %@", item);
        if (![item performAction:NSAccessibilityPressAction])
          NSBeep();
        return YES;
      }
    }
  }
  return NO;
}

- (SparkAlert *)performAction {
  if (!AXIsProcessTrustedWithOptions(SPXNSToCFDictionary(@{ SPXCFToNSString(kAXTrustedCheckOptionPrompt): @NO })))
    return [SparkAlert alertWithMessageText:@"Accessibility should be turn on!"
                  informativeTextWithFormat:@"Please turn it on in system preferences."];
  
  pid_t pid = [NSWorkspace.sharedWorkspace frontmostApplication].processIdentifier;
  if (pid <= 0)
    return nil;
  AXSApplication *app = [[AXSApplication alloc] initWithProcessIdentifier:pid];
  if (!app)
    return nil;
  AXSMenu *menu = [app menu];
  NSArray *items = [menu items];
  for (NSUInteger idx = 1, count = [items count]; idx < count; idx++) {
    AXSMenuItem *item = [items objectAtIndex:idx];
    if ([item submenu]) {
      NSString *title = [item title];
      if (!_menuTitle || ([title caseInsensitiveCompare:_menuTitle] == NSOrderedSame)) {
      //if (!_menuTitle || [title rangeOfString:_menuTitle options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location != NSNotFound) {
        /* browse submenu */
        if ([self performActionInMenu:[item submenu]])
          break;
      }
    }
  }
  return nil;
}

@end

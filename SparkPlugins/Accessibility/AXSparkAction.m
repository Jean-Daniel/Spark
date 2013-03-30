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

@synthesize menuTitle = ax_title;
@synthesize menuItemTitle = ax_subtitle;

- (id)copyWithZone:(NSZone *)aZone {
  AXSparkAction *copy = [super copyWithZone:aZone];
  copy->ax_title = [ax_title copy];
  copy->ax_subtitle = [ax_subtitle copy];
  return copy;
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    if (ax_title)
      [plist setObject:ax_title forKey:@"AXAMenuTitle"];
    if (ax_subtitle)
      [plist setObject:ax_subtitle forKey:@"AXAMenuItemTitle"];
    return YES;
  }
  return NO;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    ax_title = [[plist objectForKey:@"AXAMenuTitle"] retain];
    ax_subtitle = [[plist objectForKey:@"AXAMenuItemTitle"] retain];
  }
  return self;
}

- (void)dealloc {
  [ax_title release];
  [ax_subtitle release];
  [super dealloc];
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
      if (title && ([title caseInsensitiveCompare:ax_subtitle] == NSOrderedSame)) {
      //if (title && [title rangeOfString:ax_subtitle options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location != NSNotFound) {
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
  if (!AXAPIEnabled() && !AXIsProcessTrusted())
    return [SparkAlert alertWithMessageText:@"Accessibility should be turn on!"
                  informativeTextWithFormat:@"Please turn it on in system preferences."];
  
  ProcessSerialNumber psn;
  if (noErr != GetFrontProcess(&psn))
    return nil;
  AXSApplication *app = [[AXSApplication alloc] initWithProcess:&psn];
  if (!app)
    return nil;
  AXSMenu *menu = [app menu];
  NSArray *items = [menu items];
  for (NSUInteger idx = 1, count = [items count]; idx < count; idx++) {
    AXSMenuItem *item = [items objectAtIndex:idx];
    if ([item submenu]) {
      NSString *title = [item title];
      if (!ax_title || ([title caseInsensitiveCompare:ax_title] == NSOrderedSame)) {
      //if (!ax_title || [title rangeOfString:ax_title options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location != NSNotFound) {
        /* browse submenu */
        if ([self performActionInMenu:[item submenu]])
          break;
      }
    }
  }
  [app release];
  return nil;
}

@end

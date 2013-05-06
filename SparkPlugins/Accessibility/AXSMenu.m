//
//  AXSMenu.m
//  Spark PlugIns
//
//  Created by Jean-Daniel Dupas on 27/11/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import "AXSMenu.h"

@implementation AXSMenu

- (NSArray *)items {
  NSArray *children = [self valuesForAttribute:NSAccessibilityChildrenAttribute];
  NSMutableArray *items = [NSMutableArray arrayWithCapacity:[children count]];
  for (NSUInteger idx = 0, count = [children count]; idx < count; idx++) {
    CFTypeRef child = (CFTypeRef)[children objectAtIndex:idx];
    if (CFGetTypeID(child) == AXUIElementGetTypeID()) {
      AXSMenuItem *item = [[AXSMenuItem alloc] initWithElement:child];
      NSString *role = [item role];
      if ([role isEqualToString:NSAccessibilityMenuItemRole] || [role isEqualToString:(id)kAXMenuBarItemRole])
        [items addObject:item];
      [item release];
    }
  }
  return items;
}

- (NSString *)title {
  CFTypeRef elt = [self valueForAttribute:NSAccessibilityServesAsTitleForUIElementsAttribute];
  if (elt) {
    CFTypeRef title;
    if (kAXErrorSuccess == AXUIElementCopyAttributeValue(elt, kAXTitleAttribute, &title))
      return SPXCFStringBridgingRelease(title);
  } 
  return [self valueForAttribute:NSAccessibilityTitleAttribute];
}

@end

#pragma mark -

@implementation AXSMenuItem 

- (void)dealloc {
  [ax_submenu release];
  [super dealloc];
}

#pragma mark -
- (NSString *)title {
  return [self valueForAttribute:NSAccessibilityTitleAttribute];
}

- (BOOL)isSeparator {
  return [[self title] length] == 0;
}

- (AXSMenu *)submenu {
  if (ax_submenu) return ax_submenu;
  
  NSArray *children = [self valuesForAttribute:NSAccessibilityChildrenAttribute];
  if (children) {
    NSAssert([children count] == 1, @"invalid menu item children");
    CFTypeRef child = (CFTypeRef)[children objectAtIndex:0];
    if (CFGetTypeID(child) == AXUIElementGetTypeID()) {
      ax_submenu = [[AXSMenu alloc] initWithElement:child];
      if ([[ax_submenu role] isEqualToString:NSAccessibilityMenuRole])
        return ax_submenu;
      [ax_submenu release];
      ax_submenu = nil;
    }
  }
  return nil;
}

@end

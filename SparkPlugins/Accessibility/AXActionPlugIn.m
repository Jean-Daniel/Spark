//
//  AXAPlugin.m
//  Spark Plugins
//
//  Created by Jean-Daniel Dupas on 27/11/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import "AXActionPlugIn.h"
#import "AXSparkAction.h"

#import "AXSMenu.h"
#import "AXSApplication.h"

@interface AXActionPlugIn ()

- (void)rebuildApplicationMenu;

@end

@implementation AXActionPlugIn

- (void)loadSparkAction:(id)anAction toEdit:(BOOL)isEditing {
  if (isEditing) {
    [uiTitle setStringValue:[anAction menuTitle] ?: @""];
    [uiSubtitle setStringValue:[anAction menuItemTitle] ?: @""];
  }
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  if ([[uiSubtitle stringValue] length] == 0) {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Le champs Menu item est vide";
    alert.informativeText = @"Ce champs est obigatoire !";
    return alert;
  }
  return nil;
}

- (void)configureAction {
  AXSparkAction *action = [self sparkAction];
  [action setMenuTitle:[uiTitle stringValue]];
  [action setMenuItemTitle:[uiSubtitle stringValue]];
}

#pragma mark -
- (void)plugInViewWillBecomeVisible {
  [self rebuildApplicationMenu];
  [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self 
                                                         selector:@selector(ax_didAddApplication:) 
                                                             name:NSWorkspaceDidLaunchApplicationNotification
                                                           object:nil];
  [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self 
                                                         selector:@selector(ax_didRemoveApplication:) 
                                                             name:NSWorkspaceDidTerminateApplicationNotification
                                                           object:nil];
}

- (void)plugInViewDidBecomeHidden {
  [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

- (IBAction)chooseMenuItem:(NSMenuItem *)sender {
//  if ([[[sender selectedItem] title] isEqualToString:@"-"])
//    return;
  [uiSubtitle setStringValue:[sender title] ?: @""];
  NSMenu *menu = [sender menu];
  NSMenuItem *subitem = nil;
  while ([menu supermenu]) {
    NSMenu *sub = menu;
    menu = [menu supermenu];
    subitem = [menu itemAtIndex:[menu indexOfItemWithSubmenu:sub]];
  }
  [uiTitle setStringValue:[subitem title] ?: @""];
}

#pragma mark -
#pragma mark Application Menu
- (void)rebuildApplicationMenu {
  // FIXME: should preserve selection
  [uiApplications removeAllItems];
  [uiApplications addItemWithTitle:@"-"];
  for (NSRunningApplication *app in [NSWorkspace sharedWorkspace].runningApplications) {
    NSURL *url = app.bundleURL;
    if (url) {
      NSString *name = [[NSFileManager defaultManager] displayNameAtPath:[url path]];
      NSMenuItem *item = [[uiApplications menu] addItemWithTitle:name action:NULL keyEquivalent:@""];
      NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[url path]];
      [icon setSize:NSMakeSize(16, 16)];
      [item setImage:icon];
      [item setTag:app.processIdentifier];
    }
  }
}

- (NSMenu *)ax_buildMenu:(AXSMenu *)axmenu {
  NSMenu *menu = [[NSMenu alloc] initWithTitle:[axmenu title] ? : @""];
  NSArray *items = [axmenu items];
  for (NSUInteger idx = 0, count = [items count]; idx < count; idx++) {
    AXSMenuItem *axitem = [items objectAtIndex:idx];
    NSString *title = [axitem title];
    if ([title length] == 0) {
      [menu addItem:[NSMenuItem separatorItem]];
    } else if (-1 == [menu indexOfItemWithTitle:title]) {
      NSMenuItem *item = [menu addItemWithTitle:title action:@selector(chooseMenuItem:) keyEquivalent:@""];
      item.target = self;
      AXSMenu *axsubmenu = [axitem submenu];
      if (axsubmenu)
        [item setSubmenu:[self ax_buildMenu:axsubmenu]];
    }
  }
  [menu setAutoenablesItems:NO];
  return menu;
}

- (IBAction)selectApplication:(NSPopUpButton *)sender {
  [uiMenus removeAllItems];
  [uiMenus addItemWithTitle:@"-"];
  NSInteger tag = [sender selectedTag];
  if (tag > 0) {
    AXSApplication *app = [[AXSApplication alloc] initWithProcessIdentifier:(pid_t)tag];
    if (app) {
      NSMenu *menu = [self ax_buildMenu:[app menu]];
      if (menu && [menu numberOfItems] > 0) {
        [menu removeItemAtIndex:0];
        [uiMenus setMenu:menu];
      }
    }
  }
}

- (void)ax_didAddApplication:(NSNotification *)aNotification {
  
}
- (void)ax_didRemoveApplication:(NSNotification *)aNotification {
  
}

@end

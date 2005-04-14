//
//  PlugInMenu.m
//  Spark
//
//  Created by Fox on Sat Jan 24 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit.h>

#import "PluginMenu.h"

@implementation PlugInMenu

- (id)initWithFrame:(NSRect)frame {
  if (self = [super initWithFrame:frame]) {
    id gear = [NSImage imageNamed:@"Gear"];
    [self setSegmentCount:1];
    [self setWidth:34 forSegment:0];
    [self setImage:gear forSegment:0];
    [[self cell] setToolTip:NSLocalizedString(@"CREATE_KEY_TOOLTIP", @"Segment Menu ToolTips") forSegment:0];
    [[self cell] setTrackingMode:NSSegmentSwitchTrackingMomentary];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sparkDidAddPlugIn:) name:kSparkDidAddPlugInNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sparkDidRemovePlugIn:) name:kSparkDidRemovePlugInNotification object:nil];
  }
  return self;
}

- (void)awakeFromNib {
  [self createPlugInMenu];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObject:self];
  [self setMenu:nil forSegment:0];
  [super dealloc];
}

- (void)createPlugInMenu {
  id menu = NewActionMenu();
  [self setMenu:menu forSegment:0];
  id fileMenu = [[[NSApp mainMenu] itemWithTag:1] submenu];
  [fileMenu setSubmenu:[[menu copy] autorelease] forItem:[fileMenu itemWithTag:1]];
}

- (void)sparkDidAddPlugIn:(NSNotification *)aNotification {
  [self createPlugInMenu];
}
- (void)sparkDidRemovePlugIn:(NSNotification *)aNotification {
  [self createPlugInMenu];
}

@end

NSMenu *NewActionMenu() {
  id menu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"NEW_KEY_MENU", @"New Key Menu Title")];
  id desc = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
  id plugIns = [[[SparkActionLoader sharedLoader] plugIns] sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];
  [desc release];
  plugIns = [plugIns objectEnumerator];
  id plugIn;
  int i = 1;
  while (plugIn = [plugIns nextObject]) {
    id menuItem = [[NSMenuItem alloc] initWithTitle:[plugIn valueForKey:@"name"] action:@selector(newActionMenuItemSelected:) keyEquivalent:@""];
    [menuItem setImage:[plugIn valueForKey:@"icon"]];
    [menuItem setRepresentedObject:plugIn];
    if (i < 10) 
      [menuItem setKeyEquivalent:[NSString stringWithFormat:@"%i", i++]];
    [menu addItem:menuItem];
    [menuItem release];
  }
  return [menu autorelease];
}

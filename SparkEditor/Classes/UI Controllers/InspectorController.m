//
//  InspectorController.m
//  Spark Editor
//
//  Created by Grayfox on 15/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "InspectorController.h"
#import <SparkKit/SparkKit.h>

#import "Preferences.h"
#import "ActionLibraryController.h"
#import "ApplicationLibraryController.h"

@interface SearchFieldToolbarItem : NSToolbarItem {
}
@end

@implementation InspectorController

+ (InspectorController *)sharedInspector {
  static InspectorController *_sharedInspector = nil;
  @synchronized (self) {
    if (!_sharedInspector) {
      _sharedInspector = [[InspectorController alloc] init];
    }
  }
  return _sharedInspector;
}

- (id)init {
  if (self = [super initWithWindowNibName:@"Inspector"]) {
    _appLibrary = [[ApplicationLibraryController alloc] init];
    _actionLibrary = [[ActionLibraryController alloc] init];
  }
  return self;
}

- (void)dealloc {
  [_appLibrary release];
  [_actionLibrary release];
  [super dealloc];
}

- (void)awakeFromNib {
  [[contentView tabViewItemAtIndex:0] setView:[_appLibrary libraryView]];
  [[contentView tabViewItemAtIndex:1] setView:[_actionLibrary libraryView]];

  [self createToolbar];
  [[self window] setHidesOnDeactivate:NO];
  [[self window] setLevel:NSNormalWindowLevel]; /* Doesn't want a floating panel */
  
  [_appLibrary restoreWorkspaceWithKey:kSparkPrefInspectorApplicationLibrary];
  [_appLibrary setSearchActive:YES];
  [_actionLibrary restoreWorkspaceWithKey:kSparkPrefInspectorActionLibrary];
  [_actionLibrary setSearchActive:YES];
  
  id identifier = [[NSUserDefaults standardUserDefaults] stringForKey:kSparkPrefInspectorSelectedTab];
  if (identifier) {
    [[[self window] toolbar] setSelectedItemIdentifier:identifier];
    id items = [[[self window] toolbar] items];
    unsigned i;
    for (i=0; i<[items count]; i++) {
      id item = [items objectAtIndex:i];
      if ([[item itemIdentifier] isEqualToString:identifier]) {
        [self selectTab:item];
        break;
      }
    }
  }
}

- (void)createToolbar {
  NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"SparkInspectorToolbar"];
  [toolbar setDelegate:self];
  [toolbar setAutosavesConfiguration:NO];
  [toolbar setAllowsUserCustomization:NO];
  [toolbar setSizeMode:NSToolbarSizeModeSmall];
  [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
  [[self window] setToolbar:toolbar];
  
  [toolbar setSelectedItemIdentifier:@"SparkInspectorApplicationsItem"];
  [contentView selectTabViewItemAtIndex:0];
  
  searchField = (id)[[[toolbar items] objectAtIndex:3] view];
  [toolbar release];
}

- (LibraryController *)frontLibrary {
  LibraryController *lib = nil;
  switch ([contentView indexOfSelectedTabViewItem]) {
    case 0:
      lib = _appLibrary;
      break;
    case 1:
      lib = _actionLibrary;
      break;
  }
  return lib;
}

- (IBAction)search:(id)sender {
  [[[self frontLibrary] objects] search:sender];
}

- (IBAction)selectTab:(id)sender {
  int tag = [sender tag];
  if (tag != [contentView indexOfSelectedTabViewItem]) {
    [contentView selectTabViewItemAtIndex:tag];
    [searchField setStringValue:@""];
    [self search:searchField];
  }
}

#pragma mark -
- (void)windowWillClose:(NSNotification *)aNotification {
  [_appLibrary saveWorkspaceWithKey:kSparkPrefInspectorApplicationLibrary];
  [_actionLibrary saveWorkspaceWithKey:kSparkPrefInspectorActionLibrary];
  id identifier = [[[self window] toolbar] selectedItemIdentifier];
  [[NSUserDefaults standardUserDefaults] setObject:identifier forKey:kSparkPrefInspectorSelectedTab];
}

#pragma mark -
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
  id item = nil;
  if ([itemIdentifier isEqualToString:@"SparkInspectorApplicationsItem"]) {
    item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    [item setTag:0];
    [item setLabel:NSLocalizedString(@"TB_LABEL_APPLICATION", @"Inspector Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"TB_TOOLTIP_APPLICATIONS", @"Inspector Toolbar item tooltip")];
    [item setImage:[NSImage imageNamed:@"ApplicationsItem"]];
    [item setTarget:self];
    [item setAction:@selector(selectTab:)];
  } else if ([itemIdentifier isEqualToString:@"SparkInspectorActionsItem"]) {
    item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    [item setTag:1];
    [item setLabel:NSLocalizedString(@"TB_LABEL_ACTIONS", @"Inspector Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"TB_TOOLTIP_ACTIONS", @"Inspector Toolbar item tooltip")];
    [item setImage:[NSImage imageNamed:@"ActionsItem"]];
    [item setTarget:self];
    [item setAction:@selector(selectTab:)];
  } else if ([itemIdentifier isEqualToString:@"SearchFieldToolbarItem"]) {
    item = [[SearchFieldToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    [item setLabel:NSLocalizedString(@"SEARCH_FIELD", @"Inspector Toolbar item label")];
    [item setToolTip:NSLocalizedString(@"SEARCH_FIELD_TOOLTIP", @"Search Field")];
    [item setTarget:self];
    [item setAction:@selector(search:)];
  }
  return [item autorelease];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
  return [NSArray arrayWithObjects:@"SparkInspectorApplicationsItem", @"SparkInspectorActionsItem", NSToolbarFlexibleSpaceItemIdentifier, @"SearchFieldToolbarItem", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
  return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
  return [self toolbarDefaultItemIdentifiers:toolbar];
}

@end

@implementation SearchFieldToolbarItem

- (id)initWithItemIdentifier:(NSString *)itemIdentifier {
  if (self = [super initWithItemIdentifier:itemIdentifier]) {
    id searchField = [[NSSearchField alloc] initWithFrame:NSMakeRect(0, 0, 108, 19)];
    [[searchField cell] setControlSize:NSSmallControlSize];
    [self setView:searchField];
    [self setMinSize:[searchField frame].size];
    [self setMaxSize:[searchField frame].size];
    [searchField release];
  }
  return self;
}

@end
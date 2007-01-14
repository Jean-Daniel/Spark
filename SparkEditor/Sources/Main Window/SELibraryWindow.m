/*
 *  SELibraryWindow.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "SELibraryWindow.h"

#import "Spark.h"
#import "SETableView.h"
#import "SEHeaderCell.h"
#import "SEEntryEditor.h"
#import "SEScriptHandler.h"
#import "SESparkEntrySet.h"
#import "SELibrarySource.h"
#import "SEEntriesManager.h"
#import "SEApplicationView.h"
#import "SEApplicationSource.h"
#import "SETriggersController.h"

#import "SEServerConnection.h"

#import <ShadowKit/SKTableView.h>
#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKTableDataSource.h>
#import <ShadowKit/SKImageAndTextCell.h>
#import <ShadowKit/SKAppKitExtensions.h>

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkPlugIn.h>

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkEntryManager.h>

@implementation SELibraryWindow

- (id)init {
  if (self = [super initWithWindowNibName:@"SELibraryWindow"]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeStatus:)
                                                 name:SEServerStatusDidChangeNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (SparkLibrary *)library {
  return [[self document] library];
}
- (SEEntriesManager *)manager {
  return [[self document] manager];
}

- (void)didSelectApplication:(int)anIndex {
  SparkApplication *application = nil;
  NSArray *objects = [appSource arrangedObjects];
  if (anIndex >= 0 && (unsigned)anIndex < [objects count]) {
    application = [objects objectAtIndex:anIndex];
    [appField setSparkApplication:application];
    
    // Shared Manager set application
    [[self manager] setApplication:application];
  }
}

- (void)windowDidLoad {
  [[self window] center];
  [[self window] setFrameAutosaveName:@"SparkMainWindow"];
  [[self window] setBackgroundColor:[NSColor colorWithCalibratedWhite:.773 alpha:1]];
  [[self window] display];
}

- (void)awakeFromNib {
  [appTable registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
 
  /* Configure Application Header Cell */
  SEHeaderCell *header = [[SEHeaderCell alloc] initTextCell:@"Front Application"];
  [header setAlignment:NSCenterTextAlignment];
  [header setFont:[NSFont systemFontOfSize:11]];
  [[[appTable tableColumns] objectAtIndex:0] setHeaderCell:header];
  [header release];
  [appTable setCornerView:[[[SEHeaderCellCorner alloc] init] autorelease]];

  /* Configure list double action */
  [libraryTable setTarget:self];
  [libraryTable setDoubleAction:@selector(libraryDoubleAction:)];
  
  /* Configure application field */
  [appField setTarget:appDrawer];
  [appField setAction:@selector(toggle:)];
  
  /* Refresh Tables */
  [self didSelectApplication:0];
  [triggers loadTriggers];
  
  [self performSelector:@selector(didChangeStatus:) withObject:nil];
  
  /* Configure New Plugin Menu */
  [ibMenu setMenu:[NSApp pluginsMenu] forSegment:0];
  [[ibMenu cell] setToolTip:NSLocalizedString(@"CREATE_TRIGGER_TOOLTIP", @"Segment Menu ToolTips") forSegment:0];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
  if ([menuItem action] == @selector(copy:) || [menuItem action] == @selector(paste:)) {
    NSResponder *first = [[self window] firstResponder];
    return libraryTable == first || [triggers tableView] == first;
  }
  return YES;
}

- (IBAction)copy:(id)sender {
  ShadowTrace();
}

- (IBAction)paste:(id)sender {
  ShadowTrace();
}

- (IBAction)libraryDoubleAction:(id)sender {
  int idx = [libraryTable selectedRow];
  if (idx > 0) {
    SparkList *object = [listSource objectAtIndex:idx];
    if ([object uid] > kSparkLibraryReserved) {
      [libraryTable editColumn:0 row:idx withEvent:nil select:YES];
    } else {
      SparkPlugIn *plugin = [listSource pluginForList:object];
      if (plugin) {
        // Shared manager -> create entry:type
        [[self manager] createEntry:plugin modalForWindow:[self window]];
      }
    }
  }
}

- (IBAction)newTriggerFromMenu:(id)sender {
  if ([sender respondsToSelector:@selector(representedObject)]) {
    id object = [sender representedObject];
    if ([object isKindOfClass:[SparkPlugIn class]])
      [[self manager] createEntry:[sender representedObject] modalForWindow:[self window]];
  }
}

/* Selected list did change */
- (void)source:(SELibrarySource *)aSource didChangeSelection:(SparkList *)aList {
  [triggers setList:aList];
}

/* Selected application change */
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  [self didSelectApplication:[[aNotification object] selectedRow]];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  SparkApplication *item = [appSource objectAtIndex:rowIndex];
  if ([item uid] && [[[self library] entryManager] containsEntryForApplication:[item uid]]) {
    [aCell setFont:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]];
  } else {
    [aCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
  }
}

- (void)deleteSelectionInTableView:(NSTableView *)aTableView {
  SparkApplication *application = nil;
  int idx = [aTableView selectedRow];
  NSArray *objects = [appSource arrangedObjects];
  if (idx >= 0 && (unsigned)idx < [objects count]) {
    application = [objects objectAtIndex:idx];
  }
  [appSource deleteSelection:nil];
  
  if (application && idx == [aTableView selectedRow] && [objects objectAtIndex:idx] != application) {
    [self didSelectApplication:idx];
  }
}

/* Enable menu item */
- (IBAction)newList:(id)sender {
  [listSource newList:sender];
}

- (IBAction)toggleDaemon:(id)sender {
  [[NSApp delegate] toggleServer:sender];
}

- (void)didChangeStatus:(NSNotification *)aNotification {
  NSString *str = @"";
  NSImage *up = nil, *down = nil;
  SparkDaemonStatus status = [NSApp serverStatus];
  switch (status) {
    case kSparkDaemonStarted:
      str = NSLocalizedString(@"Spark is active", @"Spark Daemon status string");
      up = [NSImage imageNamed:@"stop"];
      down = [NSColor currentControlTint] == NSBlueControlTint ? [NSImage imageNamed:@"stop_bdown"] : [NSImage imageNamed:@"stop_gdown"];
      break;
    case kSparkDaemonStopped:
      str = NSLocalizedString(@"Spark is disabled", @"Spark Daemon status string");
      up = [NSImage imageNamed:@"start"];
      down = [NSColor currentControlTint] == NSBlueControlTint ? [NSImage imageNamed:@"start_bdown"] : [NSImage imageNamed:@"start_gdown"];
      break;
    case kSparkDaemonError:
      str = NSLocalizedString(@"Unexpected error occured", @"Spark Daemon status string");
      break;
  }
  [ibStatus setStringValue:str];
  if (up && down) {
    [ibDaemon setImage:up];
    [ibDaemon setAlternateImage:down];
  }
}

@end

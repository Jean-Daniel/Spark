/*
 *  SELibraryWindow.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SELibraryWindow.h"

#import "Spark.h"
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

- (void)didSelectApplication:(int)anIndex {
  SparkApplication *application = nil;
  NSArray *objects = [appSource arrangedObjects];
  if (anIndex >= 0 && (unsigned)anIndex < [objects count]) {
    application = [objects objectAtIndex:anIndex];
    [appField setApplication:application];
    
    // Shared Manager set application
    [[SEEntriesManager sharedManager] setApplication:application];
  }
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
        [[SEEntriesManager sharedManager] createEntry:plugin modalForWindow:[self window]];
      }
    }
  }
}

- (void)windowDidLoad {
  [[self window] center];
  [[self window] setFrameAutosaveName:@"SparkMainWindow"];
  [[self window] setBackgroundColor:[NSColor colorWithCalibratedWhite:.773 alpha:1]];
  [[self window] display];
}

/* Selected list did change */
- (void)source:(SELibrarySource *)aSource didChangeSelection:(SparkList *)aList {
  [triggers setList:aList];
}

/* Selected application change */
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  [self didSelectApplication:[[aNotification object] selectedRow]];
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

- (IBAction)search:(id)sender {

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
      str = @"Spark is active";
      up = [NSImage imageNamed:@"stop"];
      down = [NSColor currentControlTint] == NSBlueControlTint ? [NSImage imageNamed:@"stop_bdown"] : [NSImage imageNamed:@"stop_gdown"];
      break;
    case kSparkDaemonStopped:
      str = @"Spark is disabled";
      up = [NSImage imageNamed:@"start"];
      down = [NSColor currentControlTint] == NSBlueControlTint ? [NSImage imageNamed:@"start_bdown"] : [NSImage imageNamed:@"start_gdown"];
      break;
    case kSparkDaemonError:
      str = @"Unexpected error occured";
      break;
  }
  [ibStatus setStringValue:str];
  if (up && down) {
    [ibDaemon setImage:up];
    [ibDaemon setAlternateImage:down];
  }
}

@end

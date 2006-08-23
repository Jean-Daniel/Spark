//
//  SELibraryWindow.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 05/07/06.
//  Copyright 2006 Shadow Lab. All rights reserved.
//

#import "SELibraryWindow.h"

#import "SEHeaderCell.h"
#import "SEEntryEditor.h"
#import "SETriggerEntry.h"
#import "SELibrarySource.h"
#import "SEEntriesManager.h"
#import "SEApplicationView.h"
#import "SEApplicationSource.h"
#import "SETriggersController.h"

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

  }
  return self;
}

- (void)dealloc {
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
  [[self window] setBackgroundColor:[NSColor colorWithDeviceWhite:.773 alpha:1]];
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

@end

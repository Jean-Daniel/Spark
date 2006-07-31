//
//  SELibraryWindow.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 05/07/06.
//  Copyright 2006 Shadow Lab. All rights reserved.
//

#import "SELibraryWindow.h"

#import "SEHeaderCell.h"
#import "SEVirtualPlugIn.h"
#import "SELibrarySource.h"
#import "SEApplicationView.h"
#import "SETriggersController.h"

#import <ShadowKit/SKTableView.h>
#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKTableDataSource.h>
#import <ShadowKit/SKImageAndTextCell.h>
#import <ShadowKit/SKAppKitExtensions.h>

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkPlugIn.h>

#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkActionLoader.h>

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
  NSArray *objects = [appSource arrangedObjects];
  if (anIndex >= 0 && (unsigned)anIndex < [objects count]) {
    [appField setApplication:[objects objectAtIndex:anIndex]];
  } else {
    [appField setApplication:nil];
  }
}

- (void)awakeFromNib {
  [appTable registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
  [self didSelectApplication:0];
  
  /* Configure Application Header Cell */
  SEHeaderCell *header = [[SEHeaderCell alloc] initTextCell:@"Front Application"];
  [header setAlignment:NSCenterTextAlignment];
  [header setFont:[NSFont systemFontOfSize:11]];
  [[[appTable tableColumns] objectAtIndex:0] setHeaderCell:header];
  [header release];
  [appTable setCornerView:[[[SEHeaderCellCorner alloc] init] autorelease]];
  
  /* Configure Library Header Cell */
  header = [[SEHeaderCell alloc] initTextCell:@"Library"];
  [header setAlignment:NSCenterTextAlignment];
  [header setFont:[NSFont systemFontOfSize:11]];
  [[[libraryTable tableColumns] objectAtIndex:0] setHeaderCell:header];
  [header release];
  [libraryTable setCornerView:[[[SEHeaderCellCorner alloc] init] autorelease]];
  
  NSArray *plugins = [[SparkActionLoader sharedLoader] plugins];
  unsigned idx = [plugins count];
  while (idx-- > 0) {
    SparkPlugIn *plugin = [plugins objectAtIndex:idx];
    SparkList *list = [[SparkList alloc] initWithName:[plugin name] icon:[plugin icon]];
    [list setUID:128];
    [listSource addObject:list];
    [list release];
  }
  [listSource addObjects:[SparkSharedListSet() objects]];
  [listSource addObject:[SparkList objectWithName:@"Library" icon:[NSImage imageNamed:@"Library"]]];
  [listSource rearrangeObjects];
  
  [libraryTable setTarget:self];
  [libraryTable setDoubleAction:@selector(libraryDoubleAction:)];
}

- (IBAction)libraryDoubleAction:(id)sender {
  ShadowTrace();
}

- (void)windowDidLoad {
  [[self window] center];
  [[self window] setFrameAutosaveName:@"SparkMainWindow"];
  [[self window] setBackgroundColor:[NSColor colorWithDeviceWhite:.773 alpha:1]];
  [[self window] display];
}

- (IBAction)newList:(id)sender {
  SparkList *list = [[SparkList alloc] initWithName:@"New List"];
  [SparkSharedListSet() addObject:list];
  [list release];
  [listSource addObject:list];
  // Edit new list name
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  NSTableView *table = [aNotification object];
  if (table == appTable) {
    [self didSelectApplication:[table selectedRow]];
  }
}

- (void)deleteSelectionInTableView:(NSTableView *)aTableView {
  if (aTableView == appTable) {
    [appSource deleteSelection:nil];
  }
}

@end

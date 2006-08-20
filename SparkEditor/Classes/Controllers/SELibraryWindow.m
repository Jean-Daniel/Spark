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

@implementation SELibraryWindow

- (id)init {
  if (self = [super initWithWindowNibName:@"SELibraryWindow"]) {
    se_triggers = [[SETriggerEntrySet alloc] init];
    se_defaults = [[SETriggerEntrySet alloc] init];
    [se_defaults addEntriesFromDictionary:[SparkSharedLibrary() triggersForApplication:0]];
  }
  return self;
}

- (void)dealloc {
  [se_defaults release];
  [se_triggers release];
  [super dealloc];
}

- (void)didSelectApplication:(int)anIndex {
  SparkApplication *application = nil;
  NSArray *objects = [appSource arrangedObjects];
  if (anIndex >= 0 && (unsigned)anIndex < [objects count]) {
    application = [objects objectAtIndex:anIndex];
    [appField setApplication:application];
    
    [se_triggers removeAllEntries];
    [se_triggers addEntriesFromEntrySet:se_defaults];
    if ([application uid] != 0) {
      NSDictionary *entries = [SparkSharedLibrary() triggersForApplication:[application uid]];
      if ([entries count]) {
        [se_triggers addEntriesFromDictionary:entries];
      }
    }
    // Update lists
    [listSource setTriggers:se_triggers application:application];
    // Update triggers table
    [triggers setTriggers:se_triggers application:application];
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
  
  [libraryTable setTarget:self];
  [libraryTable setDoubleAction:@selector(libraryDoubleAction:)];
  
  [appField setTarget:appDrawer];
  [appField setAction:@selector(toggle:)];
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
        if (!se_editor) {
          se_editor = [[SEEntryEditor alloc] init];
          /* Load */
          [se_editor window];
        }
        [se_editor setApplication:[appField application]];
        [se_editor setEntry:nil];
        [se_editor setActionType:plugin];
        
        [NSApp beginSheet:[se_editor window]
           modalForWindow:[sender window]
            modalDelegate:nil
           didEndSelector:NULL
              contextInfo:nil];
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

- (void)source:(SELibrarySource *)aSource didChangeSelection:(SparkList *)aList {
  [triggers setList:aList];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  [self didSelectApplication:[[aNotification object] selectedRow]];
}

- (void)deleteSelectionInTableView:(NSTableView *)aTableView {
  [appSource deleteSelection:nil];
}

/* Enable menu item */
- (IBAction)newList:(id)sender {
  [listSource newList:sender];
}

- (IBAction)search:(id)sender {
//  id child = [[search accessibilityAttributeValue:NSAccessibilityChildrenAttribute] objectAtIndex:0];
//  NSLog(@"%@", [child accessibilityAttributeValue:NSAccessibilityChildrenAttribute]);
//  NSLog(@"%@", [child accessibilityAttributeValue:NSAccessibilityClearButtonAttribute]);
}

@end

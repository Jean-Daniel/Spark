//
//  SELibraryWindow.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 05/07/06.
//  Copyright 2006 Adamentium. All rights reserved.
//

#import "SELibraryWindow.h"

#import "SEHeaderCell.h"
#import "SETriggersController.h"

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKTableDataSource.h>

#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkObjectsLibrary.h>

static
NSComparisonResult SparkAppCompare(id app1, id app2, void *source) {
  if ([app1 uid] < kSparkLibraryReserved || [app2 uid] < kSparkLibraryReserved) {
    return [app1 uid] - [app2 uid];
  }
  return [[app1 name] caseInsensitiveCompare:[app2 name]];
}

@implementation SELibraryWindow

- (id)init {
  if (self = [super initWithWindowNibName:@"SELibraryWindow"]) {
  }
  return self;
}

- (void)dealloc {
  [super dealloc];
}

- (void)awakeFromNib {
  
  [appSource setCompareFunction:SparkAppCompare];
  /* Load applications */
  [appSource addObject:[SparkApplication objectWithName:@"Any Application" icon:[NSImage imageNamed:@"System"]]];
  [appSource addObjects:[SparkSharedApplicationLibrary() objects]];
  [appSource rearrangeObjects];
  [appSource setSelectionIndex:0];
  
  SEHeaderCell *header = [[SEHeaderCell alloc] initTextCell:@"Front Application"];
  [header setAlignment:NSCenterTextAlignment];
  [header setFont:[NSFont systemFontOfSize:11]];
  [[[appTable tableColumns] objectAtIndex:0] setHeaderCell:header];
  [header release];
  [appTable setCornerView:[[[SEHeaderCellCorner alloc] init] autorelease]];
  
  header = [[SEHeaderCell alloc] initTextCell:@"Library"];
  [header setAlignment:NSCenterTextAlignment];
  [header setFont:[NSFont systemFontOfSize:11]];
  [[[libraryTable tableColumns] objectAtIndex:0] setHeaderCell:header];
  [header release];
  [libraryTable setCornerView:[[[SEHeaderCellCorner alloc] init] autorelease]];
  
  //[appTable registerForDraggedTypes:[NSArray arrayWithObjects:@"SparkApplicationDragType", nil]];
}

- (void)windowDidLoad {
  [[self window] center];
  [[self window] setFrameAutosaveName:@"SparkMainWindow"];
  [[self window] setBackgroundColor:[NSColor colorWithDeviceWhite:.773 alpha:1]];
  [[self window] display];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  NSTableView *table = [aNotification object];
  int selection = [table selectedRow];
  if (selection >= 0) {
    SparkApplication *app = [[appSource arrangedObjects] objectAtIndex:selection];
    [triggers setApplication:app];
  }
}

#pragma mark Drag & Drop
//- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
//  NSArray *applications = [[appSource arrangedObjects] objectsAtIndexes:rowIndexes];
//  [pboard declareTypes:[NSArray arrayWithObject:@"SparkApplicationDragType"] owner:self];
//  NSMutableArray *ids = [[NSMutableArray alloc] init];
//  unsigned idx = [applications count];
//  while (idx-- > 0) {
//    [ids addObject:SKUInt([[applications objectAtIndex:idx] uid])];
//  }
//  [pboard setPropertyList:ids forType:@"SparkApplicationDragType"];
//  [ids release];
//  return NO;
//}

//- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation {
//  NSPasteboard *pboard = [info draggingPasteboard];
//  if ([[pboard types] containsObject:@"SparkApplicationDragType"]) {
//    if (NSTableViewDropAbove == operation && row >= 2) {
//      return NSDragOperationMove;
//    }
//  }
//  return NSDragOperationNone;
//}

//- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
//  return NO;
//}

@end

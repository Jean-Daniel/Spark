//
//  ListsTableDataSource.m
//  Spark Editor
//
//  Created by Grayfox on 20/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "ListsTableDataSource.h"
#import <SparkKit/SparkKit.h>

@implementation ListsTableDataSource

#pragma mark -
#pragma mark Drag & Drop Support
- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation {
  NSDragOperation op = NSDragOperationNone;
  if (![self pasteboardType] || operation != NSTableViewDropOn) {
    op = NSDragOperationNone;
  } else if ([tableView rowAtPoint:[tableView convertPoint:[info draggingLocation] fromView:nil]] < 0) {
    op = NSDragOperationNone;
  } else if (![[[self arrangedObjects] objectAtIndex:row] isEditable]) {
    op = NSDragOperationNone;
  } else if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:[self pasteboardType]]]) {
    op = NSDragOperationCopy;
  }
  return op;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
  if (![self pasteboardType]) {
    return NO;
  }
  SparkObjectList *list = [[self arrangedObjects] objectAtIndex:MIN((unsigned)row, [[self arrangedObjects] count] -1)];
  id uids = [[[info draggingPasteboard] propertyListForType:[self pasteboardType]] objectEnumerator];
  id uid;
  id lib = [list contentsLibrary];
  while (uid = [uids nextObject]) {
    [list addObject:(id)[lib objectWithId:uid]];
  }
  return YES;
}

@end

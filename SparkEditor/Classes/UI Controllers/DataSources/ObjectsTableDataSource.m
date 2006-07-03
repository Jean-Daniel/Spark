//
//  ObjectsTableDataSource.m
//  Spark Editor
//
//  Created by Grayfox on 20/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "ObjectsTableDataSource.h"
#include <Carbon/Carbon.h>

@implementation ObjectsTableDataSource

/* Compatibility with Mac OS X.3 */
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
  return [self tableView:aTableView writeRows:[rowIndexes toArray] toPasteboard:pboard];
}

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
  id pboardType = [self pasteboardType];
  if (!pboardType) {
    return NO;
  }
  [pboard declareTypes:[NSArray arrayWithObjects:pboardType, nil] owner:self];
  NSMutableArray *uids = [[NSMutableArray alloc] init];
  id objects = [self arrangedObjects];
  id items = [rows objectEnumerator];
  id row;
  while (row = [items nextObject]) {
    [uids addObject:[[objects objectAtIndex:[row intValue]] uid]];
  }
  [pboard setPropertyList:uids forType:pboardType];
  [uids release];
  return YES;
}

@end

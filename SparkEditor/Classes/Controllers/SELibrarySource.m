//
//  SELibrarySource.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 31/07/06.
//  Copyright 2006 Adamentium. All rights reserved.
//

#import "SELibrarySource.h"

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkLibrary.h>

static 
NSComparisonResult SECompareList(SparkList *l1, SparkList *l2, void *ctxt) {
  /* First reserved objects */
  if ([l1 uid] < 128) {
    if ([l2 uid] < 128) {
      return [l1 uid] - [l2 uid];
    } else {
      return NSOrderedAscending;
    }
  } else if ([l2 uid] < 128) {
    return NSOrderedDescending;
  }
  /* Seconds, plugins */
  if ([l1 uid] < kSparkLibraryReserved) {
    if ([l2 uid] < kSparkLibraryReserved) {
      return [[l1 name] caseInsensitiveCompare:[l2 name]];
    } else {
      return NSOrderedAscending;
    }
  } else if ([l2 uid] < kSparkLibraryReserved) {
    return NSOrderedDescending;
  }
  
  return [[l1 name] caseInsensitiveCompare:[l2 name]];
}

@implementation SELibrarySource

- (id)init {
  if (self = [super init]) {
    se_content = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  [se_content release];
  [super dealloc];
}

- (void)rearrangeObjects {
  [se_content sortUsingFunction:SECompareList context:NULL];
}

- (id)objectAtIndex:(unsigned)idx {
  return [se_content objectAtIndex:idx];
}

- (void)addObject:(SparkObject *)object {
  [se_content addObject:object];
}

- (void)addObjects:(NSArray *)objects {
  [se_content addObjectsFromArray:objects];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
  return [se_content count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
  return [se_content objectAtIndex:row];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
  SparkObject *item = [se_content objectAtIndex:row];
  NSString *name = [item name];
  if (![name isEqualToString:object]) {
    [item setName:object];
    [self rearrangeObjects];
    [tableView reloadData];
    DLog(@"Select index: %i", [se_content indexOfObjectIdenticalTo:item]);
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[se_content indexOfObjectIdenticalTo:item]] byExtendingSelection:NO];
  }
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  if (rowIndex > 0) {
    SparkObject *item = [se_content objectAtIndex:rowIndex];
    return [item uid] > kSparkLibraryReserved;
  }
  return NO;
}

- (void)deleteSelectionInTableView:(NSTableView *)aTableView {
  int idx = [aTableView selectedRow];
  if (idx > 0) {
    SparkObject *object = [se_content objectAtIndex:idx];
    if ([object uid] > kSparkLibraryReserved) {
      [se_content removeObjectAtIndex:idx];
      [aTableView reloadData];
    } else {
      NSBeep();
    }
  }
}

@end

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
#import <SparkKit/SparkActionLoader.h>

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
    /* Add library… */
    [se_content addObject:[SparkList objectWithName:@"Library" icon:[NSImage imageNamed:@"Library"]]];
    /* …, plugins list… */
    NSArray *plugins = [[SparkActionLoader sharedLoader] plugins];
    unsigned idx = [plugins count];
    while (idx-- > 0) {
      SparkPlugIn *plugin = [plugins objectAtIndex:idx];
      SparkList *list = [[SparkList alloc] initWithName:[plugin name] icon:[plugin icon]];
      [list setUID:128];
      [se_content addObject:list];
      [list release];
    }
    /* …and User defined lists */
    [se_content addObjectsFromArray:[SparkSharedListSet() objects]];
    
    [self rearrangeObjects];
  }
  return self;
}

- (void)dealloc {
  [se_content release];
  [super dealloc];
}

- (void)awakeFromNib {
  if (se_delegate)
    [self tableViewSelectionDidChange:nil];
}

- (id)delegate {
  return se_delegate;
}

- (void)setDelegate:(id)aDelegate {
  se_delegate = aDelegate;
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
    
    //  [tableView reloadData]; => End editing already call reload data.
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[se_content indexOfObjectIdenticalTo:item]] byExtendingSelection:NO];
  }
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  if (rowIndex >= 0) {
    SparkObject *item = [se_content objectAtIndex:rowIndex];
    return [item uid] > kSparkLibraryReserved;
  }
  return NO;
}

- (IBAction)newList:(id)sender {
  SparkList *list = [[SparkList alloc] initWithName:@"New List"];
  [SparkSharedListSet() addObject:list];
  [list release];
  [se_content addObject:list];
  [self rearrangeObjects];
  [table reloadData];
  unsigned idx = [se_content indexOfObjectIdenticalTo:list];
  // Notify delegate with list and index.
  if (SKDelegateHandle(se_delegate, source:didAddList:atIndex:)) {
    [se_delegate source:self didAddList:list atIndex:idx];
  } else {
    [table selectRow:idx byExtendingSelection:NO];
    [table editColumn:0 row:idx withEvent:nil select:YES];
  }
}

- (void)deleteSelectionInTableView:(NSTableView *)aTableView {
  int idx = [aTableView selectedRow];
  if (idx >= 0) {
    SparkObject *object = [se_content objectAtIndex:idx];
    if ([object uid] > kSparkLibraryReserved) {
      [SparkSharedListSet() removeObject:object];
      [se_content removeObjectAtIndex:idx];
      [aTableView reloadData];
      /* last item */
      if ((unsigned)idx == [se_content count]) {
        [aTableView selectRow:[se_content count] - 1 byExtendingSelection:NO];
      }
    } else {
      NSBeep();
    }
  }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  int idx = [table selectedRow];
  if (idx >= 0) {
    if (SKDelegateHandle(se_delegate, source:didChangeSelection:)) {
      [se_delegate source:self didChangeSelection:[se_content objectAtIndex:idx]];
    }
  }
}

@end

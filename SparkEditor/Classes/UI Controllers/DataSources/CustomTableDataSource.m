//
//  CustomTableDataSource.m
//  Spark
//
//  Created by Fox on Wed Jan 14 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "CustomTableDataSource.h"

@implementation CustomTableDataSource

- (void)dealloc {
  [_pboardType release];
  [_searchString release];
  [super dealloc];
}

#pragma mark -
#pragma mark Drag & Drop Methods
- (NSString *)pasteboardType {
  return _pboardType;
}

- (void)setPasteboardType:(NSString *)type {
  if (_pboardType != type) {
    [_pboardType release];
    _pboardType = [type retain];
  }
}

#pragma mark -
#pragma mark Sort Methods
- (CompareFunction)compareFunction {
  return _compare;
}
- (void)setCompareFunction:(CompareFunction)function {
  _compare = function;
  [self rearrangeObjects];
}

#pragma mark -
#pragma mark Search Methods
- (IBAction)search:(id)sender {
  // set the search string by getting the stringValue
  // from the sender
  NSString *str = [sender stringValue];
  [self setSearchString:[str length] ? str : nil];
  [self rearrangeObjects];    
}

- (NSString *)searchString {
  return _searchString;
}

- (void)setSearchString:(NSString *)aString {
  if (aString != _searchString) {
    [_searchString release];
    _searchString = [aString retain];  
  }
}

- (FilterFunction)filterFunction {
  return _filter;
}
- (void)setFilterFunction:(FilterFunction)function context:(void *)ctxt {
  _filter = function;
  _filterCtxt = ctxt;
  [self rearrangeObjects];
}

#pragma mark -
#pragma mark Custom Arrange Algorithm
- (NSArray *)arrangeObjects:(id)objects {
  id result = nil;
  if (_filter) {
    NSMutableArray *filteredObjects = [NSMutableArray arrayWithCapacity:[objects count]];
    NSEnumerator *objectsEnumerator = [objects objectEnumerator];
    id item;
    
    while (item = [objectsEnumerator nextObject]) {
      if (_filter(_searchString, item, _filterCtxt)) {
        [filteredObjects addObject:item];
      }
    }
    result = filteredObjects;
  } else {
    result = objects;
  }
  
  if (_compare) {
    @try { /* If Mutable Array sort it */
      [result sortUsingFunction:_compare context:self];
    } @catch (id exception) { /* else return a sorted copy */
      result = [result sortedArrayUsingFunction:_compare context:self];
    }
  } else {
    result = [super arrangeObjects:result];
  }
  return result;
}

#pragma mark -
#pragma mark TableView DataSource Protocol
/* Use to be DataSource compliante, but all values in tables are obtains by KVB */
- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
  return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  return nil;
}

#pragma mark Drag & Drop Implementation

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation {
  return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
  return NO;
}

@end

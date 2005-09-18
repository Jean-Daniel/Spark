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

#pragma mark Drag & Drop Implementation

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation {
  return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
  return NO;
}

@end

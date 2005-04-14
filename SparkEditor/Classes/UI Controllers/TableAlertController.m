//
//  TableAlertController.m
//  Spark Editor
//
//  Created by Grayfox on 11/10/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "TableAlertController.h"


@implementation TableAlertController

- (id)init {
  if (self = [super initWithWindowNibName:@"TableAlert"]) {
    [self window];
  }
  return self;
}

- (id)initForSingleDelete {
  if (self = [self init]) {
    [self window];
    [defaultButton setTitle:NSLocalizedStringFromTable(@"TABLE_ALERT_DELETE_BUTTON",
                                                       @"Libraries", @"Table Alert single delete button")];
    [otherButton setHidden:TRUE];
  }
  return self;
}

- (void)dealloc {
  [_values release];
  [super dealloc];
}

- (void)setValues:(NSArray *)values {
  [_values release];
  _values = nil;
  if (values) {
    _values = [[NSMutableArray alloc] initWithArray:values];
    id desc = [[NSSortDescriptor alloc] initWithKey:@"name"
                                          ascending:YES
                                           selector:@selector(caseInsensitiveCompare:)];
    [_values sortUsingDescriptors:[NSArray arrayWithObject:desc]];
    [desc release];
    [tableView reloadData];
  }
}
- (void)setTitle:(NSString *)newTitle {
  [titleField setStringValue:(newTitle) ? newTitle : @""];
}

- (IBAction)deleteAll:(id)sender {
  _returnCode = NSAlertOtherReturn;
  [self close];
}

- (IBAction)deleteUnused:(id)sender {
  _returnCode = NSAlertDefaultReturn;
  [self close];
}

- (IBAction)cancel:(id)sender {
  _returnCode = NSAlertAlternateReturn;
  [self close];
}

- (void)close {
  if ([[self window] isSheet])
    [NSApp endSheet:[self window] returnCode:_returnCode];
  else {
    [NSApp stopModalWithCode:_returnCode];
  }
  [super close];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
  return [_values count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  if ([[aTableColumn identifier] isEqualToString:@"_item"]) {
    return [_values objectAtIndex:rowIndex];
  } else {
    return [[_values objectAtIndex:rowIndex] valueForKey:[aTableColumn identifier]];
  }
}

@end

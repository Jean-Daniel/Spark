//
//  TableAlertController.h
//  Spark Editor
//
//  Created by Grayfox on 11/10/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TableAlertController : NSWindowController {
  IBOutlet NSTextField *titleField;
  IBOutlet NSTableView *tableView;
  
  IBOutlet NSButton *defaultButton;
  IBOutlet NSButton *alternateButton;
  IBOutlet NSButton *otherButton;
  
  NSMutableArray *_values;
@private
  int _returnCode;
}

- (id)init;
- (id)initForSingleDelete;

- (void)setValues:(NSArray *)values;
- (void)setTitle:(NSString *)newTitle;

- (IBAction)deleteUnused:(id)sender;
- (IBAction)deleteAll:(id)sender;
- (IBAction)cancel:(id)sender;

@end

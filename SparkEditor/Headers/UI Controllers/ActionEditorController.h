//
//  ActionEditorController.h
//  Spark Editor
//
//  Created by Fox on 03/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ObjectEditorController.h"

@class SparkAction, ActionEditor;
@interface ActionEditorController : ObjectEditorController {
  IBOutlet NSButton *helpButton;
  IBOutlet ActionEditor *actionEditor;
}

- (id)object;
- (void)setObject:(id)anObject;

- (SparkPlugIn *)selectedPlugin;
- (void)selectActionPlugin:(SparkPlugIn *)plugin;

- (IBAction)create:(id)sender;
- (IBAction)update:(id)sender;
- (IBAction)revert:(id)sender;

@end

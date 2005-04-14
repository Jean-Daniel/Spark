//
//  ActionEditorController.m
//  Spark Editor
//
//  Created by Fox on 03/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit.h>

#import "ActionEditorController.h"

#import "Spark.h"
#import "ActionEditor.h"

@implementation ActionEditorController

- (id)init {
  if (self = [super initWithWindowNibName:@"ActionEditor" owner:self]) {
    [self window]; /* Load immediatly */
  }
  return self;
}

- (id)object {
  return [actionEditor sparkAction];
}
- (void)setObject:(id)sparkAction {
  [super setObject:sparkAction];
  [actionEditor setAllowsChangeActionType:NO];
  [actionEditor setSparkAction:sparkAction];
}

- (SparkPlugIn *)selectedPlugin {
  return [actionEditor selectedPlugin];
}

- (void)selectActionPlugin:(SparkPlugIn *)plugin {
  [actionEditor selectActionPlugin:plugin];
}

- (IBAction)create:(id)sender {
  id alert = [actionEditor create];
  if (nil != alert) {
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:nil
                     didEndSelector:nil
                        contextInfo:nil];
  } else {
    [super create:self];
  }
}

- (IBAction)update:(id)sender {
  id alert = [actionEditor update];
  if (nil != alert) {
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:nil
                     didEndSelector:nil
                        contextInfo:nil];
  } else {
    [super update:self];
  }
}

- (IBAction)revert:(id)sender {
  [actionEditor revert];
  [super revert:sender];
}

- (NSUndoManager *)undoManagerForActionEditor:(ActionEditor *)editor {
  return [self undoManager];
}

- (void)actionEditorDidChangePlugin:(NSNotification *)aNotification {
  [helpButton setHidden:![actionEditor helpAvailable]];
}

@end

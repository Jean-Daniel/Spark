/*
 *  SEEntryEditor.m
 *  Spark Editor
 *
 *  Created by Grayfox on 09/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "SEEntryEditor.h"
#import "SEActionEditor.h"

@implementation SEEntryEditor

- (id)init {
  if (self = [super initWithWindowNibName:@"SEEntryEditor"]) {
    
  }
  return self;
}

- (void)dealloc {
  [se_editor release];
  [super dealloc];
}

/* Internal method called by nib loader */
- (void)setEditor:(NSView *)editor {
  NSAssert(se_editor == nil, @"Set editor call while editor already initialized");
  NSView *parent = [editor superview];
  [editor removeFromSuperview];
  se_editor = [[SEActionEditor alloc] init];
  [[se_editor view] setFrame:[editor frame]];
  [parent addSubview:[se_editor view]];
}

- (IBAction)ok:(id)sender {
  [self close:sender];
}

- (IBAction)cancel:(id)sender {
  [self close:sender];
}

@end

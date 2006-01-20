//
//  ObjectEditorController.m
//  Spark Editor
//
//  Created by Fox on 11/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "ObjectEditorController.h"
#import <SparkKit/SparkKit.h>

NSString * const kObjectEditorWillCloseNotification = @"ObjectEditorWillCloseNotification";

@implementation ObjectEditorController

- (void)windowDidLoad {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(windowWillClosePrivate:)
                                               name:NSWindowWillCloseNotification
                                             object:[self window]];
}

- (void)dealloc {
//  ShadowTrace();
  [[NSNotificationCenter defaultCenter] removeObserver:self]; 
  [self setDelegate:nil];
  [_undo release];
  [super dealloc];
}

- (NSUndoManager *)undoManager {
  return _undo;
}

- (id)delegate {
  return _delegate;
}

- (void)setDelegate:(id)delegate {
  if (_delegate != delegate) {
    if (nil != _delegate)
      [[NSNotificationCenter defaultCenter] removeObserver:_delegate name:nil object:self];
    _delegate = delegate;
    if (nil != _delegate)
      SKRegisterDelegateForNotification(_delegate, @selector(objectEditorWillClose:), kObjectEditorWillCloseNotification);
  }
}

- (id)object {
  return nil;
}

- (void)setObject:(id)object {
  if (nil != _undo) {
    [_undo release];
  }
  _undo = [[NSUndoManager alloc] init];
  [_undo setGroupsByEvent:NO];
  [_undo beginUndoGrouping];
  
  [defaultButton setTitle:NSLocalizedStringFromTable(@"OBJECT_EDITOR_UPDATE",
                                                     @"Editors", @"Object Editor Update Button")];
  [defaultButton setAction:@selector(update:)];
  
  [cancelButton setAction:@selector(revert:)];
}

- (BOOL)isUpdating {
  return [defaultButton action] == @selector(update:);
}

#pragma mark -
- (IBAction)create:(id)sender {
  if ([_delegate respondsToSelector:@selector(objectEditor:createObject:)]) {
    [_delegate objectEditor:self createObject:[self object]];
  }
  [self close];
}

- (IBAction)cancel:(id)sender {
  [self close];
}

- (IBAction)update:(id)sender {
  if ([_delegate respondsToSelector:@selector(objectEditor:updateObject:)]) {
    [_delegate objectEditor:self updateObject:[self object]];
  }
  [self close];
}

- (IBAction)revert:(id)sender {
  [_undo endUndoGrouping];
  [_undo undo];
  [self close];
}

- (void)close {
  if ([[self window] isSheet]) {
    [NSApp endSheet:[self window]];
  }
  [super close];
}

- (void)windowWillClosePrivate:(NSNotification *)aNotification {
  [[NSNotificationCenter defaultCenter] postNotificationName:kObjectEditorWillCloseNotification object:self];
}

@end

//
//  ObjectEditorController.h
//  Spark Editor
//
//  Created by Fox on 11/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const kObjectEditorWillCloseNotification;

@interface ObjectEditorController : NSWindowController {
  IBOutlet NSButton *defaultButton;
  IBOutlet NSButton *cancelButton;
@private
  id _delegate; /* Weak Ref */
  NSUndoManager *_undo;
}

- (BOOL)isUpdating;

- (id)object;
- (void)setObject:(id)object;

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (NSUndoManager *)undoManager;

- (IBAction)create:(id)sender;
- (IBAction)cancel:(id)sender;

- (IBAction)update:(id)sender;
- (IBAction)revert:(id)sender;

@end

@interface NSObject (ObjectEditorDelegate) 
- (void)objectEditor:(ObjectEditorController *)editor createObject:(id)object;
- (void)objectEditor:(ObjectEditorController *)editor updateObject:(id)object;
- (void)objectEditorWillClose:(NSNotification *)aNotification;
@end

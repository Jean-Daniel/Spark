//
//  ActionEditorView.h
//  Spark Editor
//
//  Created by Grayfox on 18/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const kActionEditorWillChangePluginNotification;
extern NSString * const kActionEditorDidChangePluginNotification;

@class SparkAction, SparkPlugIn;
@interface ActionEditor : NSView {
}

- (NSAlert *)create;
- (void)cancel;

- (NSAlert *)update;
- (void)revert;

@end

@interface ActionEditor (AbstractAPI)

- (IBAction)showPluginHelp:(id)sender;

- (BOOL)helpAvailable;

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (BOOL)allowsChangeActionType;
- (void)setAllowsChangeActionType:(BOOL)canChange;

- (id)sparkAction;
- (void)setSparkAction:(id)sparkAction;

- (SparkPlugIn *)selectedPlugin;
- (void)selectActionPlugin:(SparkPlugIn *)plugin;

#pragma mark UI Elements Accessors.
- (NSMenu *)pluginMenu;
@end

@interface NSObject (ActionEditorDelegate)
- (NSUndoManager *)undoManagerForActionEditor:(ActionEditor *)editor;
- (NSSize)actionEditor:(ActionEditor *)sender willResize:(NSSize)proposedFrameSize forView:(NSView *)aView;

- (void)actionEditorWillChangePlugin:(NSNotification *)aNotification;
- (void)actionEditorDidChangePlugin:(NSNotification *)aNotification;
@end

//
//  AppActionEditor.h
//  Spark Editor
//
//  Created by Grayfox on 27/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ObjectEditorController.h"

@class LibraryController;
@interface AppActionEditor : ObjectEditorController {
  IBOutlet id toolbar;
  IBOutlet id contentView;
  IBOutlet NSTextField *appName;
  IBOutlet NSImageView *appIcon;
  IBOutlet NSTextField *actionName;
  IBOutlet NSImageView *actionIcon;
  
  LibraryController *_appLibrary;
  LibraryController *_actionLibrary;
  
  NSMutableDictionary *_object;
}

- (BOOL)applicationEnabled;
- (void)setApplicationEnabled:(BOOL)flag;

- (IBAction)selectTab:(id)sender;

- (void)updateApplicationObject;
- (void)updateApplicationList;
- (void)updateActionsSelection;

@end

@interface NSObject (AppActionEditorDelegate)
- (BOOL)appActionEditor:(AppActionEditor *)editor willValidateObject:(id)object;
@end

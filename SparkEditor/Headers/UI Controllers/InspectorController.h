//
//  InspectorController.h
//  Spark Editor
//
//  Created by Grayfox on 15/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LibraryController;
@interface InspectorController : NSWindowController {
  IBOutlet id contentView;
  NSSearchField *searchField;
  
  LibraryController *_appLibrary;
  LibraryController *_actionLibrary;
}

+ (InspectorController *)sharedInspector;
- (LibraryController *)frontLibrary;
- (IBAction)selectTab:(id)sender;
- (void)createToolbar;

@end

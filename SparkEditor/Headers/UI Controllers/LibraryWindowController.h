//
//  LibraryWindowController.h
//  Spark Editor
//
//  Created by Grayfox on 19/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FirstRunController, KeyLibraryController;
@interface LibraryWindowController : NSWindowController {
  IBOutlet id searchField;
  IBOutlet NSView *contentView;
  
  FirstRunController *firstRun;
  KeyLibraryController *keyLibrary;
}

- (void)refresh;

- (void)checkActions;
- (void)checkFirstRun;

- (void)saveWorkspace;
- (void)restoreWorkspace;

- (NSImage *)startStopImage;
- (NSImage *)startStopAlternateImage;

@end

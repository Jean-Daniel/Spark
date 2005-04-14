//
//  Spark.h
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SparkExporter.h"
#import "SparkServerProtocol.h"

@class SparkLibrary;
@interface Spark : NSObject {
  IBOutlet NSMenu *aboutMenu;
  /* Export List */
  IBOutlet NSView *exportView;
  SparkExportFormat exportFormat;
  
  /* Global windows */
  id libraryWindow;
  id prefWindows;
  id plugInHelpWindow;
  
/* Scripting Addition */
  DaemonStatus serverState;
}

#pragma mark Restart Functions
+ (void)restartSpark;
+ (void)restartDaemon;

#pragma mark Menu IBActions
- (IBAction)startStopServer:(id)sender;
- (IBAction)openInspector:(id)sender;
- (IBAction)openPreferences:(id)sender;
- (IBAction)openLibraryWindow:(id)sender;

#pragma mark Import/Export Support
- (IBAction)importLibrary:(id)sender;

#pragma mark PlugIn Help Support
- (id)plugInHelpWindow;
- (IBAction)showPlugInHelp:(id)sender; 
- (void)showPlugInHelpPage:(NSString *)page;

#pragma mark Live Update Support
- (IBAction)checkForNewVersion:(id)sender;

- (void)createAboutMenu;
#if defined (DEBUG)
- (void)createDebugMenu;
#endif

@end

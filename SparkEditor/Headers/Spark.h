//
//  Spark.h
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

//#import "SparkExporter.h"
#import <SparkKit/SparkAppleScriptSuite.h>

@class SparkLibrary;
@class SELibraryWindow;
@class SEPreferencesWindow;

@interface SparkEditor : NSApplication {
}

- (NSWindow *)libraryWindow;

@end


@interface Spark : NSObject {
  IBOutlet NSMenu *aboutMenu;
  SELibraryWindow *se_mainWindow;
  
  /* Global windows */
  SEPreferencesWindow *se_preferences;
//  id plugInHelpWindow;
  
/* Scripting Addition */
  DaemonStatus se_serverState;
}

#pragma mark Restart Functions
+ (void)restartSpark;
+ (void)restartDaemon;

#pragma mark Menu IBActions
- (IBAction)startStopServer:(id)sender;
//- (IBAction)openInspector:(id)sender;
- (IBAction)showPreferences:(id)sender;

- (IBAction)showMainWindow:(id)sender;

#pragma mark Import/Export Support
//- (IBAction)importLibrary:(id)sender;

#pragma mark PlugIn Help Support
//- (id)plugInHelpWindow;
- (IBAction)showPlugInHelp:(id)sender; 
- (void)showPlugInHelpPage:(NSString *)page;

#pragma mark Live Update Support
//- (IBAction)checkForNewVersion:(id)sender;

- (void)createAboutMenu;
#if defined (DEBUG)
- (void)createDebugMenu;
#endif

@end

/*
 *  Spark.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

//#import "SparkExporter.h"
#import <SparkKit/SparkAppleScriptSuite.h>

@class SparkLibrary;
@class SELibraryWindow;
@class SEPreferencesWindow;

@interface SparkEditor : NSApplication {
  /* Scripting Addition */
  NSMenu *se_plugins;
  SparkDaemonStatus se_status;
}

- (NSMenu *)pluginsMenu;

@end


@interface Spark : NSObject {
  IBOutlet NSMenu *aboutMenu;
  IBOutlet NSMenuItem *statusMenuItem;
  @private
    /* Global windows */
    SELibraryWindow *se_mainWindow;
  SEPreferencesWindow *se_preferences;
}

#pragma mark Menu IBActions
- (IBAction)toggleServer:(id)sender;
- (IBAction)showPreferences:(id)sender;

- (NSWindow *)mainWindow;
- (IBAction)showMainWindow:(id)sender;

#pragma mark Import/Export Support
//- (IBAction)importLibrary:(id)sender;

#pragma mark PlugIn Help Support
- (IBAction)showPlugInHelp:(id)sender;
- (void)showPlugInHelpPage:(NSString *)page;

#pragma mark Live Update Support
//- (IBAction)checkForNewVersion:(id)sender;

- (void)createAboutMenu;
#if defined (DEBUG)
- (void)createDebugMenu;
#endif

@end

@interface Spark (SEFirstRun)
- (void)displayFirstRunIfNeeded;
@end


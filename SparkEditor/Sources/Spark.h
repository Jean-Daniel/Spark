/*
 *  Spark.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkAppleScriptSuite.h>

SK_PRIVATE
NSArray *gSortByNameDescriptors;
SK_PRIVATE
NSString * const SparkTriggerListPboardType;
SK_PRIVATE
NSString * const SESparkEditorDidChangePluginStatusNotification;

/* Spark current version */
SK_PRIVATE
const UInt32 kSparkVersion;

@class SparkLibrary;
@class SELibraryWindow;
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


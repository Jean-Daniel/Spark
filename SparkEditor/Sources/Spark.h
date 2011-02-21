/*
 *  Spark.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkAppleScriptSuite.h>

SPARK_PRIVATE
NSArray *gSortByNameDescriptors;
SPARK_PRIVATE
NSString * const SparkEntriesPboardType;
SPARK_PRIVATE
NSString * const SESparkEditorDidChangePlugInStatusNotification;

SPARK_PRIVATE
void SEPopulatePlugInMenu(NSMenu *menu);

@class SparkLibrary;
@class SELibraryWindow;
@interface SparkEditor : NSApplication {
  /* Scripting Addition */
  NSMenu *se_plugins;
}

- (NSMenu *)plugInsMenu;

@end

@class SEPreferences;
@interface Spark : NSObject {
  @private
  IBOutlet NSMenu *aboutMenu;
  IBOutlet NSMenuItem *statusMenuItem;
  SEPreferences *se_preferences;
}

#pragma mark Menu IBActions
- (IBAction)toggleServer:(id)sender;
- (IBAction)showPreferences:(id)sender;

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

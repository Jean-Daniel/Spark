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

@interface SparkEditor : NSApplication

- (NSMenu *)plugInsMenu;

@end

@interface Spark : NSObject <NSApplicationDelegate>

+ (Spark *)sharedSpark;

// MARK: Menu IBActions
- (IBAction)setAgentEnabled:(id)sender;
- (IBAction)setAgentDisabled:(id)sender;
- (IBAction)showPreferences:(id)sender;

// MARK: Import/Export Support
//- (IBAction)importLibrary:(id)sender;

// MARK: PlugIn Help Support
- (IBAction)showPlugInHelp:(id)sender;
- (void)showPlugInHelpPage:(NSString *)page;

// MARK: Live Update Support
//- (IBAction)checkForNewVersion:(id)sender;

- (void)createAboutMenu;
- (void)createDebugMenu;

@end

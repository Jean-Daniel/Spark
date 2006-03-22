//
//  Preferences.h
//  Spark
//
//  Created by Fox on Wed Jan 21 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kSparkVersion_2_0		0x200
#define kSparkCurrentVersion	kSparkVersion_2_0

extern CFStringRef const kSparkDaemonExecutable;

extern NSString * const kSparkPrefVersion;
extern NSString * const kSparkPrefAutoStart;
extern NSString * const kSparkPrefSingleKeyMode;
extern NSString * const kSparkPrefDisplayPlugins;

/* Optional alerts panels */
extern NSString * const kSparkPrefConfirmDeleteKey;
extern NSString * const kSparkPrefConfirmDeleteList;
extern NSString * const kSparkPrefConfirmDeleteAction;
extern NSString * const kSparkPrefConfirmDeleteApplication;

/* Workspace Layout */
extern NSString * const kSparkPrefMainWindowLibrary;
extern NSString * const kSparkPrefChoosePanelActionLibrary;

extern NSString * const kSparkPrefInspectorSelectedTab;
extern NSString * const kSparkPrefInspectorActionLibrary;
extern NSString * const kSparkPrefInspectorApplicationLibrary;

extern NSString * const kSparkPrefAppActionSelectedTab;
extern NSString * const kSparkPrefAppActionActionLibrary;
extern NSString * const kSparkPrefAppActionApplicationLibrary;

@interface Preferences : NSWindowController {
  IBOutlet NSTabView* tabView;
  BOOL autoStart, autoStartBak;
  unsigned selectedTab;
}
+ (void)setDefaultsValues;

+ (BOOL)autoStart;
+ (void)setAutoStart:(BOOL)flag;

+ (void)checkVersion;
+ (void)verifyAutoStart;

@end

@interface SparkEditorItem : NSToolbarItem {
}
@end

@interface SparkDaemonItem : NSToolbarItem {
}
@end
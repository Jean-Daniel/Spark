/*
 *  ApplicationAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

#define kApplicationActionBundleIdentifier  @"org.shadowlab.spark.action.application"
#define kApplicationActionBundle			[NSBundle bundleWithIdentifier:kApplicationActionBundleIdentifier]

typedef NS_ENUM(uint32_t, ApplicationActionType) {
  kApplicationLaunch          = 'Open', /* 1332766062 */
  kApplicationQuit            = 'Quit', /* 1366649204 */
  kApplicationToggle          = 'Togl', /* 1416587116 */
	kApplicationActivateQuit    = 'AcQu', /* 1097027957 */
  kApplicationHideOther       = 'HidO', /* 1214866511 */
  kApplicationHideFront       = 'HidF', /* 1214866502 */
  
  kApplicationForceQuitFront	= 'FQiF', /* 1179740486 */
  kApplicationForceQuitDialog	= 'FQit', /* 1179740532 */
  kApplicationForceQuitAppli	= 'Kill', /* 1265200236 */
};

enum {
  kFlagsDoNothing      = 0,
  kFlagsBringAllFront  = 1,
  kFlagsBringMainFront = 2,
};

typedef struct _ApplicationVisualSetting {
  BOOL launch;
  BOOL activation;
} ApplicationVisualSetting;

@class WBApplication;

@interface ApplicationAction : SparkAction <NSCoding, NSCopying>

+ (void)getSharedSettings:(ApplicationVisualSetting *)settings;
+ (void)setSharedSettings:(ApplicationVisualSetting *)settings;

@property(nonatomic, copy) NSString * path;

@property(nonatomic) LSLaunchFlags flags;

@property(nonatomic) BOOL reopen;

@property(nonatomic) NSInteger activation;

@property(nonatomic) BOOL usesSharedVisual;

- (void)getVisualSettings:(ApplicationVisualSetting *)settings;
- (void)setVisualSettings:(ApplicationVisualSetting *)settings;

@property(nonatomic) ApplicationActionType action;

@property(nonatomic, readonly) WBApplication *application;

- (void)launchApplication;
- (void)quitApplication;
- (void)toggleApplicationState;
- (void)activateQuitApplication;

- (void)forceQuitFront;
- (void)forceQuitDialog;
- (void)forceQuitApplication;

- (void)hideFront;
- (void)hideOthers;

- (BOOL)launchAppWithFlag:(LSLaunchFlags)flag;

@end

SPARK_PRIVATE
NSImage *ApplicationActionIcon(ApplicationAction *action);

SPARK_PRIVATE
NSString *ApplicationActionDescription(ApplicationAction *anAction, NSString *name);


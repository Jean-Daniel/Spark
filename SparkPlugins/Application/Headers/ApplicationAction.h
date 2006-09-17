/*
 *  ApplicationAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) Shadow Lab. 2004 - 2006. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>

SPARK_PRIVATE
NSString * const kApplicationActionBundleIdentifier;

#define ApplicationActionBundle			[NSBundle bundleWithIdentifier:kApplicationActionBundleIdentifier]

typedef enum {
  kApplicationLaunch	= 'Open', /* 1332766062 */
  kApplicationQuit		= 'Quit', /* 1366649204 */
  kApplicationToggle	= 'Togl', /* 1416587116 */
  kApplicationForceQuit	= 'FQit', /* 1179740532 */
  kApplicationHideOther	= 'HidO', /* 1214866511 */
  kApplicationHideFront	= 'HidF', /* 1214866502 */
} ApplicationActionType;

@class SKAlias, SKApplication;
@interface ApplicationAction : SparkAction <NSCoding, NSCopying> {
  @private
  int aa_action;
  SKAlias *aa_alias;
  LSLaunchFlags aa_flags;
  SKApplication *aa_application;
}

- (NSString *)path;
- (void)setPath:(NSString *)path;

- (SKAlias *)alias;
- (void)setAlias:(SKAlias *)alias;

- (LSLaunchFlags)flags;
- (void)setFlags:(LSLaunchFlags)flags;

- (ApplicationActionType)action;
- (void)setAction:(ApplicationActionType)action;

- (void)hideFront;
- (void)hideOthers;
- (void)launchApplication;
- (void)quitApplication;
- (void)toggleApplicationState;
- (void)killApplication;
- (void)relaunchApplication;

- (BOOL)launchAppWithFlag:(int)flag;

@end

SK_PRIVATE
NSString *ApplicationActionDescription(ApplicationAction *anAction, NSString *name);


/*
 *  ApplicationAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>

SPARK_PRIVATE
NSString * const kApplicationActionBundleIdentifier;

#define kApplicationActionBundle			[NSBundle bundleWithIdentifier:kApplicationActionBundleIdentifier]

typedef enum {
  kApplicationLaunch	= 'Open', /* 1332766062 */
  kApplicationQuit		= 'Quit', /* 1366649204 */
  kApplicationToggle	= 'Togl', /* 1416587116 */
  kApplicationForceQuit	= 'FQit', /* 1179740532 */
  kApplicationHideOther	= 'HidO', /* 1214866511 */
  kApplicationHideFront	= 'HidF', /* 1214866502 */
} ApplicationActionType;

typedef struct _ApplicationVisualSetting {
  BOOL launch;
  BOOL activation;
} ApplicationVisualSetting;

@class SKAliasedApplication;
@interface ApplicationAction : SparkAction <NSCoding, NSCopying> {
  @private
  int aa_action;
  LSLaunchFlags aa_lsFlags;
  SKAliasedApplication *aa_application;
  struct _aa_aaFlags {
    unsigned int active:2;
    unsigned int reopen:1;
    
    unsigned int visual:1;
    unsigned int atLaunch:1;
    unsigned int atActivate:1;
    unsigned int reserved:26;
  } aa_aaFlags;
  IconRef aa_icon;
}

+ (void)getSharedSettings:(ApplicationVisualSetting *)settings;
+ (void)setSharedSettings:(ApplicationVisualSetting *)settings;

- (NSString *)path;
- (void)setPath:(NSString *)path;

- (LSLaunchFlags)flags;
- (void)setFlags:(LSLaunchFlags)flags;

- (BOOL)reopen;
- (void)setReopen:(BOOL)flag;

- (int)activation;
- (void)setActivation:(int)actv;

- (BOOL)usesSharedVisual;
- (void)setUsesSharedVisual:(BOOL)flag;

- (void)getVisualSettings:(ApplicationVisualSetting *)settings;
- (void)setVisualSettings:(ApplicationVisualSetting *)settings;

- (ApplicationActionType)action;
- (void)setAction:(ApplicationActionType)action;

- (void)launchApplication;
- (void)quitApplication;
- (void)toggleApplicationState;
- (void)killApplication;

- (void)hideFront;
- (void)hideOthers;

- (BOOL)launchAppWithFlag:(int)flag;

@end

SK_PRIVATE
NSString *ApplicationActionDescription(ApplicationAction *anAction, NSString *name);


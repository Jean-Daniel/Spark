/*
 *  SystemAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

typedef NS_ENUM(uint32_t, SystemActionType) {
  kSystemLogOut          = 'Logo', /* 1282369391 */
  kSystemSleep           = 'Slep', /* 1399612784 */
  kSystemRestart         = 'Rest', /* 1382380404 */
  kSystemShutDown        = 'Halt', /* 1214344308 */
  kSystemSwitch          = 'Swit', /* 1400334708 */
  kSystemScreenSaver     = 'ScSa', /* 1399018337 */
  /* Accessibility */
  kSystemSwitchGrayscale = 'Gray', /* 1198678393 */
  kSystemSwitchPolarity  = 'Pola', /* 1349479521 */
  /* System event */
  kSystemEject           = 'Ejct', /* 1164600180 */
  kSystemEmptyTrash      = 'Epty', /* 1164997753 */
  kSystemKeyboardViewer  = 'KbVi', /* 1264735849 */
  /* Sound Volume */
  kSystemVolumeUp        = 'VoUp', /* 1450136944 */
  kSystemVolumeDown      = 'VoDo', /* 1450132591 */
  kSystemVolumeMute      = 'Mute', /* 1299543141 */
  /* Brightness */
  kSystemBrightnessUp    = 'BrUp', /* 1114789232 */
  kSystemBrightnessDown  = 'BrDo', /* 1114784879 */  
};

#define kSystemActionBundleIdentifier @"org.shadowlab.spark.action.system"
#define kSystemActionBundle		      [NSBundle bundleWithIdentifier:kSystemActionBundleIdentifier]

@interface SystemAction : SparkAction <NSCoding, NSCopying>

@property(nonatomic) SystemActionType action;

@property(nonatomic) uid_t userID;

@property(nonatomic, copy) NSString *userName;

- (void)logout;
- (void)sleep;
- (void)restart;
- (void)shutDown;
- (void)screenSaver;
- (void)switchSession;

- (void)toggleGray;
- (void)togglePolarity;

- (void)emptyTrash;

/* Sound */
- (void)volumeUp;
- (void)volumeDown;
- (void)toggleMute;

/* Brightness */
+ (BOOL)supportBrightness;

- (void)brightnessUp;
- (void)brightnessDown;

@property(nonatomic) BOOL playFeedback;

@property(nonatomic) BOOL shouldNotify;

@property(nonatomic) BOOL shouldConfirm;

@end

SPARK_PRIVATE
NSImage *SystemActionIcon(SystemAction *anAction);
SPARK_PRIVATE
NSString *SystemActionDescription(SystemAction *anAction);

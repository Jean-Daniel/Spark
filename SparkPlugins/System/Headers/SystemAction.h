/*
 *  SystemAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>

typedef enum {
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
} SystemActionType;

SK_PRIVATE
NSString * const kSystemActionBundleIdentifier;

#define kSystemActionBundle		[NSBundle bundleWithIdentifier:kSystemActionBundleIdentifier]

@interface SystemAction : SparkAction <NSCoding, NSCopying> {
  SystemActionType sa_action;
  struct _sa_saFlags {
    unsigned int notify:1;
    unsigned int confirm:1;
    unsigned int reserved:30;
  } sa_saFlags;
  /* Switch data */
  uid_t sa_uid;
  NSString *sa_uname;
  NSTimeInterval sa_start;
}

- (SystemActionType)action;
- (void)setAction:(SystemActionType)anAction;

- (uid_t)userID;
- (void)setUserID:(uid_t)uid;

- (NSString *)userName;
- (void)setUserName:(NSString *)aName;

- (void)logout;
- (void)sleep;
- (void)restart;
- (void)shutDown;
- (void)screenSaver;
- (void)switchSession;

- (void)toggleGray;
- (void)togglePolarity;

- (void)emptyTrash;
- (void)launchKeyboardViewer;

/* Sound */
- (void)volumeUp;
- (void)volumeDown;
- (void)toggleMute;

/* Brightness */
+ (BOOL)supportBrightness;

- (void)brightnessUp;
- (void)brightnessDown;

- (BOOL)shouldNotify;
- (void)setShouldNotify:(BOOL)flag;

- (BOOL)shouldConfirm;
- (void)setShouldConfirm:(BOOL)flag;

@end

SK_PRIVATE 
NSImage *SystemActionIcon(SystemAction *anAction);
SK_PRIVATE 
NSString *SystemActionDescription(SystemAction *anAction);

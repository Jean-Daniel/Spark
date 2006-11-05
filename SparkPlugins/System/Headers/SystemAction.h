/*
 *  SystemAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>

typedef enum {
  kSystemLogOut          = 'Logo', /* 1282369391 */
  kSystemSleep           = 'Slep', /* 1399612784 */
  kSystemRestart         = 'Rest', /* 1382380404 */
  kSystemShutDown        = 'Halt', /* 1214344308 */
  kSystemFastLogOut      = 'FLog', /* 1179414375 */
  kSystemScreenSaver     = 'ScSa', /* 1399018337 */
  /* Accessibility */
  kSystemSwitchGrayscale = 'Gray', /* 1198678393 */
  kSystemSwitchPolarity  = 'Pola', /* 1349479521 */
  /* System event */
  kSystemEmptyTrash      = 'Epty', /* 1164997753 */
//  kSystemMute,
//  kSystemEject,
//  kSystemVolumeUp,
//  kSystemVolumeDown,
} SystemActionType;

SK_PRIVATE
NSString * const kSystemActionBundleIdentifier;

#define kSystemActionBundle		[NSBundle bundleWithIdentifier:kSystemActionBundleIdentifier]

@interface SystemAction : SparkAction <NSCoding, NSCopying> {
  SystemActionType sa_action;
  struct _sa_saFlags {
    unsigned int confirm:1;
    unsigned int reserved:31;
  } sa_saFlags;
}

- (SystemActionType)action;
- (void)setAction:(SystemActionType)anAction;

- (void)logout;
- (void)sleep;
- (void)restart;
- (void)shutDown;
- (void)fastLogout;
- (void)screenSaver;

- (void)toggleGray;
- (void)togglePolarity;

- (void)emptyTrash;

- (BOOL)shouldConfirm;
- (void)setShouldConfirm:(BOOL)flag;

@end

SK_PRIVATE 
NSString *SystemActionDescription(SystemAction *anAction);

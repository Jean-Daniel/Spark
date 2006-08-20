//
//  SystemAction.h
//  Spark
//
//  Created by Fox on Wed Feb 18 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkPluginAPI.h>

typedef enum {
  kSystemLogOut = 0,
  kSystemSleep,
  kSystemRestart,
  kSystemShutDown,
  kSystemFastLogOut,
  kSystemScreenSaver,
  /* Accessibility */
  kSystemSwitchGrayscale,
  kSystemSwitchPolarity,
  /* System event */
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

- (BOOL)shouldConfirm;
- (void)setShouldConfirm:(BOOL)flag;

@end

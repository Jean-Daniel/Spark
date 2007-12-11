/*
 *  SEPreferences.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKWindowController.h>

SK_PRIVATE
NSString * const kSparkVersionKey;

SK_PRIVATE
NSString * const kSEPreferencesHideDisabled;

SK_PRIVATE
NSString * const kSEPreferencesStartAtLogin;

SK_PRIVATE
NSString * const kSEPreferencesAutoUpdate;

SK_PRIVATE
NSString * const kSparkPrefSingleKeyMode;

@interface SEPreferences : SKWindowController {
  @private
  IBOutlet NSTabView *uiPanels;
  IBOutlet NSOutlineView *uiPlugins;
  IBOutlet NSObjectController *ibController;
  /* update */
  IBOutlet NSTextField *uiUpdateMsg;
  IBOutlet NSTextField *uiUpdateStatus;
  IBOutlet NSProgressIndicator *uiProgress;
  
  BOOL se_login;
  BOOL se_update;
  NSMapTable *se_status;
  NSMutableArray *se_plugins;
}

+ (void)setup;
+ (BOOL)synchronize;

- (float)delay;
- (void)setDelay:(float)delay;

- (IBAction)close:(id)sender;
- (IBAction)apply:(id)sender;
- (IBAction)update:(id)sender;

@end

SK_PRIVATE
void SEPreferencesSetLoginItemStatus(BOOL status);


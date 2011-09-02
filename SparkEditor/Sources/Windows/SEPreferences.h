/*
 *  SEPreferences.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import WBHEADER(WBWindowController.h)

WB_PRIVATE
NSString * const kSparkVersionKey;

WB_PRIVATE
NSString * const kSEPreferencesHideDisabled;

WB_PRIVATE
NSString * const kSEPreferencesStartAtLogin;

WB_PRIVATE
NSString * const kSEPreferencesAutoUpdate;

WB_PRIVATE
NSString * const kSparkPrefSingleKeyMode;

@interface SEPreferences : WBWindowController <NSToolbarDelegate> {
  @private
  IBOutlet NSTabView *uiPanels;
  IBOutlet NSOutlineView *uiPlugins;
  IBOutlet NSObjectController *ibController;
  /* update */
  IBOutlet NSTextField *uiUpdateMsg;
  IBOutlet NSTextField *uiUpdateStatus;
  IBOutlet NSProgressIndicator *uiProgress;
  
  IBOutlet NSComboBox *uiFeedURL;
  IBOutlet NSDateFormatter *ibDateFormat;

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
- (IBAction)checkForUpdates:(id)sender;

@end

WB_PRIVATE
void SEPreferencesSetLoginItemStatus(BOOL status);


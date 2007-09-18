/*
 *  SEPreferences.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKWindowController.h>

SK_PRIVATE
NSString * const kSparkPrefVersion;

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
  IBOutlet NSOutlineView *ibPlugins;
  IBOutlet NSObjectController *ibController;
  
  BOOL se_login;
  NSMapTable *se_status;
  NSMutableArray *se_plugins;
}

+ (void)setup;
+ (BOOL)synchronize;

- (float)delay;
- (void)setDelay:(float)delay;

@end

SK_PRIVATE
void SEPreferencesSetLoginItemStatus(BOOL status);


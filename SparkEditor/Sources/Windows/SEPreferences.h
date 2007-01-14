/*
 *  SEPreferences.h
 *  Spark Editor
 *
 *  Created by Grayfox on 07/09/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKWindowController.h>

SK_PRIVATE
NSString * const kSparkPrefVersion;

SK_PRIVATE
NSString * const kSparkPrefHideDisabled;
SK_PRIVATE
NSString * const kSparkPrefStartAtLogin;
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


/*
 *  SEPluginInstaller.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKWindowController.h>

@interface SEPluginInstaller : SKWindowController {
  @private
  IBOutlet NSMatrix *ibMatrix;
  IBOutlet NSButton *ibIntall;
  IBOutlet NSTextField *ibInfo;
  IBOutlet NSTextField *ibExplain;
  
  NSString *se_plugin;
}


- (void)setPlugin:(NSString *)path;

- (NSString *)installPlugin:(NSString *)plugin domain:(int)skdomain;

@end

/*
 *  SEPluginInstaller.h
 *  Spark Editor
 *
 *  Created by Grayfox on 14/11/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
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

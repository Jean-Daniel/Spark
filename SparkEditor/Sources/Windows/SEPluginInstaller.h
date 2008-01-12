/*
 *  SEPluginInstaller.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import WBHEADER(WBWindowController.h)

@interface SEPluginInstaller : WBWindowController {
  @private
  IBOutlet NSMatrix *ibMatrix;
  IBOutlet NSTextField *ibInfo;
  IBOutlet NSTextField *ibExplain;
  
  NSString *se_plugin;
}


- (void)setPlugin:(NSString *)path;

- (NSString *)installPlugin:(NSString *)plugin domain:(NSInteger)skdomain;

- (IBAction)update:(id)sender;
- (IBAction)install:(id)sender;

@end

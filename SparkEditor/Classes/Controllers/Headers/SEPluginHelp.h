/*
 *  SEPluginHelp.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKWindowController.h>

@class WebView;
@class SparkPlugIn, SKHeaderView;
@interface SEPluginHelp : SKWindowController {
  IBOutlet WebView *ibWeb;
  IBOutlet SKHeaderView *ibHead;
  
  @private
    NSButton *se_previous, *se_next;
  NSPopUpButton *se_plugins;
}

+ (id)sharedPluginHelp;

- (void)setPage:(NSString *)aPage;
- (void)setPlugin:(SparkPlugIn *)aPlugin;

- (IBAction)selectPlugin:(id)sender;

@end

/*
 *  SEPluginHelp.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import WBHEADER(WBWindowController.h)

@class WebView;
@class SparkPlugIn, WBHeaderView;
@interface SEPluginHelp : WBWindowController {
  IBOutlet WebView *ibWeb;
  IBOutlet WBHeaderView *ibHead;
  
  @private
    NSButton *se_previous, *se_next;
  NSPopUpButton *se_plugins;
}

+ (id)sharedPluginHelp;

- (void)loadPluginMenu;

- (void)setPage:(NSString *)aPage;
- (void)setPlugin:(SparkPlugIn *)aPlugin;

- (IBAction)selectPlugin:(id)sender;

@end

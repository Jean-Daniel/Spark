/*
 *  SEPlugInHelp.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <WonderBox/WonderBox.h>

@class WebView;
@class SparkPlugIn;
@interface SEPlugInHelp : WBWindowController {
  IBOutlet WebView *ibWeb;
  IBOutlet NSPopUpButton *ibPlugins;
}

+ (id)sharedPlugInHelp;

- (void)loadPlugInMenu;

- (void)setPage:(NSString *)aPage;
- (void)setPlugIn:(SparkPlugIn *)aPlugin;

- (IBAction)selectPlugIn:(id)sender;

@end

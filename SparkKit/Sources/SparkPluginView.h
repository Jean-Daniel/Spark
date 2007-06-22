/*
 *  SparkPluginView.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKViewController.h>

@class SparkActionPlugIn;
@interface SparkPluginView : SKViewController {
  @private
  IBOutlet NSImageView *uiIcon;
  IBOutlet NSTextField *uiName;
  IBOutlet NSView *uiTrap;
  IBOutlet NSView *uiView;
}

- (void)setPlugin:(SparkActionPlugIn *)aPlugin;
- (void)setPluginView:(NSView *)aView;

- (NSView *)trapPlaceholder;

@end

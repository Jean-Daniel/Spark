/*
 *  SparkPluginView.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPluginView.h>
#import <SparkKit/SparkActionPlugIn.h>

@implementation SparkPluginView

- (id)init {
  if (self = [super initWithViewNibName:@"SparkPluginView"]) {
    /* load nib file */
    [self view];
  }
  return self;
}

- (void)setPlugin:(SparkActionPlugIn *)aPlugin {
  [uiIcon setImage:[[aPlugin class] pluginViewIcon]];
  [uiName setStringValue:[[aPlugin class] pluginFullName]];
}

- (void)setPluginView:(NSView *)aView {
  /* calling [self view] first to load the view */
  NSRect global = [[self view] frame];
  NSRect frame = [aView frame];
  NSRect orig = [uiView frame];
  global.size.width += NSWidth(frame) - NSWidth(orig);
  global.size.height += NSHeight(frame) - NSHeight(orig);
  [[self view] setFrame:global];
  
  NSView *parent = [uiView superview];
  [aView setFrameOrigin:orig.origin];
  [uiView removeFromSuperview];
  uiView = aView;
  [parent addSubview:aView];
  
  [[self view] setAutoresizingMask:[uiView autoresizingMask]];
}

- (NSView *)trapPlaceholder {
  return uiTrap;
}

@end

/*
 *  ITunesVisualSetting.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>
#import "ITunesInfo.h"

@interface ITunesVisualSetting : NSObject {
  IBOutlet NSButton *ibShow;
  @private
    id ia_delegate;
  int ia_loc;
  int ia_config;
  NSString *ia_color;
  ITunesInfo *ia_info;
}

- (IBAction)hide:(id)sender;
- (IBAction)show:(id)sender;
- (IBAction)preview:(id)sender;

- (IBAction)defaultSettings:(id)sender;

- (float)delay;
- (void)setDelay:(float)aDelay;

- (int)location;
- (void)setLocation:(int)idx;

- (BOOL)shadow;
- (void)setShadow:(BOOL)aShadow;

- (NSColor *)color;
- (void)setColor:(NSColor *)aColor;

- (int)colorComponent;
- (void)setColorComponent:(int)cpnt;

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (int)configuration;
- (void)setConfiguration:(int)aConfig;

- (void)getVisual:(ITunesVisual *)visual;
- (void)setVisual:(const ITunesVisual *)visual;

@end

@interface NSObject (ITunesVisualSettingDelegate)

- (void)settingWillChangeConfiguration:(ITunesVisualSetting *)settings;
- (void)settingDidChangeConfiguration:(ITunesVisualSetting *)settings;

@end

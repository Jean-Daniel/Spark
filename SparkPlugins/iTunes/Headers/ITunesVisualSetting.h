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
}

- (IBAction)hide:(id)sender;
- (IBAction)show:(id)sender;
- (IBAction)preview:(id)sender;

- (IBAction)defaultSettings:(id)sender;

@property(nonatomic) CGFloat delay;

@property(nonatomic) NSInteger location;

@property(nonatomic) BOOL shadow;

@property(nonatomic, retain) NSColor *color;

@property(nonatomic) NSInteger colorComponent;

@property(nonatomic, assign) id delegate;

@property(nonatomic) NSInteger configuration;

- (void)getVisual:(ITunesVisual *)visual;
- (void)setVisual:(const ITunesVisual *)visual;

@end

@interface NSObject (ITunesVisualSettingDelegate)

- (void)settingWillChangeConfiguration:(ITunesVisualSetting *)settings;
- (void)settingDidChangeConfiguration:(ITunesVisualSetting *)settings;

@end

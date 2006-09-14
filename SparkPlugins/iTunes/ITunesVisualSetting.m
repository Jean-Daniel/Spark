/*
 *  ITunesVisualSetting.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) Shadow Lab. 2004 - 2006. All rights reserved.
 */

#import "ITunesVisualSetting.h"

@implementation ITunesVisualSetting

- (id)init {
  if (self = [super init]) {
    ia_info = [[ITunesInfo alloc] init];
    ia_config = kiTunesSettingDefault;
    [self setLocation:1];
    [self setColorComponent:0];
  }
  return self;
}

- (void)dealloc {
  [ia_info release];
  [ia_color release]; // useless since color is a constant.
  [super dealloc];
}

- (IBAction)hide:(id)sender {
  [[ia_info window] close];
  [[ia_info window] setIgnoresMouseEvents:YES];
  
  [ibShow setTitle:@"Show"];
  [ibShow setState:NSOffState];
  [ibShow setAction:@selector(show:)];
}

- (IBAction)show:(id)sender {
  [[ia_info window] setIgnoresMouseEvents:NO];
  [ia_info showWindow:sender];

  [ibShow setTitle:@"Hide"];
  [ibShow setState:NSOnState];
  [ibShow setAction:@selector(hide:)];
}

- (IBAction)preview:(id)sender {
  [self hide:sender];
  [ia_info display:sender];
}

SK_INLINE
NSPoint _iTunesGetPointForIndex(int idx) {
  switch (idx) {
    case 0:
      return kiTunesUpperLeft;
    case 1:
      return kiTunesUpperRight;
    case 2:
      return kiTunesBottomLeft;
    case 3:
      return kiTunesBottomRight;
  }
  return NSZeroPoint;
}
SK_INLINE
int _iTunesGetIndexForPoint(NSPoint point) {
  if (SKFloatEquals(point.x, kiTunesUpperLeft.x))
    return 0;
  if (SKFloatEquals(point.x, kiTunesUpperRight.x))
    return 1;
  if (SKFloatEquals(point.x, kiTunesBottomLeft.x))
    return 2;
  if (SKFloatEquals(point.x, kiTunesBottomRight.x))
    return 3;
  
  return 5;
}

- (int)location {
  return ia_loc >= 0 ? ia_loc : 5;
}
- (void)setLocation:(int)idx {
  switch (idx) {
    case 0 ... 3:
      ia_loc = idx;
      [ia_info setPosition:_iTunesGetPointForIndex(idx)];
      [[ia_info window] setMovableByWindowBackground:NO];
      break;
    default:
      ia_loc = -1;
      [[ia_info window] center];
      [[ia_info window] setMovableByWindowBackground:YES];
      [self show:nil];
  }  
}

- (float)delay {
  return [ia_info delay];
}
- (void)setDelay:(float)aDelay {
  [ia_info setDelay:aDelay < 0.5 ? 1 : aDelay];
}

- (BOOL)shadow {
  return [[ia_info window] hasShadow];
}
- (void)setShadow:(BOOL)aShadow {
  [[ia_info window] setHasShadow:aShadow];
}

- (NSColor *)color {
  return ia_color ? [ia_info valueForKey:ia_color] : nil;
}
- (void)setColor:(NSColor *)aColor {
  if (ia_color)
    [ia_info setValue:aColor forKey:ia_color];
}

- (int)colorComponent {
  if ([ia_color isEqualToString:@"borderColor"]) return 1;
  else if ([ia_color isEqualToString:@"backgroundColor"]) return 2;
  else if ([ia_color isEqualToString:@"backgroundTopColor"]) return 4;
  else if ([ia_color isEqualToString:@"backgroundBottomColor"]) return 5;
  return 0;
}

- (void)setColorComponent:(int)component {
  [self willChangeValueForKey:@"color"];
  switch (component) {
    case 0:
      ia_color = @"textColor";
      break;
    case 1:
      ia_color = @"borderColor";
      break;
    case 2:
      ia_color = @"backgroundColor";
      break;
    case 4:
      ia_color = @"backgroundTopColor";
      break;
    case 5:
      ia_color = @"backgroundBottomColor";
      break;
  }
  [self didChangeValueForKey:@"color"];
}

- (id)delegate {
  return ia_delegate;
}

- (void)setDelegate:(id)delegate {
  ia_delegate = delegate;
}

- (int)configuration {
  return ia_config;
}
- (void)setConfiguration:(int)aConfig {
  if (ia_config != aConfig) {
    if (SKDelegateHandle(ia_delegate, settingWillChangeConfiguration))
      [ia_delegate settingWillChangeConfiguration:self];
    ia_config = aConfig;
    if (SKDelegateHandle(ia_delegate, settingDidChangeConfiguration))
      [ia_delegate settingDidChangeConfiguration:self];
  }
}

- (void)getVisual:(ITunesVisual *)visual {
  [ia_info getVisual:visual];
}

- (void)setVisual:(const ITunesVisual *)visual {
  [self willChangeValueForKey:@"delay"];
  [self willChangeValueForKey:@"color"];
  [self willChangeValueForKey:@"shadow"];
  [ia_info setVisual:visual];
  [self didChangeValueForKey:@"shadow"];
  [self didChangeValueForKey:@"color"];
  [self didChangeValueForKey:@"delay"];
  [self setLocation:_iTunesGetIndexForPoint(visual->location)];
}

- (IBAction)defaultSettings:(id)sender {
  [self setVisual:&kiTunesDefaultSettings];
}

@end

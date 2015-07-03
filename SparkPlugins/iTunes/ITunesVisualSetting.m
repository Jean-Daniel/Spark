/*
 *  ITunesVisualSetting.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "ITunesVisualSetting.h"

#import "ITunesAction.h"

@interface ITunesVisualSetting (ITunesPrivate)
- (void)updateLocation:(NSInteger)idx;
@end

@implementation ITunesVisualSetting {
@private
  NSString *ia_color;
  ITunesInfo *ia_info;
  NSInteger _location;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
  return ![key isEqualToString:@"location"];
}

- (id)init {
  if (self = [super init]) {
    ia_info = [[ITunesInfo alloc] init];
    [ia_info setDuration:163 rate:60];
    _configuration = kiTunesSettingDefault;
    [self updateLocation:1];
    [self setColorComponent:0];
  }
  return self;
}

- (void)dealloc {
  [ia_info close];
}

- (IBAction)hide:(id)sender {
  [[ia_info window] close];
  [[ia_info window] setIgnoresMouseEvents:YES];
  
  [ibShow setTitle:NSLocalizedStringFromTableInBundle(@"Show", nil, kiTunesActionBundle,
                                                      @"Hide/Show button * Visual settings *")];
  [ibShow setState:NSOffState];
  [ibShow setAction:@selector(show:)];
}

- (IBAction)show:(id)sender {
  [[ia_info window] setIgnoresMouseEvents:NO];
  [ia_info.window orderFront:sender];

  [ibShow setTitle:NSLocalizedStringFromTableInBundle(@"Hide", nil, kiTunesActionBundle,
                                                      @"Hide/Show button * Visual settings *")];
  [ibShow setState:NSOnState];
  [ibShow setAction:@selector(hide:)];
}

- (IBAction)preview:(id)sender {
  [self hide:sender];
  [ia_info display:sender];
}

WB_INLINE
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
WB_INLINE
int _iTunesGetIndexForPoint(NSPoint point) {
  if (fequal(point.x, kiTunesUpperLeft.x))
    return 0;
  if (fequal(point.x, kiTunesUpperRight.x))
    return 1;
  if (fequal(point.x, kiTunesBottomLeft.x))
    return 2;
  if (fequal(point.x, kiTunesBottomRight.x))
    return 3;
  
  return 5;
}

- (void)updateLocation:(NSInteger)idx {
  [self willChangeValueForKey:@"location"];
  switch (idx) {
    case 0 ... 3:
      _location = idx;
      [[ia_info window] setMovableByWindowBackground:NO];
      [ia_info setPosition:_iTunesGetPointForIndex(idx)];
      break;
    default:
      _location = -1;
      [[ia_info window] setMovableByWindowBackground:YES];
      [ia_info setPosition:[[ia_info window] frame].origin];
  }
  [self didChangeValueForKey:@"location"];
}

- (NSInteger)location {
  return _location >= 0 ? _location : 5;
}
- (void)setLocation:(NSInteger)idx {
  [self updateLocation:idx];
  if (_location < 0) {
    [[ia_info window] center];
    [self show:nil];
  }
}

- (CGFloat)delay {
  return [ia_info delay];
}
- (void)setDelay:(CGFloat)aDelay {
  [ia_info setDelay:aDelay < 0.5 ? 1.5 : aDelay];
}

- (BOOL)shadow {
  return [ia_info hasShadow];
}
- (void)setShadow:(BOOL)aShadow {
  [ia_info setHasShadow:aShadow];
}

- (BOOL)artwork {
  return [ia_info displayArtwork];
}
- (void)setArtwork:(BOOL)flag {
  [ia_info setDisplayArtwork:flag];
}

- (NSColor *)color {
  return ia_color ? [ia_info valueForKey:ia_color] : nil;
}
- (void)setColor:(NSColor *)aColor {
  if (ia_color)
    [ia_info setValue:aColor forKey:ia_color];
}

- (NSInteger)colorComponent {
  if ([ia_color isEqualToString:@"borderColor"]) return 1;
  else if ([ia_color isEqualToString:@"backgroundColor"]) return 2;
  else if ([ia_color isEqualToString:@"backgroundTopColor"]) return 4;
  else if ([ia_color isEqualToString:@"backgroundBottomColor"]) return 5;
  return 0;
}

- (void)setColorComponent:(NSInteger)component {
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

- (void)setConfiguration:(NSInteger)aConfig {
  if (_configuration != aConfig) {
    if (SPXDelegateHandle(_delegate, settingWillChangeConfiguration:))
      [_delegate settingWillChangeConfiguration:self];
    _configuration = aConfig;
    if (SPXDelegateHandle(_delegate, settingDidChangeConfiguration:))
      [_delegate settingDidChangeConfiguration:self];
  }
}

- (void)getVisual:(ITunesVisual *)visual {
  [ia_info getVisual:visual];
}

- (void)setVisual:(const ITunesVisual *)visual {
  [self willChangeValueForKey:@"delay"];
  [self willChangeValueForKey:@"color"];
	[self willChangeValueForKey:@"shadow"];
	[self willChangeValueForKey:@"artwork"];
  [ia_info setVisual:visual];
	[self didChangeValueForKey:@"artwork"];
  [self didChangeValueForKey:@"shadow"];
  [self didChangeValueForKey:@"color"];
  [self didChangeValueForKey:@"delay"];
  [self updateLocation:_iTunesGetIndexForPoint(visual->location)];
}

- (IBAction)defaultSettings:(id)sender {
  [self setVisual:&kiTunesDefaultSettings];
}

@end

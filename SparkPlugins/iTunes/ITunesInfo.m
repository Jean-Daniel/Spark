/*
 *  ITunesInfo.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "ITunesInfo.h"
#import "ITunesAction.h"

#import <ShadowKit/SKCGFunctions.h>
#import <ShadowKit/SKNotificationWindow.h>

#define kiTunesVisualDefaultPosition	{ -1e8, 0 }

const NSPoint kiTunesUpperLeft = kiTunesVisualDefaultPosition;
const NSPoint kiTunesUpperRight = { -2e8, 0 };
const NSPoint kiTunesBottomLeft = { -3e8, 0 };
const NSPoint kiTunesBottomRight = { -4e8, 0 };

const ITunesVisual kiTunesDefaultSettings = {
  YES, 1.f, kiTunesVisualDefaultPosition,
  { 0, 0, 0, 1 },
  /* Gray */
  {.188, .192f, .200f, 1 },
  {.957f, .961f, .973f, 1 },
  {.682f, .703f, .733f, 1 },
  /* Blue */
//  {.314f, .439f, .682f, 1 },
//  {.961f, .969f, .988f, 1 },
//  {.620f, .710f, .886f, 1 },
};

enum {
  kiTunesVisualUL,
  kiTunesVisualUR,
  kiTunesVisualBL,
  kiTunesVisualBR,
  kiTunesVisualOther,
};

SK_INLINE
int _iTunesGetTypeForLocation(NSPoint point) {
  if (SKFloatEquals(point.x, kiTunesUpperLeft.x))
    return kiTunesVisualUL;
  if (SKFloatEquals(point.x, kiTunesUpperRight.x))
    return kiTunesVisualUR;
  if (SKFloatEquals(point.x, kiTunesBottomLeft.x))
    return kiTunesVisualBL;
  if (SKFloatEquals(point.x, kiTunesBottomRight.x))
    return kiTunesVisualBR;
  
  return kiTunesVisualOther;
}
SK_INLINE
NSPoint _iTunesGetLocationForType(int type) {
  switch (type) {
    case kiTunesVisualUL:
      return kiTunesUpperLeft;
    case kiTunesVisualUR:
      return kiTunesUpperRight;
    case kiTunesVisualBL:
      return kiTunesBottomLeft;
    case kiTunesVisualBR:
      return kiTunesBottomRight;
  }
  return NSZeroPoint;
}

@interface ITunesInfoView : NSView {
  @private
  float border[4];
  CGShadingRef shading;
  SKSimpleShadingInfo info;
}

- (void)setVisual:(const ITunesVisual *)visual;

- (NSColor *)borderColor;
- (void)setBorderColor:(NSColor *)aColor;

- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)aColor;

- (NSColor *)backgroundTopColor;
- (void)setBackgroundTopColor:(NSColor *)aColor;

- (NSColor *)backgroundBottomColor;
- (void)setBackgroundBottomColor:(NSColor *)aColor;

@end

@implementation ITunesInfo

+ (void)initialize {
  [NSColor setIgnoresAlpha:NO];
}

+ (ITunesInfo *)sharedWindow {
  static ITunesInfo *shared = nil;
  if (shared)
    return shared;
  else {
    @synchronized(self) {
      if (!shared) {
        shared = [[ITunesInfo alloc] init];
      }
    }
  }
  return shared;
}

- (id)init {
  NSWindow *info = [[SKNotificationWindow alloc] init];
  [info setHasShadow:YES];
  if (self = [super initWithWindow:info]) {
    [NSBundle loadNibNamed:@"iTunesInfo" owner:self];
    [self setVisual:&kiTunesDefaultSettings];
  }
  [info release];
  return self;
}

- (void)dealloc {
  [[self window] close];
  [super dealloc];
}

- (void)setIbView:(NSView *)aView {
  /* Nib root object should be release */
  [[self window] setContentSize:[aView bounds].size];
  [[self window] setContentView:[aView autorelease]];
}

#pragma mark -
- (void)getVisual:(ITunesVisual *)visual {
  bzero(visual, sizeof(*visual));
  /* Get delay */
  visual->delay = [self delay];
  /* Get location */
  if (ia_loc != kiTunesVisualOther) visual->location = _iTunesGetLocationForType(ia_loc);
  else visual->location = [[self window] frame].origin;
  /* Get shadow */
  visual->shadow = [[self window] hasShadow];
  /* Get text color */
  [[[self textColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getComponents:visual->text];
  [(id)[[self window] contentView] getVisual:visual];
}

- (void)setVisual:(const ITunesVisual *)visual {
  [self setDelay:visual->delay];
  [self setPosition:visual->location];
  [self setHasShadow:visual->shadow];
  [self setTextColor:[NSColor colorWithCalibratedRed:visual->text[0] green:visual->text[1] blue:visual->text[2] alpha:visual->text[3]]];
  [[[self window] contentView] setVisual:visual];
}

- (float)delay {
  return [(id)[self window] delay];
}
- (void)setDelay:(float)aDelay {
  [(id)[self window] setDelay:aDelay];
}

#define SCREEN_MARGIN 17
- (void)setPosition:(NSPoint)aPoint {
  NSPoint origin = aPoint;
  NSRect bounds = [[self window] frame];
  NSRect screen = [[NSScreen mainScreen] frame];
  ia_loc = _iTunesGetTypeForLocation(aPoint);
  switch (ia_loc) {
    case kiTunesVisualUL:
      origin.x = SCREEN_MARGIN;
      origin.y = NSHeight(screen) - NSHeight(bounds) - SCREEN_MARGIN - 22; // menu bar
      break;
    case kiTunesVisualUR:
      origin.x = NSWidth(screen) - NSWidth(bounds) - SCREEN_MARGIN;
      origin.y = NSHeight(screen) - NSHeight(bounds) - SCREEN_MARGIN - 22;
      break;
    case kiTunesVisualBL:
      origin.x = SCREEN_MARGIN;
      origin.y = SCREEN_MARGIN + 22;
      break;
    case kiTunesVisualBR:
      origin.x = NSWidth(screen) - NSWidth(bounds) - SCREEN_MARGIN;
      origin.y = SCREEN_MARGIN + 22; // like that
      break;
  }
  [[self window] setFrameOrigin:origin];
}

- (void)setHasShadow:(BOOL)hasShadow {
  [[self window] setHasShadow:hasShadow];
}

- (IBAction)display:(id)sender {
  [(id)[self window] display:sender];
}

- (void)setDuration:(SInt32)aTime rate:(SInt32)rate {
  NSString *str = nil;
  SInt32 days = aTime / (3600 * 24);
  SInt32 hours = (aTime % (3600 * 24)) / 3600;
  SInt32 minutes = (aTime % 3600) / 60;
  SInt32 seconds = aTime % 60;
  
  if (days > 0) {
    str = [NSString stringWithFormat:@"%i:%.2i:%.2i:%.2i - ", days, hours, minutes, seconds];
  } else if (hours > 0) {
    str = [NSString stringWithFormat:@"%i:%.2i:%.2i -", hours, minutes, seconds];
  } else if (minutes > 0 || seconds > 0) {
    str = [NSString stringWithFormat:@"%i:%.2i -", minutes, seconds];
  } else {
    str = @" -";
  }
  [ibTime setStringValue:str];
  /* adjust time size and move rate */
  [ibTime sizeToFit];
  NSPoint origin = [ibRate frame].origin;
  origin.x = NSMaxX([ibTime frame]);
  [ibRate setFrameOrigin:origin];
  
  if (rate > 95) {
    // 5 stars
    str = NSLocalizedStringFromTableInBundle(@"*****", nil, kiTunesActionBundle, @"5 stars rate");
  } else if (rate > 85) {
    // 1 star
    str = NSLocalizedStringFromTableInBundle(@"**** 1/2", nil, kiTunesActionBundle, @"4,5 star rate");
  }  else if (rate > 75) {
    // 4 stars
    str = NSLocalizedStringFromTableInBundle(@"****", nil, kiTunesActionBundle, @"4 stars rate");
  } else if (rate > 65) {
    // 1 star
    str = NSLocalizedStringFromTableInBundle(@"*** 1/2", nil, kiTunesActionBundle, @"3,5 star rate");
  }  else if (rate > 55) {
    // 3 stars
    str = NSLocalizedStringFromTableInBundle(@"***", nil, kiTunesActionBundle, @"3 stars rate");
  } else if (rate > 45) {
    // 1 star
    str = NSLocalizedStringFromTableInBundle(@"** 1/2", nil, kiTunesActionBundle, @"2,5 star rate");
  }  else if (rate > 35) {
    // 2 stars
    str = NSLocalizedStringFromTableInBundle(@"**", nil, kiTunesActionBundle, @"2 stars rate");
  } else if (rate > 25) {
    // 1 star
    str = NSLocalizedStringFromTableInBundle(@"* 1/2", nil, kiTunesActionBundle, @"1,5 star rate");
  }  else if (rate > 15) {
    // 1 star
    str = NSLocalizedStringFromTableInBundle(@"*", nil, kiTunesActionBundle, @"1 star rate");
  } else if (rate > 5) {
    // 1 star
    str = NSLocalizedStringFromTableInBundle(@"1/2", nil, kiTunesActionBundle, @"0,5 star rate");
  } else {
    // 0 star
    str = NSLocalizedStringFromTableInBundle(@"ooooo", nil, kiTunesActionBundle, @"0 star rate");
  }
  [ibRate setStringValue:str ? : @""];
}

- (void)setTrack:(iTunesTrack *)track {
  CFStringRef value = NULL;
  /* Track Name */
  if (track)
    iTunesGetTrackStringProperty(track, kiTunesNameKey, &value);
  if (value) {
    [ibName setStringValue:(id)value];
    CFRelease(value);
    value = NULL;
  } else {
    [ibName setStringValue:@"<untiled>"];
  }
  
  /* Album */
  if (track)
    iTunesGetTrackStringProperty(track, kiTunesAlbumKey, &value);
  if (value) {
    [ibAlbum setStringValue:(id)value];
    CFRelease(value);
    value = NULL;
  } else {
    [ibAlbum setStringValue:@""];
  }
  
  /* Artist */
  if (track)
    iTunesGetTrackStringProperty(track, kiTunesArtistKey, &value);
  if (value) {
    [ibArtist setStringValue:(id)value];
    CFRelease(value);
    value = NULL;
  } else {
    [ibArtist setStringValue:@""];
  }
  
  /* Time and rate */
  SInt32 duration = 0, rate = 0;
  if (track) {
    iTunesGetTrackIntegerProperty(track, kiTunesDurationKey, &duration);
    iTunesGetTrackIntegerProperty(track, kiTunesRateKey, &rate);
  }
  [self setDuration:duration rate:rate];
}

- (void)setOrigin:(NSPoint)origin {
  [[self window] setFrameOrigin:origin];
}

- (NSColor *)textColor {
  return [ibName textColor];
}

- (void)setTextColor:(NSColor *)aColor {
  [ibName setTextColor:aColor];
  [ibAlbum setTextColor:aColor];
  [ibArtist setTextColor:aColor];
  
  [ibTime setTextColor:aColor];
  [ibRate setTextColor:aColor];
}

- (NSColor *)borderColor {
  return [(id)[[self window] contentView] borderColor];
}
- (void)setBorderColor:(NSColor *)aColor {
  [(id)[[self window] contentView] setBorderColor:aColor];
}

- (NSColor *)backgroundColor {
  return [(id)[[self window] contentView] backgroundColor];
}
- (void)setBackgroundColor:(NSColor *)aColor {
  [(id)[[self window] contentView] setBackgroundColor:aColor];
}

- (NSColor *)backgroundTopColor {
  return [(id)[[self window] contentView] backgroundTopColor];
}
- (void)setBackgroundTopColor:(NSColor *)aColor {
  [(id)[[self window] contentView] setBackgroundTopColor:aColor];
}

- (NSColor *)backgroundBottomColor {
  return [(id)[[self window] contentView] backgroundBottomColor];
}
- (void)setBackgroundBottomColor:(NSColor *)aColor {
  [(id)[[self window] contentView] setBackgroundBottomColor:aColor];
}
@end

@implementation ITunesInfoView

- (id)initWithFrame:(NSRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setVisual:&kiTunesDefaultSettings];
  }
  return self;
}

- (void)dealloc {
  if (shading)
    CGShadingRelease(shading);
  [super dealloc];
}

- (void)clearShading {
  if (shading) {
    CGShadingRelease(shading);
    shading = NULL;
  }
  [self setNeedsDisplay:YES];
}

static
void iTunesShadingFunction(void *pinfo, const float *in, float *out) {
  float v;
  SKSimpleShadingInfo *ctxt = pinfo;

  v = *in;
  for (int k = 0; k < 4; k++) {
    *out++ = ctxt->start[k] - (ctxt->start[k] - ctxt->end[k]) * pow(sin(M_PI_2 * v), 2);
  }
}

- (void)drawRect:(NSRect)aRect {
  CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
  
  CGRect rect = CGRectFromNSRect([self bounds]);
  
  CGRect internal = rect;
  internal.origin.x += 2;
  internal.origin.y += 2;
  internal.size.width -= 4;
  internal.size.height -= 4;
  SKCGContextAddRoundRect(ctxt, internal, 6);
  
  CGContextSaveGState(ctxt);
  CGContextClip(ctxt);
  if (!shading)
    shading = SKCGCreateShading(CGPointMake(0, NSHeight([self bounds])), CGPointZero, iTunesShadingFunction, &info);
  CGContextDrawShading(ctxt, shading);
  CGContextRestoreGState(ctxt);
  
  /* Border */
  SKCGContextAddRoundRect(ctxt, rect, 8);
  rect.origin.x += 3;
  rect.origin.y += 3;
  rect.size.width -= 6;
  rect.size.height -= 6;
  SKCGContextAddRoundRect(ctxt, rect, 5);
  CGContextSetRGBFillColor(ctxt, border[0], border[1], border[2], border[3]);
  CGContextDrawPath(ctxt, kCGPathEOFill);
}

#pragma mark -
- (void)getVisual:(ITunesVisual *)visual {
  memcpy(visual->border, border, sizeof(visual->border));
  memcpy(visual->backbot, info.end, sizeof(visual->backbot));
  memcpy(visual->backtop, info.start, sizeof(visual->backtop));
}

- (void)setVisual:(const ITunesVisual *)visual {
  memcpy(border, visual->border, sizeof(visual->border));
  memcpy(info.end, visual->backbot, sizeof(visual->backbot));
  memcpy(info.start, visual->backtop, sizeof(visual->backtop));
  [self clearShading];
}

- (NSColor *)borderColor {
  return [NSColor colorWithCalibratedRed:border[0] green:border[1] blue:border[2] alpha:border[3]];
}

- (void)setBorderColor:(NSColor *)aColor {
  [[aColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getComponents:border];
  [self setNeedsDisplay:YES];
}
- (NSColor *)backgroundColor {
  return [NSColor colorWithCalibratedRed:info.end[0] green:info.end[1] blue:info.end[2] alpha:info.end[3]];
}
- (void)setBackgroundColor:(NSColor *)aColor {
  [[aColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getComponents:info.end];
  info.start[0] = 0.75 + info.end[0] * 0.25;
  info.start[1] = 0.75 + info.end[1] * 0.25;
  info.start[2] = 0.75 + info.end[2] * 0.25;
  info.start[3] = 0.75 + info.end[3] * 0.25;
  [self clearShading];
}

- (NSColor *)backgroundTopColor {
  return [NSColor colorWithCalibratedRed:info.start[0] green:info.start[1] blue:info.start[2] alpha:info.start[3]];
}
- (void)setBackgroundTopColor:(NSColor *)aColor {
  [[aColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getComponents:info.start];
  [self clearShading];
}

- (NSColor *)backgroundBottomColor {
  return [NSColor colorWithCalibratedRed:info.end[0] green:info.end[1] blue:info.end[2] alpha:info.end[3]];
}
- (void)setBackgroundBottomColor:(NSColor *)aColor {
  [[aColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getComponents:info.end];
  [self clearShading];
}

@end

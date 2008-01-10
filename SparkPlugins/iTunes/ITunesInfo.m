/*
 *  ITunesInfo.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "ITunesInfo.h"
#import "ITunesAction.h"
#import "ITunesStarView.h"
#import "ITunesProgressView.h"

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKCGFunctions.h>
#import <ShadowKit/SKNotificationWindow.h>

#define kiTunesVisualDefaultPosition	{ -1e8, 0 }

const NSPoint kiTunesUpperLeft = kiTunesVisualDefaultPosition;
const NSPoint kiTunesUpperRight = { -2e8, 0 };
const NSPoint kiTunesBottomLeft = { -3e8, 0 };
const NSPoint kiTunesBottomRight = { -4e8, 0 };

const ITunesVisual kiTunesDefaultSettings = {
  YES, kiTunesVisualDefaultPosition, 1.5,
  { 1, 1, 1, 1 },
  { 0, 0, 0, 0 },
  { 6/255., 12/255., 18/255., .65 },
  { 9/255., 18/255., 27/255., .85 },
};

enum {
  kiTunesVisualUL,
  kiTunesVisualUR,
  kiTunesVisualBL,
  kiTunesVisualBR,
  kiTunesVisualOther,
};

SK_INLINE
int __iTunesGetTypeForLocation(NSPoint point) {
  if (SKRealEquals(point.x, kiTunesUpperLeft.x))
    return kiTunesVisualUL;
  if (SKRealEquals(point.x, kiTunesUpperRight.x))
    return kiTunesVisualUR;
  if (SKRealEquals(point.x, kiTunesBottomLeft.x))
    return kiTunesVisualBL;
  if (SKRealEquals(point.x, kiTunesBottomRight.x))
    return kiTunesVisualBR;
  
  return kiTunesVisualOther;
}
SK_INLINE
NSPoint __iTunesGetLocationForType(int type) {
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

SK_INLINE
BOOL __FloatEquals(CGFloat a, CGFloat b) { double __delta = a - b; return (__delta < 1e-5 && __delta > -1e-5); }
SK_INLINE
BOOL __CGFloatEquals(CGFloat a, CGFloat b) { CGFloat __delta = a - b; return (__delta < 1e-5 && __delta > -1e-5); }

SK_INLINE 
void __CopyCGColor(const CGFloat cgcolor[], CGFloat color[]) {
  for (NSUInteger idx = 0; idx < 4; idx++) {
    color[idx] = (CGFloat)cgcolor[idx];
  }
}
SK_INLINE 
void __CopyColor(const CGFloat color[], CGFloat cgcolor[]) {
  for (NSUInteger idx = 0; idx < 4; idx++) {
    cgcolor[idx] = color[idx];
  }
}

SK_INLINE
BOOL __ITunesVisualCompareColors(const CGFloat c1[4], const CGFloat c2[4]) {
  for (int idx = 0; idx < 4; idx++)
    if (!__FloatEquals(c1[idx], c2[idx])) return NO;
  return YES;
}

BOOL ITunesVisualIsEqualTo(const ITunesVisual *v1, const ITunesVisual *v2) {
  if (v1->shadow != v2->shadow) return NO;
  if (!__CGFloatEquals(v1->delay, v2->delay)) return NO;
  if (!__CGFloatEquals(v1->location.x, v2->location.x) || !__CGFloatEquals(v1->location.y, v2->location.y)) return NO;
  
  if (!__ITunesVisualCompareColors(v1->text, v2->text)) return NO;
  if (!__ITunesVisualCompareColors(v1->border, v2->border)) return NO;
  if (!__ITunesVisualCompareColors(v1->backtop, v2->backtop)) return NO;
  if (!__ITunesVisualCompareColors(v1->backbot, v2->backbot)) return NO;
  
  return YES;
}

/* disable multi shading */
#define MULTI_SHADING 0

@interface ITunesInfoView : NSView {
  @private
  CGFloat _border[4];
  CGLayerRef _shading;
#if MULTI_SHADING
  SKCGMultiShadingInfo *_info;
#else
  SKCGSimpleShadingInfo _info;
#endif
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
SK_INLINE
void __iTunesGetColorComponents(NSColor *color, CGFloat rgba[]) {
  color = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
  [color getRed:&rgba[0] green:&rgba[1] blue:&rgba[2] alpha:&rgba[3]];
}

- (void)getVisual:(ITunesVisual *)visual {
  bzero(visual, sizeof(*visual));
  /* Get delay */
  visual->delay = [self delay];
  /* Get location */
  if (ia_loc != kiTunesVisualOther) visual->location = __iTunesGetLocationForType(ia_loc);
  else visual->location = [[self window] frame].origin;
  /* Get shadow */
  visual->shadow = [[self window] hasShadow];
  /* Get text color */
  CGFloat rgba[4];
  __iTunesGetColorComponents([self textColor], rgba);
  __CopyCGColor(rgba, visual->text);
  [(id)[[self window] contentView] getVisual:visual];
}

- (void)setVisual:(const ITunesVisual *)visual {
  [self setDelay:visual->delay];
  [self setPosition:visual->location];
  [self setHasShadow:visual->shadow];
  [self setTextColor:[NSColor colorWithCalibratedRed:visual->text[0] green:visual->text[1] blue:visual->text[2] alpha:visual->text[3]]];
  [[[self window] contentView] setVisual:visual];
}

- (NSTimeInterval)delay {
  return [(id)[self window] delay];
}
- (void)setDelay:(NSTimeInterval)aDelay {
  [(id)[self window] setDelay:aDelay];
}

#define SCREEN_MARGIN 17
- (void)setPosition:(NSPoint)aPoint {
  NSPoint origin = aPoint;
  NSRect bounds = [[self window] frame];
  NSRect screen = [[NSScreen mainScreen] frame];
  ia_loc = __iTunesGetTypeForLocation(aPoint);
  switch (ia_loc) {
    case kiTunesVisualUL:
      origin.x = SCREEN_MARGIN * SKScreenScaleFactor([NSScreen mainScreen]);
      origin.y = NSHeight(screen) - NSHeight(bounds) - (SCREEN_MARGIN + 22) * SKScreenScaleFactor([NSScreen mainScreen]); // menu bar
      break;
    case kiTunesVisualUR:
      origin.x = NSWidth(screen) - NSWidth(bounds) - SCREEN_MARGIN * SKScreenScaleFactor([NSScreen mainScreen]);
      origin.y = NSHeight(screen) - NSHeight(bounds) - (SCREEN_MARGIN + 22) * SKScreenScaleFactor([NSScreen mainScreen]);
      break;
    case kiTunesVisualBL:
      origin.x = SCREEN_MARGIN * SKScreenScaleFactor([NSScreen mainScreen]);
      origin.y = (SCREEN_MARGIN + 22) * SKScreenScaleFactor([NSScreen mainScreen]);
      break;
    case kiTunesVisualBR:
      origin.x = NSWidth(screen) - NSWidth(bounds) - SCREEN_MARGIN * SKScreenScaleFactor([NSScreen mainScreen]);
      origin.y = (SCREEN_MARGIN + 22) * SKScreenScaleFactor([NSScreen mainScreen]);
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
  
  [ibRate setRate:lround(rate / 10)];
}

- (void)setTrack:(iTunesTrack *)track {
  OSType cls = 0;
  CFStringRef value = NULL;
  
  if (track)
    iTunesGetObjectType(track, &cls);
  
  /* Track Name */
  if (track) {
    if ('cURT' == cls)
      iTunesCopyCurrentStreamTitle(&value); /* current stream title */
    else
      iTunesCopyTrackStringProperty(track, kiTunesNameKey, &value);
  }
  if (value) {
    [ibName setStringValue:(id)value];
    CFRelease(value);
    value = NULL;
  } else {
    [ibName setStringValue:NSLocalizedStringFromTableInBundle(@"<untiled>", nil, kiTunesActionBundle, @"Untitled track info")];
  }
  
  /* Album */
  if (track) {
    if ('cURT' == cls)
      iTunesCopyTrackStringProperty(track, kiTunesNameKey, &value); /* radio name */
    else
      iTunesCopyTrackStringProperty(track, kiTunesAlbumKey, &value);
  }
  if (value) {
    [ibAlbum setStringValue:(id)value];
    CFRelease(value);
    value = NULL;
  } else {
    [ibAlbum setStringValue:@""];
  }
  
  /* Artist */
  if (track) {
    if ('cURT' == cls)
      iTunesCopyTrackStringProperty(track, 'pCat', &value); /* category not available for radio */
    else
      iTunesCopyTrackStringProperty(track, kiTunesArtistKey, &value);
  }
  
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
    if ('cURT' == cls) {
      iTunesGetPlayerPosition((UInt32 *)&duration); /* duration not available for radio */
    } else {
      iTunesGetTrackIntegerProperty(track, kiTunesDurationKey, &duration);
      iTunesGetTrackIntegerProperty(track, kiTunesRateKey, &rate);
    }
  }
  [self setDuration:duration rate:rate];
  
  
  if ('cURT' == cls) {
    [ibProgress setProgress:0];
  } else {
    UInt32 progress = 0;
    verify_noerr(iTunesGetPlayerPosition(&progress));
    if (duration > 0)
      [ibProgress setProgress:(CGFloat)progress / duration];
    else
      [ibProgress setProgress:0];
  }
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
  [ibRate setStarsColor:aColor];
  [ibProgress setColor:aColor];
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

#pragma mark -
#pragma mark Color derivation
#if MULTI_SHADING
SK_INLINE
CMColor __CMColorCreateRGB(CGFloat r, CGFloat g, CGFloat b) {
  CMColor color = {
rgb: {r * 65535, g * 65535, b * 65535} 
  };
  return color;
}

static
void _iTunesDeriveColor(CGFloat *base, CGFloat *dest, CGFloat h, CGFloat s, CGFloat v) {
  CMColor hsv;
  CMColor rgb = __CMColorCreateRGB(base[0], base[1], base[2]);
  
  CMConvertRGBToHSV(&rgb, &hsv, 1);
  hsv.hsv.hue = MIN(hsv.hsv.hue * h, 65535);
  hsv.hsv.saturation = MIN(hsv.hsv.saturation * s, 65535);
  hsv.hsv.value = MIN(hsv.hsv.value * v, 65535);
  CMConvertHSVToRGB(&hsv, &rgb, 1);
  
  dest[0] = rgb.rgb.red / 65535.;
  dest[1] = rgb.rgb.green / 65535.;
  dest[2] = rgb.rgb.blue / 65535.;
  dest[3] = base[3];
}

SK_INLINE
void __iTunesDeriveTopColor(SKCGMultiShadingInfo *info) {
  _iTunesDeriveColor(info->steps[0].rgba2, info->steps[0].rgba, 1.035, .502, 1.104);
}
SK_INLINE
void __iTunesDeriveBottomColor(SKCGMultiShadingInfo *info) {
  _iTunesDeriveColor(info->steps[1].rgba, info->steps[1].rgba2, .925, .827, 1.225);
}
SK_INLINE
void __iTunesDeriveBothColors(SKCGMultiShadingInfo *info) {
  __iTunesDeriveTopColor(info);
  __iTunesDeriveBottomColor(info);
}
static
void _iTunesDeriveAllColors(SKCGMultiShadingInfo *info) {
  /* derive top from bottom */
  _iTunesDeriveColor(info->steps[1].rgba, info->steps[0].rgba2, 1.004, .882, 1.030);
  
  /* derive shading */
  __iTunesDeriveTopColor(info);
  __iTunesDeriveBottomColor(info);
}
#endif

@implementation ITunesInfoView

- (id)initWithFrame:(NSRect)frame {
  if (self = [super initWithFrame:frame]) {
#if MULTI_SHADING
    _info = calloc(1, sizeof(*_info) + 2 * sizeof(*_info->steps));
    _info->count = 2;
    _info->steps[0].end = .40;
    _info->steps[1].end = 1;
#else
    _info.fct = SKCGShadingSinFactorFunction;
#endif
    [self setVisual:&kiTunesDefaultSettings];
  }
  return self;
}

- (void)dealloc {
  CGLayerRelease(_shading);
  [super dealloc];
}

- (void)clearShading {
  if (_shading) {
    CGLayerRelease(_shading);
    _shading = NULL;
  }
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)aRect {
  CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
  
  CGRect rect = NSRectToCGRect([self bounds]);
  
  CGRect internal = CGRectInset(rect, 2, 2);
  SKCGContextAddRoundRect(ctxt, internal, 6);
  
  CGContextSaveGState(ctxt);
  CGContextClip(ctxt);
  if (!_shading) {
#if MULTI_SHADING
    _shading = SKCGLayerCreateWithVerticalShading(ctxt, CGSizeMake(64, NSHeight([self bounds])), true, SKCGShadingMultiShadingFunction, _info);
#else
    _shading = SKCGLayerCreateWithVerticalShading(ctxt, CGSizeMake(64, NSHeight([self bounds])), true, SKCGShadingSimpleShadingFunction, &_info);
#endif
  }
  CGContextDrawLayerInRect(ctxt, NSRectToCGRect([self bounds]), _shading);
  CGContextRestoreGState(ctxt);
  
  /* Border */
  if (_border[3] > 0) {
    SKCGContextAddRoundRect(ctxt, rect, 8);
    rect = CGRectInset(rect, 3, 3);
    SKCGContextAddRoundRect(ctxt, rect, 5);
    CGContextSetRGBFillColor(ctxt, _border[0], _border[1], _border[2], _border[3]);
    CGContextDrawPath(ctxt, kCGPathEOFill);
  }
}

#pragma mark -
- (void)getVisual:(ITunesVisual *)visual {
  __CopyCGColor(_border, visual->border);
#if MULTI_SHADING
  memcpy(visual->backbot, _info->steps[1].rgba, sizeof(visual->backbot));
  memcpy(visual->backtop, _info->steps[0].rgba2, sizeof(visual->backtop));
#else
  memcpy(visual->backbot, _info.end, sizeof(visual->backbot));
  memcpy(visual->backtop, _info.start, sizeof(visual->backtop));
#endif
}

- (void)setVisual:(const ITunesVisual *)visual {
  __CopyColor(visual->border, _border);  
#if MULTI_SHADING
  memcpy(_info->steps[1].rgba, visual->backbot, sizeof(visual->backbot));
  memcpy(_info->steps[0].rgba2, visual->backtop, sizeof(visual->backtop));
  /* derive colors */
  __iTunesDeriveBothColors(_info);
#else
  memcpy(_info.end, visual->backbot, sizeof(visual->backbot));
    memcpy(_info.start, visual->backtop, sizeof(visual->backtop));
#endif
  [self clearShading];
}

- (NSColor *)borderColor {
  return [NSColor colorWithCalibratedRed:_border[0] green:_border[1] blue:_border[2] alpha:_border[3]];
}

- (void)setBorderColor:(NSColor *)aColor {
  __iTunesGetColorComponents(aColor, _border);
  [self setNeedsDisplay:YES];
}
- (NSColor *)backgroundColor {
#if MULTI_SHADING
  return [NSColor colorWithCalibratedRed:_info->steps[1].rgba[0] green:_info->steps[1].rgba[1] 
                                    blue:_info->steps[1].rgba[2] alpha:_info->steps[1].rgba[3]];
#else
  return [NSColor colorWithCalibratedRed:_info.end[0] green:_info.end[1] blue:_info.end[2] alpha:_info.end[3]];
#endif
}
- (void)setBackgroundColor:(NSColor *)aColor {
#if MULTI_SHADING
  __iTunesGetColorComponents(aColor, _info->steps[1].rgba);
  /* Derive all colors */
  _iTunesDeriveAllColors(_info);
#else
  __iTunesGetColorComponents(aColor, _info.end);
  _info.start[0] = 0.75 + _info.end[0] * 0.25;
  _info.start[1] = 0.75 + _info.end[1] * 0.25;
  _info.start[2] = 0.75 + _info.end[2] * 0.25;
  _info.start[3] = 0.75 + _info.end[3] * 0.25;
#endif
  [self clearShading];
}

- (NSColor *)backgroundTopColor {
#if MULTI_SHADING
  return [NSColor colorWithCalibratedRed:_info->steps[0].rgba2[0] green:_info->steps[0].rgba2[1] 
                                    blue:_info->steps[0].rgba2[2] alpha:_info->steps[0].rgba2[3]];
#else
  return [NSColor colorWithCalibratedRed:_info.start[0] green:_info.start[1] blue:_info.start[2] alpha:_info.start[3]];
#endif
}
- (void)setBackgroundTopColor:(NSColor *)aColor {
#if MULTI_SHADING
  __iTunesGetColorComponents(aColor, _info->steps[0].rgba2);
  /* derive top color */
  __iTunesDeriveTopColor(_info);
#else
  __iTunesGetColorComponents(aColor, _info.start);
#endif
  [self clearShading];
}

- (NSColor *)backgroundBottomColor {
#if MULTI_SHADING
  return [NSColor colorWithCalibratedRed:_info->steps[1].rgba[0] green:_info->steps[1].rgba[1] 
                                    blue:_info->steps[1].rgba[2] alpha:_info->steps[1].rgba[3]];
#else
  return [NSColor colorWithCalibratedRed:_info.end[0] green:_info.end[1] blue:_info.end[2] alpha:_info.end[3]];
#endif
}
- (void)setBackgroundBottomColor:(NSColor *)aColor {
#if MULTI_SHADING
  __iTunesGetColorComponents(aColor, _info->steps[1].rgba);
  /* derive bottom color */
  __iTunesDeriveBottomColor(_info);
#else
  __iTunesGetColorComponents(aColor, _info.end);
#endif
  [self clearShading];
}

@end

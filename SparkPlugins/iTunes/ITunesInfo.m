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

#import <WonderBox/WBGradient.h>
#import <WonderBox/WBCGFunctions.h>
#import <WonderBox/WBNotificationWindow.h>

#define kiTunesVisualDefaultPosition	{ -1e8, 0 }

const NSPoint kiTunesUpperLeft = kiTunesVisualDefaultPosition;
const NSPoint kiTunesUpperRight = { -2e8, 0 };
const NSPoint kiTunesBottomLeft = { -3e8, 0 };
const NSPoint kiTunesBottomRight = { -4e8, 0 };

const ITunesVisual kiTunesDefaultSettings = {
  NO, YES, kiTunesVisualDefaultPosition, 1.5,
  { 1, 1, 1, 1 },
  { 0, 0, 0, 0 },
  { 6/255., 12/255., 12/255., .65 },
  { 9/255., 18/255., 18/255., .85 },
};

enum {
  kiTunesVisualUL,
  kiTunesVisualUR,
  kiTunesVisualBL,
  kiTunesVisualBR,
  kiTunesVisualOther,
};

WB_INLINE
int __iTunesGetTypeForLocation(NSPoint point) {
  if (fequal(point.x, kiTunesUpperLeft.x))
    return kiTunesVisualUL;
  if (fequal(point.x, kiTunesUpperRight.x))
    return kiTunesVisualUR;
  if (fequal(point.x, kiTunesBottomLeft.x))
    return kiTunesVisualBL;
  if (fequal(point.x, kiTunesBottomRight.x))
    return kiTunesVisualBR;
  
  return kiTunesVisualOther;
}

NSData *ITunesVisualPack(ITunesVisual *visual) {
  NSMutableData *data = [[NSMutableData alloc] initWithCapacity:sizeof(ITunesPackedVisual)];
  [data setLength:sizeof(ITunesPackedVisual)];
  ITunesPackedVisual *pack = [data mutableBytes];
  pack->version = 1;
  if (visual->shadow)	pack->flags |= kiTunesVisualFlagsShadow;
  if (visual->artwork)	pack->flags |= kiTunesVisualFlagsArtwork;
  pack->delay = CFConvertFloat64HostToSwapped(visual->delay);
  pack->x = CFConvertFloat32HostToSwapped((float)visual->location.x);
  pack->y = CFConvertFloat32HostToSwapped((float)visual->location.y);
  pack->colors[0] = OSSwapHostToBigInt64(ITunesVisualPackColor(visual->text));
  pack->colors[1] = OSSwapHostToBigInt64(ITunesVisualPackColor(visual->border));
  pack->colors[2] = OSSwapHostToBigInt64(ITunesVisualPackColor(visual->backtop));
  pack->colors[3] = OSSwapHostToBigInt64(ITunesVisualPackColor(visual->backbot));
  return data;
}

BOOL ITunesVisualUnpack(NSData *data, ITunesVisual *visual) {
  NSCParameterAssert(visual != NULL);
  memset(visual, 0, sizeof(*visual));
  if (!data) return NO;

  if ([data length] == sizeof(ITunesPackedVisual_v0)) {
    const ITunesPackedVisual_v0 *pack = [data bytes];
    visual->artwork = 0;
    visual->shadow = pack->shadow != 0;
    visual->delay = CFConvertFloat64SwappedToHost(pack->delay);
    visual->location.x = CFConvertFloat32SwappedToHost(pack->x);
    visual->location.y = CFConvertFloat32SwappedToHost(pack->y);
    ITunesVisualUnpackColor(OSSwapBigToHostInt64(pack->colors[0]), visual->text);
    ITunesVisualUnpackColor(OSSwapBigToHostInt64(pack->colors[1]), visual->border);
    ITunesVisualUnpackColor(OSSwapBigToHostInt64(pack->colors[2]), visual->backtop);
    ITunesVisualUnpackColor(OSSwapBigToHostInt64(pack->colors[3]), visual->backbot);
  } else if ([data length] >= sizeof(ITunesPackedVisual)) {
    const ITunesPackedVisual *pack = [data bytes];
    if (pack->version != 1) return NO;
    visual->shadow = (pack->flags & kiTunesVisualFlagsShadow) != 0;
    visual->artwork = (pack->flags & kiTunesVisualFlagsArtwork) != 0;
    visual->delay = CFConvertFloat64SwappedToHost(pack->delay);
    visual->location.x = CFConvertFloat32SwappedToHost(pack->x);
    visual->location.y = CFConvertFloat32SwappedToHost(pack->y);
    ITunesVisualUnpackColor(OSSwapBigToHostInt64(pack->colors[0]), visual->text);
    ITunesVisualUnpackColor(OSSwapBigToHostInt64(pack->colors[1]), visual->border);
    ITunesVisualUnpackColor(OSSwapBigToHostInt64(pack->colors[2]), visual->backtop);
    ITunesVisualUnpackColor(OSSwapBigToHostInt64(pack->colors[3]), visual->backbot);
  } else {
    return NO;
  }
  
  return YES;
}

WB_INLINE
BOOL __FloatEquals(CGFloat a, CGFloat b) { double __delta = a - b; return (__delta < 1e-5 && __delta > -1e-5); }
WB_INLINE
BOOL __CGFloatEquals(CGFloat a, CGFloat b) { CGFloat __delta = a - b; return (__delta < 1e-5 && __delta > -1e-5); }

WB_INLINE 
void __CopyCGColor(const CGFloat cgcolor[], CGFloat color[]) {
  for (NSUInteger idx = 0; idx < 4; idx++) {
    color[idx] = (CGFloat)cgcolor[idx];
  }
}
WB_INLINE 
void __CopyColor(const CGFloat color[], CGFloat cgcolor[]) {
  for (NSUInteger idx = 0; idx < 4; idx++) {
    cgcolor[idx] = color[idx];
  }
}

WB_INLINE
BOOL __ITunesVisualCompareColors(const CGFloat c1[4], const CGFloat c2[4]) {
  for (int idx = 0; idx < 4; idx++)
    if (!__FloatEquals(c1[idx], c2[idx])) return NO;
  return YES;
}

BOOL ITunesVisualIsEqualTo(const ITunesVisual *v1, const ITunesVisual *v2) {
  if (v1->shadow != v2->shadow) return NO;
	if (v1->artwork != v2->artwork) return NO;
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
  WBGradientDefinition *_info;
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

@interface ITunesInfo ()

@property(nonatomic, assign) IBOutlet NSView *ibView;

@property(nonatomic, assign) IBOutlet NSTextField *ibName;
@property(nonatomic, assign) IBOutlet NSTextField *ibAlbum;
@property(nonatomic, assign) IBOutlet NSTextField *ibArtist;

@property(nonatomic, assign) IBOutlet NSTextField *ibTime;

// We may detach it from the parent view, so use strong ref.
@property(nonatomic, strong) IBOutlet NSImageView *ibArtwork;

@property(nonatomic, assign) IBOutlet ITunesStarView *ibRate;
@property(nonatomic, assign) IBOutlet ITunesProgressView *ibProgress;

@end

@implementation ITunesInfo {
@private
  CGFloat ia_artWidth;
  NSPoint ia_artOrigin;
}

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
  NSWindow *info = [[WBNotificationWindow alloc] init];
  [info setHasShadow:YES];
  if (self = [super initWithWindow:info]) {
    [kiTunesActionBundle loadNibNamed:@"iTunesInfo" owner:self topLevelObjects:NULL];
		NSAssert(_ibArtwork, @"nib not loaded ?");
    [self setVisual:&kiTunesDefaultSettings];
		[info setDelegate:self];
  }
  return self;
}

- (void)dealloc {
  [[self window] close];
}

- (NSView *)ibView { return self.window.contentView; }

- (void)setIbView:(NSView *)aView {
  /* Nib root object should be release */
  self.window.contentSize = aView.bounds.size;
  self.window.contentView = aView;
}

#pragma mark -
WB_INLINE
void __iTunesGetColorComponents(NSColor *color, CGFloat rgba[]) {
  color = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
  [color getRed:&rgba[0] green:&rgba[1] blue:&rgba[2] alpha:&rgba[3]];
}

- (void)getVisual:(ITunesVisual *)visual {
  memset(visual, 0, sizeof(*visual));
  /* Get delay */
  visual->delay = [self delay];
  /* Get location */
	NSUInteger type = __iTunesGetTypeForLocation(_position);
  if (type != kiTunesVisualOther)
    visual->location = _position;
  else
    visual->location = [[self window] frame].origin;
  /* Get shadow */
  visual->shadow = [self hasShadow];
	visual->artwork = [self displayArtwork];
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
	[self setDisplayArtwork:visual->artwork];
  [self setTextColor:[NSColor colorWithCalibratedRed:visual->text[0] green:visual->text[1] blue:visual->text[2] alpha:visual->text[3]]];
  [[[self window] contentView] setVisual:visual];
}

- (NSTimeInterval)delay {
  return [(id)[self window] delay];
}
- (void)setDelay:(NSTimeInterval)aDelay {
  [(id)[self window] setDelay:aDelay];
}

- (void)setDisplayArtwork:(BOOL)flag {
	_displayArtwork = flag;
	if (SparkGetCurrentContext() == kSparkContext_Editor)
		[self setArtworkVisible:_displayArtwork];
}

#define SCREEN_MARGIN 17
- (NSPoint)windowOriginForSize:(NSSize)size {
	NSPoint origin = _position;
  //NSRect bounds = [[self window] frame];
  NSRect screen = [[[self window] screen] ? : [NSScreen mainScreen] frame];
  NSUInteger type = __iTunesGetTypeForLocation(_position);
  switch (type) {
    case kiTunesVisualUL:
      origin.x = SCREEN_MARGIN;
      origin.y = NSHeight(screen) - size.height - (SCREEN_MARGIN + 22); // menu bar
      break;
    case kiTunesVisualUR:
      origin.x = NSWidth(screen) - size.width - SCREEN_MARGIN;
      origin.y = NSHeight(screen) - size.height - (SCREEN_MARGIN + 22);
      break;
    case kiTunesVisualBL:
      origin.x = SCREEN_MARGIN ;
      origin.y = (SCREEN_MARGIN + 22);
      break;
    case kiTunesVisualBR:
      origin.x = NSWidth(screen) - size.width - SCREEN_MARGIN;
      origin.y = (SCREEN_MARGIN + 22);
      break;
  }
	return origin;
}

- (void)setPosition:(NSPoint)aPoint {
  _position = aPoint;
	NSRect frame = [[self window] frame];
	frame.origin = [self windowOriginForSize:frame.size];
	[[self window] setFrameOrigin:frame.origin];
}

- (BOOL)hasShadow {
	return [[self window] hasShadow];
}
- (void)setHasShadow:(BOOL)hasShadow {
  [[self window] setHasShadow:hasShadow];
}

- (IBAction)display:(id)sender {
  [(id)[self window] display:sender];
}

- (void)setDuration:(SInt32)aTime rate:(SInt32)rate {
  NSString *str = nil;
  int32_t days = aTime / (3600 * 24);
  int32_t hours = (aTime % (3600 * 24)) / 3600;
  int32_t minutes = (aTime % 3600) / 60;
  int32_t seconds = aTime % 60;
  
  if (days > 0) {
    str = [NSString stringWithFormat:@"%i:%.2i:%.2i:%.2i - ", days, hours, minutes, seconds];
  } else if (hours > 0) {
    str = [NSString stringWithFormat:@"%i:%.2i:%.2i -", hours, minutes, seconds];
  } else if (minutes > 0 || seconds > 0) {
    str = [NSString stringWithFormat:@"%i:%.2i -", minutes, seconds];
  } else {
    str = @" -";
  }
  [_ibTime setStringValue:str];
  /* adjust time size and move rate */
  [_ibTime sizeToFit];
  NSPoint origin = [_ibRate frame].origin;
  origin.x = NSMaxX([_ibTime frame]);
  [_ibRate setFrameOrigin:origin];
  
  [_ibRate setRate:lround(rate / 10)];
}

- (void)setTrack:(iTunesTrack *)track visual:(const ITunesVisual *)visual {
  OSType cls = 0;
  CFStringRef value = NULL;
  
	/* should be call first */
	[self setVisual:visual];
	
  if (track)
    iTunesGetObjectType(track, &cls);
  
  /* Track Name */
  if (track) {
    if ('cURT' == cls)
      value = iTunesCopyCurrentStreamTitle(NULL); /* current stream title */
    else
      value = iTunesCopyTrackStringProperty(track, kiTunesNameKey, NULL);
  }
  if (value) {
    [_ibName setStringValue:SPXCFStringBridgingRelease(value)];
    value = NULL;
  } else {
    [_ibName setStringValue:NSLocalizedStringFromTableInBundle(@"<untiled>", nil, kiTunesActionBundle, @"Untitled track info")];
  }
  
  /* Album */
  if (track) {
    if ('cURT' == cls)
      value = iTunesCopyTrackStringProperty(track, kiTunesNameKey, NULL); /* radio name */
    else
      value = iTunesCopyTrackStringProperty(track, kiTunesAlbumKey, NULL);
  }
  if (value) {
    [_ibAlbum setStringValue:SPXCFStringBridgingRelease(value)];
    value = NULL;
  } else {
    [_ibAlbum setStringValue:@""];
  }
  
  /* Artist */
  if (track) {
    if ('cURT' == cls)
      value = iTunesCopyTrackStringProperty(track, kiTunesCategoryKey, NULL); /* category not available for radio */
    else
      value = iTunesCopyTrackStringProperty(track, kiTunesArtistKey, NULL);
  }
  
  if (value) {
    [_ibArtist setStringValue:SPXCFStringBridgingRelease(value)];
    value = NULL;
  } else {
    [_ibArtist setStringValue:@""];
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
    [_ibProgress setProgress:0];
  } else {
    UInt32 progress = 0;
    spx_verify_noerr(iTunesGetPlayerPosition(&progress));
    if (duration > 0)
      [_ibProgress setProgress:(CGFloat)progress / duration];
    else
      [_ibProgress setProgress:0];
  }
	
	/* Image */
	BOOL display = NO;
	[_ibArtwork setImage:nil];
	if (track && _displayArtwork) {
    OSType type;
		CFDataRef data = NULL;
		if ((data = iTunesCopyTrackArtworkData(track, &type, NULL))) {
			NSImage *image = [[NSImage alloc] initWithData:SPXCFDataBridgingRelease(data)];
			if (image) {
				// display image zone
				[self setArtworkVisible:YES];
				[_ibArtwork setImage:image];
				display = YES;
			}
		}
	}
	[self setArtworkVisible:display];
}

- (void)setArtworkVisible:(BOOL)flag {
	// artwork
	if ([_ibArtwork superview] && !flag) {
		if (ia_artWidth <= 0)	{
			ia_artWidth = NSMaxX([_ibArtwork frame]);
			ia_artOrigin = [_ibArtwork frame].origin;
		}
		/* adjust window frame */
		[_ibArtwork removeFromSuperview];
		
		NSRect frame = [[self window] frame];
		frame.size.width -= ia_artWidth;
		
		frame.origin = [self windowOriginForSize:frame.size];
		if (SparkGetCurrentContext() == kSparkContext_Editor) {
			[[self window] setFrame:frame display:YES animate:YES];
		} else {
			[[self window] setFrame:frame display:YES animate:NO];
		}
	} else if (![_ibArtwork superview] && flag) {
		NSAssert(ia_artWidth > 0, @"Internal inconsistency");
		/* adjust window frame */
		NSRect frame = [[self window] frame];
		frame.size.width += ia_artWidth;
		frame.origin = [self windowOriginForSize:frame.size];
		if (SparkGetCurrentContext() == kSparkContext_Editor) {
			[[self window] setFrame:frame display:YES animate:YES];
		} else {
			[[self window] setFrame:frame display:YES animate:NO];
		}
		
		[[[self window] contentView] addSubview:_ibArtwork];
		[_ibArtwork setFrameOrigin:ia_artOrigin];
	}
}

- (void)windowWillClose:(NSNotification *)notification {
	/* release image when no longer needed */
	if (SparkGetCurrentContext() == kSparkContext_Daemon)
		[_ibArtwork setImage:nil];
}

- (NSColor *)textColor {
  return [_ibName textColor];
}

- (void)setTextColor:(NSColor *)aColor {
  [_ibName setTextColor:aColor];
  [_ibAlbum setTextColor:aColor];
  [_ibArtist setTextColor:aColor];
  
  [_ibTime setTextColor:aColor];
  [_ibRate setStarsColor:aColor];
  [_ibProgress setColor:aColor];
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
WB_INLINE
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

WB_INLINE
void __iTunesDeriveTopColor(WBCGMultiShadingInfo *info) {
  _iTunesDeriveColor(info->stops[0].rgba2, info->stops[0].rgba, 1.035, .502, 1.104);
}
WB_INLINE
void __iTunesDeriveBottomColor(WBCGMultiShadingInfo *info) {
  _iTunesDeriveColor(info->stops[1].rgba, info->stops[1].rgba2, .925, .827, 1.225);
}
WB_INLINE
void __iTunesDeriveBothColors(WBCGMultiShadingInfo *info) {
  __iTunesDeriveTopColor(info);
  __iTunesDeriveBottomColor(info);
}
static
void _iTunesDeriveAllColors(WBCGMultiShadingInfo *info) {
  /* derive top from bottom */
  _iTunesDeriveColor(info->stops[1].rgba, info->stops[0].rgba2, 1.004, .882, 1.030);
  
  /* derive shading */
  __iTunesDeriveTopColor(info);
  __iTunesDeriveBottomColor(info);
}
#endif

@implementation ITunesInfoView

- (id)initWithFrame:(NSRect)frame {
  if (self = [super initWithFrame:frame]) {
#if MULTI_SHADING
    NSUInteger stops = 2;
#else
    NSUInteger stops = 1;
#endif
    _info = calloc(1, sizeof(*_info) + stops * sizeof(*_info->stops));

    _info->cs = kWBGradientColorSpace_RGB;
#if MULTI_SHADING
    _info->stops[0].location = .40;
    _info->stops[0].fct.type = kWBInterpolationTypeDefault;
    _info->stops[1].location = 1;
    _info->stops[1].fct.type = kWBInterpolationTypeDefault;
#else
    _info->stops[0].location = 1;
    _info->stops[0].fct.type = kWBInterpolationTypeDefault;
#endif
    WBInterpolationDefinition fct = WBInterpolationCallBackDef(WBInterpolationSin);
    _info->fct = fct;
    [self setVisual:&kiTunesDefaultSettings];
  }
  return self;
}

- (void)dealloc {
  CGLayerRelease(_shading);
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
  WBCGContextAddRoundRect(ctxt, internal, 6);
  
  CGContextSaveGState(ctxt);
  CGContextClip(ctxt);
  if (!_shading) {
    WBGradientBuilder *builder = [[WBGradientBuilder alloc] initWithDefinition:_info];
    _shading = [builder newLayerWithVerticalGradient:CGRectGetHeight(rect) context:ctxt];
  }
  CGContextDrawLayerInRect(ctxt, rect, _shading);
  CGContextRestoreGState(ctxt);
  
  /* Border */
  if (_border[3] > 0) {
    WBCGContextAddRoundRect(ctxt, rect, 8);
    rect = CGRectInset(rect, 3, 3);
    WBCGContextAddRoundRect(ctxt, rect, 5);
    CGContextSetRGBFillColor(ctxt, _border[0], _border[1], _border[2], _border[3]);
    CGContextDrawPath(ctxt, kCGPathEOFill);
  }
}

#pragma mark -
- (void)getVisual:(ITunesVisual *)visual {
  __CopyCGColor(_border, visual->border);
#if MULTI_SHADING
  // FIXME
  memcpy(visual->backbot, _info->stops[1].rgba, sizeof(visual->backbot));
  memcpy(visual->backtop, _info->stops[0].rgba2, sizeof(visual->backtop));
#else
  memcpy(visual->backbot, _info->stops[0].endColor, sizeof(visual->backbot));
  memcpy(visual->backtop, _info->stops[0].startColor, sizeof(visual->backtop));
#endif
}

- (void)setVisual:(const ITunesVisual *)visual {
  __CopyColor(visual->border, _border);  
#if MULTI_SHADING
  // FIXME
  memcpy(_info->stops[1].rgba, visual->backbot, sizeof(visual->backbot));
  memcpy(_info->stops[0].rgba2, visual->backtop, sizeof(visual->backtop));
  /* derive colors */
  __iTunesDeriveBothColors(_info);
#else
  memcpy(_info->stops[0].endColor, visual->backbot, sizeof(visual->backbot));
  memcpy(_info->stops[0].startColor, visual->backtop, sizeof(visual->backtop));
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
  return [NSColor colorWithCalibratedRed:_info->stops[1].rgba[0] green:_info->stops[1].rgba[1]
                                    blue:_info->stops[1].rgba[2] alpha:_info->stops[1].rgba[3]];
#else
  return [NSColor colorWithCalibratedRed:_info->stops[0].endColor[0] green:_info->stops[0].endColor[1]
                                    blue:_info->stops[0].endColor[2] alpha:_info->stops[0].endColor[3]];
#endif
}
- (void)setBackgroundColor:(NSColor *)aColor {
#if MULTI_SHADING
  __iTunesGetColorComponents(aColor, _info->stops[1].rgba);
  /* Derive all colors */
  _iTunesDeriveAllColors(_info);
#else
  __iTunesGetColorComponents(aColor, _info->stops[0].endColor);
  _info->stops[0].startColor[0] = 0.75 + _info->stops[0].endColor[0] * 0.25;
  _info->stops[0].startColor[1] = 0.75 + _info->stops[0].endColor[1] * 0.25;
  _info->stops[0].startColor[2] = 0.75 + _info->stops[0].endColor[2] * 0.25;
  _info->stops[0].startColor[3] = 0.75 + _info->stops[0].endColor[3] * 0.25;
#endif
  [self clearShading];
}

- (NSColor *)backgroundTopColor {
#if MULTI_SHADING
  return [NSColor colorWithCalibratedRed:_info->stops[0].rgba2[0] green:_info->stops[0].rgba2[1]
                                    blue:_info->stops[0].rgba2[2] alpha:_info->stops[0].rgba2[3]];
#else
  return [NSColor colorWithCalibratedRed:_info->stops[0].startColor[0] green:_info->stops[0].startColor[1]
                                    blue:_info->stops[0].startColor[2] alpha:_info->stops[0].startColor[3]];
#endif
}
- (void)setBackgroundTopColor:(NSColor *)aColor {
#if MULTI_SHADING
  __iTunesGetColorComponents(aColor, _info->stops[0].rgba2);
  /* derive top color */
  __iTunesDeriveTopColor(_info);
#else
  __iTunesGetColorComponents(aColor, _info->stops[0].startColor);
#endif
  [self clearShading];
}

- (NSColor *)backgroundBottomColor {
#if MULTI_SHADING
  return [NSColor colorWithCalibratedRed:_info->stops[1].rgba[0] green:_info->stops[1].rgba[1]
                                    blue:_info->stops[1].rgba[2] alpha:_info->stops[1].rgba[3]];
#else
  return [NSColor colorWithCalibratedRed:_info->stops[0].endColor[0] green:_info->stops[0].endColor[1]
                                    blue:_info->stops[0].endColor[2] alpha:_info->stops[0].endColor[3]];
#endif
}
- (void)setBackgroundBottomColor:(NSColor *)aColor {
#if MULTI_SHADING
  __iTunesGetColorComponents(aColor, _info->stops[1].rgba);
  /* derive bottom color */
  __iTunesDeriveBottomColor(_info);
#else
  __iTunesGetColorComponents(aColor, _info->stops[0].endColor);
#endif
  [self clearShading];
}

@end

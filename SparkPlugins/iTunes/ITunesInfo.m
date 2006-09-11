/*
 *  ITunesInfo.m
 *  Spark Plugins
 *
 *  Created by Grayfox on 10/09/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "ITunesInfo.h"

#import <ShadowKit/SKCGFunctions.h>
#import <ShadowKit/SKNotificationWindow.h>

@implementation ITunesInfo

+ (void)initialize {
  [NSColor setIgnoresAlpha:NO];
}

- (id)init {
  NSWindow *info = [[SKNotificationWindow alloc] init];
  [info setHasShadow:YES];
  if (self = [super initWithWindow:info]) {
    [NSBundle loadNibNamed:@"iTunesInfo" owner:self];
  }
  [info release];
  return self;
}

- (void)dealloc {
  [super dealloc];
}

- (void)setIbView:(NSView *)aView {
  /* Nib root object should be release */
  [[self window] setContentSize:[aView bounds].size];
  [[self window] setContentView:[aView autorelease]];
}

#pragma mark -
- (void)setDelay:(float)aDelay {
  [(id)[self window] setDelay:aDelay];
}

- (void)setPosition:(NSPoint)aPoint {
  
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
  } else if (seconds > 0) {
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
  
  if (rate > 90) {
    // 5 stars
    str = NSLocalizedString(@"*****", @"5 stars rate");
  } else if (rate > 70) {
    // 4 stars
    str = NSLocalizedString(@"****", @"4 stars rate");
  } else if (rate > 50) {
    // 3 stars
    str = NSLocalizedString(@"***", @"3 stars rate");
  } else if (rate > 30) {
    // 2 stars
    str = NSLocalizedString(@"**", @"2 stars rate");
  } else if (rate > 10) {
    // 1 star
    str = NSLocalizedString(@"*", @"1 star rate");
  } else {
    // 0 star
    str = NSLocalizedString(@"ooooo", @"0 star rate");
  }
  [ibRate setStringValue:str];
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
    info.start[0] = .961f;
    info.start[1] = .969f;
    info.start[2] = .988f;
    info.start[3] = 1;

    info.end[0] = .620f;
    info.end[1] = .710f;
    info.end[2] = .886f;
    info.end[3] = 1;
    
    border[0] = .086f;
    border[1] = .251f;
    border[2] = .502f;
    border[3] = 1;
  }
  return self;
}

- (void)dealloc {
  if (shading)
    CGShadingRelease(shading);
  [super dealloc];
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
    shading = SKCGCreateShading(CGPointMake(0, NSHeight([self bounds])), CGPointZero, SKCGSimpleShadingFunction, &info);
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
  info.start[0] = 0.8 + info.end[0] * 0.2;
  info.start[1] = 0.8 + info.end[1] * 0.2;
  info.start[2] = 0.8 + info.end[2] * 0.2;
  info.start[3] = 0.8 + info.end[3] * 0.2;
  if (shading) {
    CGShadingRelease(shading);
    shading = NULL;
  }
  [self setNeedsDisplay:YES];
}

- (NSColor *)backgroundTopColor {
  return [NSColor colorWithCalibratedRed:info.start[0] green:info.start[1] blue:info.start[2] alpha:info.start[3]];
}
- (void)setBackgroundTopColor:(NSColor *)aColor {
  [[aColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getComponents:info.start];
  if (shading) {
    CGShadingRelease(shading);
    shading = NULL;
  }
  [self setNeedsDisplay:YES];
}

- (NSColor *)backgroundBottomColor {
  return [NSColor colorWithCalibratedRed:info.end[0] green:info.end[1] blue:info.end[2] alpha:info.end[3]];
}
- (void)setBackgroundBottomColor:(NSColor *)aColor {
  [[aColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getComponents:info.end];
  if (shading) {
    CGShadingRelease(shading);
    shading = NULL;
  }
  [self setNeedsDisplay:YES];
}

@end

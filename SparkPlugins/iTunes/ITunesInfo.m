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

- (id)init {
  NSWindow *info = [[SKNotificationWindow alloc] init];
  [info setOneShot:NO];
  [info setHasShadow:YES];
  [info setIgnoresMouseEvents:NO];
  [info setMovableByWindowBackground:YES];
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
  [[self window] setFrameOrigin:NSMakePoint(150, 150)];
  [[self window] setContentView:[aView autorelease]];
}

- (IBAction)display:(id)sender {
  [(id)[self window] display:sender];
}

- (void)setDuration:(SInt32)aTime rate:(SInt32)rate {
  NSString *str = nil;
  if (aTime > 3600 * 24) {
    str = NULL; // TODO: [NSString stringWithFormat:@"%i:%.2i:%.2i:%.2i - ", aTime / 60, aTime % 60]
  } else if (aTime > 3600) {
    str = [NSString stringWithFormat:@"%i:%.2i:%.2i -", aTime / 3600, (aTime % 3600) / 60, aTime % 60];
  } else if (aTime > 0) {
    str = [NSString stringWithFormat:@"%i:%.2i -", aTime / 60, aTime % 60];
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
    shading = SKCGCreateShading(CGPointMake(0, NSHeight(frame)), CGPointZero, SKCGSimpleShadingFunction, &info);
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
  CGContextDrawShading(ctxt, shading);
  CGContextRestoreGState(ctxt);
  
  /* Border */
  SKCGContextAddRoundRect(ctxt, rect, 8);
  rect.origin.x += 3;
  rect.origin.y += 3;
  rect.size.width -= 6;
  rect.size.height -= 6;
  SKCGContextAddRoundRect(ctxt, rect, 5);
  CGContextSetRGBFillColor(ctxt,.086f, .251f, .502f, 1);
  CGContextDrawPath(ctxt, kCGPathEOFill);
}

@end

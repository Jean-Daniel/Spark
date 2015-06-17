//
//  ITunesProgressView.m
//  Spark Plugins
//
//  Created by Jean-Daniel Dupas on 14/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ITunesProgressView.h"

#import <WonderBox/WBCGFunctions.h>

@implementation ITunesProgressView {
@private
  CGFloat _red, _green, _blue, _alpha;
}

- (void)setColor:(NSColor *)aColor {
  if (aColor) {
    [[aColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&_red green:&_green blue:&_blue alpha:&_alpha];
  } else {
    _alpha = 1;
    _red = _green = _blue = 0;
  }
}

- (void)setProgress:(CGFloat)progress {
  _progress = progress;
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)r {
  CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
  CGRect rect = NSRectToCGRect([self bounds]);
  // FIXME: userspace scale factor
  rect = CGRectInset(rect, .5, .5);
  //rect = CGRectIntegral(rect);
  
  CGContextSaveGState(ctxt);
  CGContextSetRGBFillColor(ctxt, _red, _green, _blue, _alpha);
  CGContextSetRGBStrokeColor(ctxt, _red, _green, _blue, _alpha);
  
  CGContextSaveGState(ctxt);
  /* clip to round rect */
  CGFloat radius = CGRectGetHeight(rect) / 2;
  WBCGContextAddRoundRect(ctxt, rect, radius);
  CGContextClip(ctxt);
  /* draw progress bar */
  CGRect progress = rect;
  progress.size.width *= _progress;
  CGContextFillRect(ctxt, progress);
  CGContextRestoreGState(ctxt);

  /* stroke progress border */
  WBCGContextAddRoundRect(ctxt, rect, radius);
  CGContextStrokePath(ctxt);
  
  CGContextRestoreGState(ctxt);
}

@end

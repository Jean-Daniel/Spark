/*
 *  ITunesStarView.m
 *  Spark Plugins
 *
 *  Created by Grayfox on 13/01/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 */

#import "ITunesStarView.h"

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKCGFunctions.h>

@implementation ITunesStarView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void) dealloc {
  [ia_color release];
  [super dealloc];
}

- (UInt8)rate {
  return ia_rate;
}
- (void)setRate:(UInt8)rate {
  if (ia_rate != rate) {
    ia_rate = rate;
    [self setNeedsDisplay:YES];
  }
}

- (NSColor *)starsColor {
  return ia_color;
}
- (void)setStarsColor:(NSColor *)aColor {
  SKSetterRetain(ia_color, aColor);
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect {
  CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
  CGContextSaveGState(ctxt);
  /* Set fill color */
  if (ia_color)
    [ia_color setFill];
  else
    CGContextSetGrayFillColor(ctxt, 0, 1);
  
  double shift = 0.5 / SKWindowScaleFactor([self window]);
  if (ia_rate) {
    double center = 6;
    unsigned rate = ia_rate / 2;
    while (rate-- > 0) {
      SKCGContextAddStar(ctxt, CGPointMake(center + shift, 8), 5, 6, 0);
      center += 13;
    }
    CGContextFillPath(ctxt);
    /* if 1/2 */
    if (ia_rate % 2) {
      CGContextClipToRect(ctxt, CGRectMake(center - 6, 0, 6 + 2 * shift, 17));
      SKCGContextAddStar(ctxt, CGPointMake(center + shift, 8), 5, 6, 0);
    }
    CGContextFillPath(ctxt);
  } else {
    CGRect point = CGRectMake(4 + shift, 6, 3, 3);
    for (unsigned idx = 0; idx < 5; idx++) {
      CGContextAddEllipseInRect(ctxt, point);
      point.origin.x += 12;
    }
    CGContextFillPath(ctxt);
  }
  
  CGContextRestoreGState(ctxt);
}

@end

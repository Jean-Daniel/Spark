/*
 *  ITunesStarView.m
 *  Spark Plugins
 *
 *  Created by Grayfox on 13/01/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 */

#import "ITunesStarView.h"

#import WBHEADER(WBFunctions.h)
#import WBHEADER(WBCGFunctions.h)

@implementation ITunesStarView

static
void _ITunesDrawHalfString(NSPoint point, NSColor *color) {
  static NSMutableAttributedString *sHalf = nil;
  if (!sHalf) {
    unichar half = 0x00bd;
    sHalf = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithCharacters:&half length:1]
                                                   attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName, nil]];
  }
  [sHalf addAttribute:NSForegroundColorAttributeName value:color ? : [NSColor blackColor] range:NSMakeRange(0, 1)];
  [sHalf drawAtPoint:point];
}

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
  WBSetterRetain(ia_color, aColor);
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
  
  // FIXME: userspace scale factor
  CGFloat shift = 0.5 / WBWindowUserSpaceScaleFactor([self window]);
  if (ia_rate) {
    double center = 6;
    unsigned rate = ia_rate / 2;
    while (rate-- > 0) {
      WBCGContextAddStar(ctxt, CGPointMake(center + shift, 9), 5, 6, 0);
      center += 13;
    }
    CGContextFillPath(ctxt);
    
    /* if 1/2 */
    if (ia_rate % 2) {
      _ITunesDrawHalfString(NSMakePoint(center - 4, 2), ia_color);
      center += 11;
    }
    
    rate = (10 - ia_rate) / 2;
    if (rate > 0) {
      /* Adjust color */
      if (ia_color)
        [[ia_color colorWithAlphaComponent:0.25 * [ia_color alphaComponent]] setFill];
      else
        CGContextSetGrayFillColor(ctxt, 0, .25);
      
      CGRect point = CGRectMake(center - 2 + shift, 7, 3, 3);
      while (rate-- > 0) {
        CGPoint start = CGPointMake(point.origin.x + point.size.width, point.origin.y + point.size.height / 2);
        /* move to start */
        CGContextMoveToPoint(ctxt, start.x, start.y);
        /* compute center */
        start.x = point.origin.x + point.size.width / 2;
        CGContextAddArc(ctxt, start.x, start.y, point.size.width / 2, 0, 2 * M_PI, true);
        point.origin.x += 12;
      }
      CGContextFillPath(ctxt);
    }
  } else {
    CGRect point = CGRectMake(4 + shift, 7, 3, 3);
    for (unsigned idx = 0; idx < 5; idx++) {
      CGPoint start = CGPointMake(point.origin.x + point.size.width, point.origin.y + point.size.height / 2);
      /* move to start */
      CGContextMoveToPoint(ctxt, start.x, start.y);
      /* compute center */
      start.x = point.origin.x + point.size.width / 2;
      CGContextAddArc(ctxt, start.x, start.y, point.size.width / 2, 0, 2 * M_PI, true);
      point.origin.x += 12;
    }
    CGContextFillPath(ctxt);
  }
  
  CGContextRestoreGState(ctxt);
}

@end

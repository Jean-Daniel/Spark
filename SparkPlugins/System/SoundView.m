/*
 *  SoundView.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "SoundView.h"

@implementation SoundView

- (BOOL)isMuted {
  return [super zero];
}
- (void)setMuted:(BOOL)flag {
  [super setZero:flag];
}

- (void)drawImage:(CGContextRef)ctxt {
  /* Draw Sound logo */
  CGContextMoveToPoint(ctxt, 36.f, 78.f);
  CGContextAddLineToPoint(ctxt, 57.f, 78.f);
  CGContextAddLineToPoint(ctxt, 72.f, 63.f);
  CGContextAddLineToPoint(ctxt, 72.f, 115.f);
  CGContextAddLineToPoint(ctxt, 57.f, 100.f);
  CGContextAddLineToPoint(ctxt, 36.f, 100.f);
  CGContextFillPath(ctxt);
  
  if (![self isMuted]) {
    /* If not muted, draw circles */
    CGContextSetLineWidth(ctxt, 6.f);
    CGContextSetLineCap(ctxt, kCGLineCapRound);
    
    CGContextAddArc(ctxt, 80.5f, 88.5f, 11.f, -M_PI/3, M_PI/3, FALSE);
    CGContextStrokePath(ctxt);
  
    CGContextAddArc(ctxt, 77.f, 88.5f, 30.f, -M_PI/3, M_PI/3, FALSE);
    CGContextStrokePath(ctxt);
    
    CGContextAddArc(ctxt, 77.f, 88.5f, 45.f, -M_PI/3, M_PI/3, FALSE);
    CGContextStrokePath(ctxt);
  }
}

@end

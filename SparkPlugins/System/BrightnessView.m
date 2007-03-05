/*
 *  BrightnessView.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "BrightnessView.h"
#import <ShadowKit/SKCGFunctions.h>

@implementation BrightnessView

- (void)drawImage:(CGContextRef)ctxt {
  CGContextSetGrayFillColor(ctxt, 1, 1);
  CGContextSetGrayStrokeColor(ctxt, 0.5, 1);
  
  CGContextTranslateCTM(ctxt, 82, 93);
  
  CGContextBeginTransparencyLayer(ctxt, NULL);
  
  CGContextMoveToPoint(ctxt, 16, 0);
  CGContextAddArc(ctxt, 0, 0, 16, 0, 2 * M_PI, true);
  
  CGContextMoveToPoint(ctxt, 28, 0);
  CGContextAddArc(ctxt, 0, 0, 28, 0, 2 * M_PI, false);

  for (unsigned int idx = 0; idx < 8; idx++) {
    SKCGContextAddRoundRect(ctxt, CGRectMake(36, -5.5, 24, 11), 5.5);
    CGContextRotateCTM(ctxt, M_PI_4);
  }
  CGContextDrawPath(ctxt, kCGPathEOFillStroke);
  CGContextEndTransparencyLayer(ctxt);
}

@end

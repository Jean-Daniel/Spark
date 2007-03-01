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
  CGContextSetGrayFillColor(ctxt, 1, 0.1);
  CGContextFillRect(ctxt, CGRectFromNSRect([self bounds]));
  
  CGContextSetGrayFillColor(ctxt, 1, 1);
  CGContextSetGrayStrokeColor(ctxt, 0.5, 1);
  
  CGContextTranslateCTM(ctxt, 81, 93);
  
  CGContextBeginTransparencyLayer(ctxt, NULL);
  
  CGContextAddEllipseInRect(ctxt, CGRectMake(-16, -16, 32, 32));
  CGContextAddEllipseInRect(ctxt, CGRectMake(-28, -28, 56, 56));

  for (unsigned int idx = 0; idx < 8; idx++) {
    SKCGContextAddRoundRect(ctxt, CGRectMake(36, -5.5, 24, 11), 5.5);
    CGContextRotateCTM(ctxt, M_PI_4);
  }
  CGContextDrawPath(ctxt, kCGPathEOFillStroke);
  CGContextEndTransparencyLayer(ctxt);
}

@end

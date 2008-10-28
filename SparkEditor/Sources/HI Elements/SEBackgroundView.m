/*
 *  SEBackgroundView.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEBackgroundView.h"
#import WBHEADER(WBFunctions.h)
#import WBHEADER(WBCGFunctions.h)

static const 
WBCGSimpleShadingInfo kSETopShadingInfo = {
	{.771, .771, .771, 1},
	{.508, .508, .508, 1},
  NULL,
};

static bool sShading = false;
static const CGFloat se_top = 46;
static const CGFloat se_bottom = 35;

static CGLayerRef sSETopShadingImage = nil;

@implementation SEBackgroundView

+ (void)initialize {
  if ([SEBackgroundView class] == self) {
    if (WBSystemMajorVersion() >= 10 && WBSystemMinorVersion() < 5) {
      sShading = true;
    }
  }
}

+ (void)configureWindow:(NSWindow *)aWindow {
  if (WBSystemMajorVersion() >= 10 && WBSystemMinorVersion() < 5) {
    [aWindow setBackgroundColor:[NSColor colorWithCalibratedWhite:.773 alpha:1]];
  }
}

- (void)drawRect:(NSRect)rect {
  if (sShading) {
    CGFloat radius = 10;
    
    NSRect bounds = [self bounds];
    CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextMoveToPoint(ctxt, NSMinX(bounds), NSMaxY(bounds));
    /* Left border */
    CGContextAddLineToPoint(ctxt, NSMinX(bounds), NSMinY(bounds) + radius);
    /* Bottom left */
    CGContextAddArc(ctxt, NSMinX(bounds) + radius, NSMinY(bounds) + radius, 10, M_PI, 3 * M_PI_2, 0);
    /* Bottom */
    CGContextAddLineToPoint(ctxt, NSMaxX(bounds) - radius, NSMinY(bounds));
    /* Bottom right */
    CGContextAddArc(ctxt, NSMaxX(bounds) - radius, NSMinY(bounds) + radius, 10, 3 * M_PI_2, 0, 0);
    /* Right */
    CGContextAddLineToPoint(ctxt, NSMaxX(bounds), NSMaxY(bounds));
    CGContextClosePath(ctxt);
    CGContextClip(ctxt);
    
    CGContextAddRect(ctxt, CGRectMake(NSMinX(rect), NSMinY(rect), NSWidth(rect), NSHeight(rect)));
    CGContextClip(ctxt);
    
    NSRect gradient = NSMakeRect(0, NSMaxY(bounds) - se_top, NSMaxX(bounds), se_top);
    if (NSIntersectsRect(gradient, rect)) {
      gradient.origin.x += 1;
      gradient.size.width -= 2;
      if (!sSETopShadingImage)
        sSETopShadingImage = WBCGLayerCreateWithVerticalShading(ctxt, CGSizeMake(128, se_top), true, WBCGShadingSimpleShadingFunction, (void *)&kSETopShadingInfo);
      CGContextDrawLayerInRect(ctxt, NSRectToCGRect(gradient), sSETopShadingImage);
      
      CGContextSaveGState(ctxt);
      CGRect rects[] = { 
        CGRectMake(0, NSMaxY(bounds) - se_top, 1, se_top - 18), 
			CGRectMake(NSMaxX(bounds) - 1, NSMaxY(bounds) - se_top, NSMaxX(bounds), se_top - 18)};
      CGContextClipToRects(ctxt, rects, 2);
      
      CGContextDrawLayerInRect(ctxt, CGRectMake(0, NSMaxY(bounds) - se_top, 1, se_top), sSETopShadingImage);
      CGContextDrawLayerInRect(ctxt, CGRectMake(NSMaxX(bounds) - 1, NSMaxY(bounds) - se_top, NSMaxX(bounds), se_top), sSETopShadingImage);
      CGContextRestoreGState(ctxt);
    }
    
    gradient = NSMakeRect(0, 0, NSMaxX(bounds), se_bottom);
    if (NSIntersectsRect(gradient, rect)) {
      CGContextDrawLayerInRect(ctxt, NSRectToCGRect(gradient), sSETopShadingImage);
      
      // FIXME: userspace scale factor
      CGContextSetGrayStrokeColor([[NSGraphicsContext currentContext] graphicsPort], .978, 1);
      [NSBezierPath strokeLineFromPoint:NSMakePoint(0, se_bottom - .5) toPoint:NSMakePoint(NSMaxX(bounds), se_bottom - .5)];
      
      // FIXME: userspace scale factor
      CGContextSetGrayStrokeColor([[NSGraphicsContext currentContext] graphicsPort], .2745, 1);
      [NSBezierPath strokeLineFromPoint:NSMakePoint(0, .5) toPoint:NSMakePoint(NSMaxX(bounds), .5)];
    }
  }
}

@end

/*
 *  WBLevelView.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "WBLevelView.h"

static 
NSShadow *sDropShadow = nil, *sLevelShadow = nil;

@implementation WBLevelView

+ (void)initialize {
  if ([WBLevelView class] == self) {
    sDropShadow = [[NSShadow alloc] init];
    [sDropShadow setShadowBlurRadius:4];
    [sDropShadow setShadowOffset:NSMakeSize(1, -2)];
    [sDropShadow setShadowColor:[NSColor colorWithCalibratedWhite:0 alpha:.5f]];
    
    sLevelShadow = [[NSShadow alloc] init];
    [sLevelShadow setShadowBlurRadius:2];
    [sLevelShadow setShadowOffset:NSMakeSize(0, -1)];
    [sLevelShadow setShadowColor:[NSColor colorWithCalibratedWhite:0 alpha:.75f]];
  }
}

- (BOOL)drawsLevelIndicator {
  return !sk_svFlags.hide;
}
- (void)setDrawsLevelIndicator:(BOOL)flag {
  WBFlagSet(sk_svFlags.hide, !flag);
  [self setNeedsDisplay:YES];
}

- (BOOL)zero {
  return sk_svFlags.zero;
}
- (void)setZero:(BOOL)flag {
  WBFlagSet(sk_svFlags.zero, flag);
}

- (NSUInteger)level {
  return sk_svFlags.level;
}
- (void)setLevel:(NSUInteger)level {
  if (level > kWBLevelViewMaxLevel) level = kWBLevelViewMaxLevel;
  sk_svFlags.level = level;
  [self setNeedsDisplay:YES];
}

- (void)drawImage:(CGContextRef)ctxt {
}

- (void)drawLevelIndicator:(CGContextRef)ctxt {
  NSUInteger level = [self zero] ? 0 : [self level];
  
  unsigned idx = 0;
  CGContextSetGrayFillColor(ctxt, 0, .45);
  CGRect plot = CGRectMake(143, 3, 7, 9);
  for (idx = kWBLevelViewMaxLevel; idx > level; idx--) {
    CGContextAddRect(ctxt, plot);
    plot.origin.x -= 9;
  }
  CGContextFillPath(ctxt);
  
  [sLevelShadow set];
  CGContextSetGrayFillColor(ctxt, 1, 1);
  while (idx-- > 0) {
    CGContextAddRect(ctxt, plot);
    plot.origin.x -= 9;    
  }
  CGContextFillPath(ctxt);
}

- (void)drawRect:(NSRect)rect {
  CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
  /* First save context */
  CGContextSaveGState(ctxt);
  
  /* Set drop Shadow */
  [sDropShadow set];
  CGContextSetGrayFillColor(ctxt, 1, 1);
  CGContextSetGrayStrokeColor(ctxt, 1, 1);
  
  /* Draw Sound logo */
  [self drawImage:ctxt];
  
  /* Draw sound volume */
  if ([self drawsLevelIndicator]) {
    /* Restore Context (reset shadow) */
    CGContextRestoreGState(ctxt);
    CGContextSaveGState(ctxt);
    [self drawLevelIndicator:ctxt];
  }
  
  /* Restore Context (reset shadow) */
  CGContextRestoreGState(ctxt);
}

@end

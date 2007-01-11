/*
 *  SoundView.m
 *  Labo Test
 *
 *  Created by Grayfox on 08/01/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 */

#import "SoundView.h"
#import "AudioOutput.h"

@implementation SoundView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
      
    }
    return self;
}

- (BOOL)isMuted {
  return sk_svFlags.mute;
}
- (void)setMuted:(BOOL)flag {
  SKSetFlag(sk_svFlags.mute, flag);
  [self setNeedsDisplay:YES];
}

- (UInt32)level {
  return sk_svFlags.level;
}
- (void)setLevel:(UInt32)level {
  if (level > kAudioOutputVolumeMaxLevel) level = kAudioOutputVolumeMaxLevel;
  sk_svFlags.level = level;
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect {
  CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
  /* First save context */
  CGContextSaveGState(ctxt);
  
  /* Set drop Shadow */
  NSShadow *dropshadow = [[NSShadow alloc] init];
  [dropshadow setShadowBlurRadius:4];
  [dropshadow setShadowOffset:NSMakeSize(1, -2)];
  [dropshadow setShadowColor:[NSColor colorWithCalibratedWhite:0 alpha:.5f]];
  [dropshadow set];

  /* Draw Sound logo */
  CGContextMoveToPoint(ctxt, 36.f, 78.f);
  CGContextAddLineToPoint(ctxt, 57.f, 78.f);
  CGContextAddLineToPoint(ctxt, 72.f, 63.f);
  CGContextAddLineToPoint(ctxt, 72.f, 115.f);
  CGContextAddLineToPoint(ctxt, 57.f, 100.f);
  CGContextAddLineToPoint(ctxt, 36.f, 100.f);
  
  CGContextSetGrayFillColor(ctxt, 1.f, 1.f);
  CGContextFillPath(ctxt);
  
  if (![self isMuted]) {
    /* If not muted, draw circles */
    CGContextSetLineWidth(ctxt, 6.f);
    CGContextSetLineCap(ctxt, kCGLineCapRound);
    CGContextSetGrayStrokeColor(ctxt, 1.f, 1.f);
  
    CGContextAddArc(ctxt, 80.5f, 88.5f, 11.f, -M_PI/3, M_PI/3, FALSE);
    CGContextStrokePath(ctxt);
  
    CGContextAddArc(ctxt, 77.f, 88.5f, 30.f, -M_PI/3, M_PI/3, FALSE);
    CGContextStrokePath(ctxt);
    
    CGContextAddArc(ctxt, 77.f, 88.5f, 45.f, -M_PI/3, M_PI/3, FALSE);
    CGContextStrokePath(ctxt);
  }
  
  /* Restore Context (reset shadow) */
  CGContextRestoreGState(ctxt);
  
  CGContextSaveGState(ctxt);
  /* Draw sound volume */
  UInt32 level = [self isMuted] ? 0 : [self level];
  
  unsigned idx = 0;
  CGContextSetGrayFillColor(ctxt, 0.f, .45f);
  CGRect plot = CGRectMake(143.f, 3.f, 7.f, 9.f);
  for (idx = 16; idx > level; idx--) {
    CGContextAddRect(ctxt, plot);
    plot.origin.x -= 9;
  }
  CGContextFillPath(ctxt);
  
  [dropshadow setShadowBlurRadius:2];
  [dropshadow setShadowOffset:NSMakeSize(0, -1)];
    [dropshadow setShadowColor:[NSColor colorWithCalibratedWhite:0 alpha:.75f]];
  [dropshadow set];
  CGContextSetGrayFillColor(ctxt, 1.f, 1.f);
  while (idx-- > 0) {
    CGContextAddRect(ctxt, plot);
    plot.origin.x -= 9;    
  }
  CGContextFillPath(ctxt);
  [dropshadow release];
  
  /* Restore Context */
  CGContextRestoreGState(ctxt);
}

@end

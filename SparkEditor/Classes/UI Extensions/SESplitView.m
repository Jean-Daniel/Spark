/*
 *  SESplitView.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SESplitView.h"

static NSImage *XECenterDividerImage = nil;
static NSImage *XEVerticalDividerImage = nil;
static NSImage *XEHorizontalDividerImage = nil;

@implementation SESplitView

+ (void)initialize {
  if ([SESplitView class] == self) {
    XECenterDividerImage = [[NSImage imageNamed:@"SESplitDot"] retain];
    XEVerticalDividerImage = [[NSImage imageNamed:@"SEVSplitBar"] retain];
    XEHorizontalDividerImage = [[NSImage imageNamed:@"SEHSplitBar"] retain];
  }
}

- (float)dividerThickness {
  return 5.0f;
}

- (void)drawDividerInRect:(NSRect)aRect {
  NSPoint center;
  NSImage *background = nil;
  if ([self isVertical]) {
    background = XEVerticalDividerImage;
    center.x = NSMinX(aRect);
    center.y = (NSHeight(aRect) + [XECenterDividerImage size].height) / 2;
  } else {
    background = XEHorizontalDividerImage;
    center.x = (NSWidth(aRect) + [XECenterDividerImage size].width) / 2;    
    center.y = NSMaxY(aRect);
  }
  /* Draw background */
  if (background) {
    NSRect src = NSZeroRect;
    src.size = [background size];
    [background drawInRect:aRect fromRect:src operation:NSCompositeSourceOver fraction:1];
  } else {
    CGContextSetGrayFillColor([[NSGraphicsContext currentContext] graphicsPort], .933, 1);
    [NSBezierPath fillRect:aRect];
  }
  /* Draw the center image */
  center.x = roundf(center.x);
  center.y = roundf(center.y);
  [XECenterDividerImage compositeToPoint:center operation:NSCompositeSourceOver];
}

@end

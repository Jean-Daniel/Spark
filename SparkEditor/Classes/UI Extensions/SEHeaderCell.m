/*
 *  SEHeaderCell.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SEHeaderCell.h"

static
NSImage *SEHeaderCellCreateShading(float height, Boolean flipped);

#pragma mark -
static NSColor *SEHeaderTextColor = nil;
static NSColor *SEHeaderShadowColor = nil;

@implementation SEHeaderCell

- (id)copyWithZone:(NSZone *)aZone {
  SEHeaderCell *copy = [super copyWithZone:aZone];
  copy->se_background = [se_background retain];
  return copy;
}

#pragma mark -
+ (void)initialize {
  if ([SEHeaderCell class] == self) {
    SEHeaderTextColor = [[NSColor colorWithCalibratedWhite:0.80 alpha:1] retain];
    SEHeaderShadowColor = [[NSColor colorWithCalibratedWhite:0.15 alpha:1] retain];
  }
}

- (void) dealloc {
  [se_background release];
  [super dealloc];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  float y = NSMaxY(cellFrame) - 0.5;
  [NSBezierPath setDefaultLineWidth:1];
  CGContextSetGrayStrokeColor([[NSGraphicsContext currentContext] graphicsPort], .400, 1);
  [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(cellFrame), y) toPoint:NSMakePoint(NSMaxX(cellFrame), y)];  
  
  cellFrame.origin.y++;
  cellFrame.size.height-=2;
  [self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  if (!se_background) {
    se_background = SEHeaderCellCreateShading(NSHeight(cellFrame), [controlView isFlipped]);
  }
  [se_background drawInRect:cellFrame fromRect:NSMakeRect(0, 0, 32, NSHeight(cellFrame)) operation:NSCompositeSourceOver fraction:1];
  
  cellFrame.origin.y += 1;
  [self setTextColor:SEHeaderTextColor];
  [super drawInteriorWithFrame:cellFrame inView:controlView];
  
  cellFrame.origin.y -= 1;
  [self setTextColor:SEHeaderShadowColor];
  [super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end

@implementation SEHeaderCellCorner

- (void)drawRect:(NSRect)frame {
  if (!se_background) {
    se_background = SEHeaderCellCreateShading(NSHeight([self bounds]) -2, NO);
  }
  [se_background compositeToPoint:NSMakePoint(0, 1) operation:NSCompositeSourceOver];
  
  [NSBezierPath setDefaultLineWidth:1];
  CGContextSetGrayStrokeColor([[NSGraphicsContext currentContext] graphicsPort], .400, 1);
  [NSBezierPath strokeLineFromPoint:NSMakePoint(0, .5) toPoint:NSMakePoint(NSWidth(frame), .5)];
  
  [NSBezierPath strokeLineFromPoint:NSMakePoint(NSWidth(frame), 0) toPoint:NSMakePoint(NSWidth(frame), NSHeight(frame))];
}

@end

#pragma mark -
static 
void SEHeaderCellShadingValue (void *info, const float *in, float *out) {
  float v;
  size_t k, components;
  components = (size_t)info;
  
  v = *in;
  for (k = 0; k < components -1; k++) {
    //*out++ = .700 + (.860 - .700) * sqrt(v * (2 - v));
    *out++ = .730 + (.860 - .730) * pow(sin(M_PI_2 * v), 2);
  }
//  float factor = pow(sin(M_PI_2 *v), 2);
//  *out++ = .490 + (.765 - .490) * factor;
//  *out++ = .570 + (.815 - .570) * factor;
//  *out++ = .695 + (.870 - .695) * factor;
  *out++ = 1;
}

static 
CGFunctionRef SEHeaderCellShadingFunction(CGColorSpaceRef colorspace) {
  size_t components;
  static const float input_value_range [2] = { 0, 1 };
  static const float output_value_ranges [8] = { 0, 1, 0, 1, 0, 1, 0, 1 };
  static const CGFunctionCallbacks callbacks = { 0, &SEHeaderCellShadingValue, NULL };
  
  components = 1 + CGColorSpaceGetNumberOfComponents(colorspace);
  return CGFunctionCreate((void *) components, 1, input_value_range, components, output_value_ranges, &callbacks);
}

static NSImage *SEHeaderCellCreateShading(float height, Boolean flipped) {
  CGPoint startPoint = CGPointMake(0, flipped ? height : 0), endPoint = CGPointMake(0, flipped ? 0 : height);
  CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
  CGFunctionRef function = SEHeaderCellShadingFunction(colorspace);
  
  CGShadingRef shading = CGShadingCreateAxial(colorspace, startPoint, endPoint, function, false, false);;
  
  NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(32, height)];
  [image lockFocus];
  CGContextDrawShading([[NSGraphicsContext currentContext] graphicsPort], shading);    
  [image unlockFocus];
  CGShadingRelease(shading);
  CGFunctionRelease(function);
  CGColorSpaceRelease(colorspace);
  
  return image;
}


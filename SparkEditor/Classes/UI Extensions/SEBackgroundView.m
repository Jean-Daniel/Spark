//
//  SEBackgroundView.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 06/07/06.
//  Copyright 2006 Adamentium. All rights reserved.
//

#import "SEBackgroundView.h"

static 
void SEBackgroundShadingValue (void *info, const float *in, float *out) {
  float v;
  size_t k, components;
  components = (size_t)info;
  
  v = *in;
  for (k = 0; k < components -1; k++)
    *out++ = ((.771 - .580) * v) + .580;   
  *out++ = 1;
}

static 
CGFunctionRef SEBackgroundShadingFunction(CGColorSpaceRef colorspace) {
  size_t components;
  static const float input_value_range [2] = { 0, 1 };
  static const float output_value_ranges [8] = { 0, 1, 0, 1, 0, 1, 0, 1 };
  static const CGFunctionCallbacks callbacks = { 0, &SEBackgroundShadingValue, NULL };
  
  components = 1 + CGColorSpaceGetNumberOfComponents(colorspace);
  return CGFunctionCreate((void *) components, 1, input_value_range, components, output_value_ranges, &callbacks);
}

static NSImage *SETopShadingImage = nil;
static NSImage *SEBottomShadingImage = nil;

static const float se_top = 46;
static const float se_bottom = 35;

@implementation SEBackgroundView

static
NSImage *SECreateShadingImage(float height) {
  NSImage *img = [[NSImage alloc] initWithSize:NSMakeSize(128, height)];
  CGPoint startPoint = CGPointMake(0, 0), endPoint = CGPointMake(0, height);
  
  CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
  CGFunctionRef function = SEBackgroundShadingFunction(colorspace);
  CGShadingRef shading = CGShadingCreateAxial(colorspace, startPoint, endPoint, function, false, false);
  
  [img lockFocus];
  CGContextDrawShading([[NSGraphicsContext currentContext] graphicsPort], shading);
  [img unlockFocus];
  
  CGShadingRelease(shading);
  CGFunctionRelease(function);
  CGColorSpaceRelease(colorspace);
  
  return img;
}

+ (void)initialize {
  if ([SEBackgroundView class] == self) {
    SETopShadingImage = SECreateShadingImage(se_top);
    SEBottomShadingImage = SECreateShadingImage(se_bottom);
  }
}

- (void)drawRect:(NSRect)rect {
  float radius = 10;
  
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
    [SETopShadingImage drawInRect:gradient fromRect:NSMakeRect(0, 0, 128, se_top) operation:NSCompositeSourceOver fraction:1];
    
    [SETopShadingImage drawInRect:NSMakeRect(0, NSMaxY(bounds) - se_top, 1, se_top - 18) fromRect:NSMakeRect(0, 0, 1, se_top -18) operation:NSCompositeSourceOver fraction:1];
    [SETopShadingImage drawInRect:NSMakeRect(NSMaxX(bounds) - 1, NSMaxY(bounds) - se_top, NSMaxX(bounds), se_top - 18) fromRect:NSMakeRect(0, 0, 1, se_top -18) operation:NSCompositeSourceOver fraction:1];
  }
      
  gradient = NSMakeRect(0, 0, NSMaxX(bounds), se_bottom);
  if (NSIntersectsRect(gradient, rect)) {
    [SEBottomShadingImage drawInRect:gradient fromRect:NSMakeRect(0, 0, 128, se_bottom) operation:NSCompositeSourceOver fraction:1];

    CGContextSetGrayStrokeColor([[NSGraphicsContext currentContext] graphicsPort], .978, 1);
    [NSBezierPath strokeLineFromPoint:NSMakePoint(0, se_bottom - .5) toPoint:NSMakePoint(NSMaxX(bounds), se_bottom - .5)];
    
    CGContextSetGrayStrokeColor([[NSGraphicsContext currentContext] graphicsPort], .2745, 1);
    [NSBezierPath strokeLineFromPoint:NSMakePoint(0, .5) toPoint:NSMakePoint(NSMaxX(bounds), .5)];
  }
}

@end

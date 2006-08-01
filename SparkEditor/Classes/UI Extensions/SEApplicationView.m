/*
 *  SEApplicationView.m
 *  Spark Editor
 *
 *  Created by Grayfox on 14/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "SEApplicationView.h"

#import <ShadowKit/SKCGFunctions.h>
#import <ShadowKit/SKShadowLabel.h>

#import <SparkKit/SparkApplication.h>

@implementation SEApplicationView

- (id)init {
  if (self = [super init]) {
  }
  return self;
}

- (void)dealloc {
  [se_app release];
  [se_icon release];
  [super dealloc];
}

- (BOOL)isOpaque {
  return NO;
}

- (SparkApplication *)application {
  return se_app;
}
- (void)setApplication:(SparkApplication *)anApp {
  if (se_app != anApp) {
    [se_app release];
    se_app = [anApp retain];
    /* Cache informations */
    [se_title release];
    if (se_app && [se_app uid] == 0) {
      se_title = @"Globals HotKeys";
    } else {
      se_title = se_app ? [[NSString alloc] initWithFormat:@"%@ HotKeys", [se_app name]] : nil;
      //se_title = se_app ? [[se_app name] retain] : nil;
    }
    se_width = se_title ? [se_title sizeWithAttributes:nil].width : 0;
    
    /* Cache icon */
    [se_icon release];
    se_icon = nil;
    if (se_app) {
      if (0 == [se_app uid]) {
        se_icon = [[NSImage imageNamed:@"applelogo"] retain];
      } else if ([se_app path]) {
        se_icon = [[[NSWorkspace sharedWorkspace] iconForFile:[se_app path]] retain];
      } else if ([se_app icon]) {
        se_icon = [[se_app icon] retain];
      } else {
        se_icon = [[[NSWorkspace sharedWorkspace] iconForFileType:@"app"] retain];
      }
    }
    
    [self setNeedsDisplay:YES];
  }
}

static const float kAVMargin = 16.f;
static const float kAVImageSize = 26.f;
static const float kAVImageRightMargin = 6.f;

- (void)drawRect:(NSRect)rect {
  if (se_app) {
    CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetShouldAntialias(ctxt, true);
    CGContextSetInterpolationQuality(ctxt, kCGInterpolationHigh);
    
    float x = AVG(NSWidth([self bounds]), - (se_width + kAVImageSize + kAVImageRightMargin));
    
    CGRect cgrect = CGRectMake(x - kAVMargin, 0.5, se_width + kAVImageSize + kAVImageRightMargin + 2 * kAVMargin, kAVImageSize + 4);
    SKCGContextAddRoundRect(ctxt, cgrect, 5);
    
    CGContextSetGrayStrokeColor(ctxt, 0.5, 1);
    CGContextSetGrayFillColor(ctxt, 0, .050);
    CGContextDrawPath(ctxt,kCGPathFillStroke);
    
    //NSImage *img = nil;
//    if (0 == [se_app uid]) {
//      img = [NSImage imageNamed:@"applelogo"];
//    } else if ([se_app path]) {
//      img = [[NSWorkspace sharedWorkspace] iconForFile:[se_app path]];
//    } else if ([se_app icon]) {
//      img = [se_app icon];
//    } else {
//      img = [[NSWorkspace sharedWorkspace] iconForFileType:@"app"];
//    }
    
    if (se_icon) {
      NSRect source = NSZeroRect;
      source.size = [se_icon size];
      /* paint icon with y=3 because lots of icon look better */
      [se_icon drawInRect:NSMakeRect(x, 3, kAVImageSize, kAVImageSize)
                 fromRect:source
                operation:NSCompositeSourceOver
                 fraction:1];
    }
    
    [[SKShadowLabel defaultShadow] set];
    [se_title drawAtPoint:NSMakePoint(x + kAVImageSize + kAVImageRightMargin, 8) withAttributes:nil];
  }
}

@end

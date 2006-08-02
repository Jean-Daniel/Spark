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

static const float kAVMargin = 16.f;
static const float kAVImageSize = 26.f;
static const float kAVImageRightMargin = 6.f;

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

- (id)target {
  return se_target;
}
- (void)setTarget:(id)aTarget {
  se_target = aTarget;
}

- (SEL)action {
  return se_action;
}
- (void)setAction:(SEL)anAction {
  se_action = anAction;
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
    
    NSRect frame = [self frame];
    NSRect dirty = frame;
    if (se_width > 0) {
      float x = AVG(NSWidth([self bounds]), - (se_width + kAVImageSize + kAVImageRightMargin));
      /* Make sure x is an integer value */
      x = floorf(x);
      frame.origin.x += x - kAVMargin;
      frame.size.width = se_width + kAVImageSize + kAVImageRightMargin + 2 * kAVMargin + 1;
      
      if (x - kAVMargin < 0) {
        dirty = frame;
      }
    } else {
      frame.origin.x += NSWidth([self bounds]) / 2;
    }
    [self setFrame:frame];
    [[self superview] setNeedsDisplayInRect:dirty];
  }
}

- (void)drawRect:(NSRect)rect {
  if (se_app) {
    CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetShouldAntialias(ctxt, true);
    CGContextSetInterpolationQuality(ctxt, kCGInterpolationHigh);
    
    CGRect cgrect = CGRectMake(.5f, .5f, NSWidth([self bounds]) - 1, kAVImageSize + 4);
    SKCGContextAddRoundRect(ctxt, cgrect, 5);
    
    CGContextSetGrayStrokeColor(ctxt, 0.5, 1);
    CGContextSetGrayFillColor(ctxt, 0, se_highlight ? .15f : .05f);
    CGContextDrawPath(ctxt,kCGPathFillStroke);
    
    if (se_icon) {
      NSRect source = NSZeroRect;
      source.size = [se_icon size];
      /* paint icon with y=3 because lots of icon look better */
      [se_icon drawInRect:NSMakeRect(kAVMargin, 3, kAVImageSize, kAVImageSize)
                 fromRect:source
                operation:NSCompositeSourceOver
                 fraction:1];
    }
    
    [[SKShadowLabel defaultShadow] set];
    [se_title drawAtPoint:NSMakePoint(kAVMargin + kAVImageSize + kAVImageRightMargin, 8) withAttributes:nil];
  }
}

- (void)highlight:(BOOL)flag {
  if (XOR(flag, se_highlight)) {
    se_highlight = flag;
    [self setNeedsDisplay:YES];
  }
  
}

- (BOOL)mouseDownCanMoveWindow {
  return NO;
}

- (void)mouseClick:(NSEvent *)theEvent {
  if (se_action)
    [se_target performSelector:se_action withObject:self];
}

- (void)mouseDown:(NSEvent *)theEvent {
  BOOL keepOn = YES;
  
  NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  BOOL isInside = [self mouse:mouseLoc inRect:[self bounds]];
  
  if (isInside) {
    [self highlight:YES];
    
    while (keepOn) {
      theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
      mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
      isInside = [self mouse:mouseLoc inRect:[self bounds]];
      
      switch ([theEvent type]) {
        case NSLeftMouseDragged:
          [self highlight:isInside];
          break;
        case NSLeftMouseUp:
          if (isInside) [self mouseClick:theEvent];
          [self highlight:NO];
          keepOn = NO;
          break;
        default:
          /* Ignore any other kind of event. */
          break;
      }
    }
  }
}

@end

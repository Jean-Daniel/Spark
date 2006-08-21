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

- (BOOL)acceptsFirstResponder {
  return se_action != nil;
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

- (void)viewDidMoveToWindow {
  /* Set dark if window is not textured */
  BOOL flag = ([[self window] styleMask] & NSTexturedBackgroundWindowMask) == 0;
  SKSetFlag(se_saFlags.dark, flag);
}

- (void)setIcon:(NSImage *)anImage {
  SKSetterRetain(se_icon, anImage);
}
- (void)setTitle:(NSString *)title {
  if (title != se_title) {
    /* Cache informations */
    [se_title release];
    se_title = [title retain];
    
    se_width = se_title ? [se_title sizeWithAttributes:nil].width : 0;
    
    NSRect frame = [self frame];
    NSRect dirty = frame;
    if (se_width > 0) {
      float x = 0;
      switch (se_saFlags.align) {
        case 0: /* center */
          x = AVG(NSWidth([[self superview] bounds]), - (se_width + kAVImageSize + kAVImageRightMargin));
          x -= kAVMargin;
          /* Make sure x is an integer value */
          x = floorf(x);
          break;
        case 1: /* left */
          x = 0;
          break;
        case 2: /* right */
          x = NSWidth([self bounds]) - (se_width + kAVImageSize + kAVImageRightMargin);
          
          break;
      }
      
      frame.origin.x = x;
      frame.size.width = se_width + kAVImageSize + kAVImageRightMargin + 2 * kAVMargin + 1;
      
      if (NSWidth(frame) > NSWidth([self bounds])) {
        dirty = frame;
      }
    } else {
      float x = 0;
      switch (se_saFlags.align) {
        case 0: /* center */
          x = NSWidth([self bounds]) / 2;
          break;
        case 1: /* left */
          x = 0;
          break;
        case 2: /* right */
          x = NSWidth([self bounds]);
          break;
      }
      frame.origin.x += x;
    }
    [self setFrame:frame];
    [[self superview] setNeedsDisplayInRect:dirty];
  }
}

- (SparkApplication *)application {
  return se_app;
}
- (void)setApplication:(SparkApplication *)anApp {
  if (se_app != anApp) {
    [se_app release];
    se_app = [anApp retain];
    
    /* Cache icon */
    NSImage *icon = nil;
    if (se_app) {
      if (0 == [se_app uid]) {
        icon = [NSImage imageNamed:@"applelogo"];
      } else if ([se_app path]) {
        icon = [[NSWorkspace sharedWorkspace] iconForFile:[se_app path]];
        if (icon && [[NSWindow class] instancesRespondToSelector:@selector(userSpaceScaleFactor)]) {
          float scale = [[self window] userSpaceScaleFactor];
          if (scale > 1) {
            NSSize size = [icon size];
            size.width = MIN(256, size.width * scale);
            size.height = MIN(256, size.height * scale);
            [icon setSize:size];
          }
        }
        
      } else if ([se_app icon]) {
        icon = [se_app icon];
      } else {
        icon = [[NSWorkspace sharedWorkspace] iconForFileType:@"app"];
      }
    }
    [self setIcon:icon];
    
    /* Update title and refresh (in setTitle:) */
    NSString *title = nil;
    if (se_app && [se_app uid] == 0) {
      title = @"Globals HotKeys";
    } else {
      title = se_app ? [[NSString alloc] initWithFormat:@"%@ HotKeys", [se_app name]] : nil;
    }
    [self setTitle:title];
    [title release];
  }
}

- (void)drawRect:(NSRect)rect {
  if (se_app) {
    CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetShouldAntialias(ctxt, true);
    CGContextSetInterpolationQuality(ctxt, kCGInterpolationHigh);
    
    CGRect cgrect = CGRectMake(.5f, .5f, NSWidth([self bounds]) - 1, kAVImageSize + 4);
    SKCGContextAddRoundRect(ctxt, cgrect, 5);
    
    if (se_saFlags.dark) {
      CGContextSetGrayStrokeColor(ctxt, 0.50, 0.60);
      CGContextSetGrayFillColor(ctxt, 0.65f, se_saFlags.highlight ? .40f : .25f);
    } else {
      CGContextSetGrayStrokeColor(ctxt, 0.5, 1);
      CGContextSetGrayFillColor(ctxt, 0, se_saFlags.highlight ? .15f : .08f);
    }

    /* Draw before image if not highlight */
    if (!se_saFlags.highlight) {
//      if (se_action) {
//        CGContextSaveGState(ctxt);
//        NSSetFocusRingStyle(NSFocusRingBelow);
//      }
      CGContextDrawPath(ctxt, kCGPathFillStroke);
//      if (se_action) {
//        CGContextRestoreGState(ctxt);
//      }
    }
    
    /* Draw icon */
    if (se_icon) {
      NSRect source = NSZeroRect;
      source.size = [se_icon size];
      /* paint icon with y=3 (instead of 2) because lots of icon look better */
      [se_icon drawInRect:NSMakeRect(kAVMargin, 3, kAVImageSize, kAVImageSize)
                 fromRect:source
                operation:NSCompositeSourceOver
                 fraction:1];
    }
    
    if (se_saFlags.highlight) {
      CGContextDrawPath(ctxt, kCGPathFillStroke);
    }
    
    /* Draw string */
    if (!se_saFlags.dark) {
      [[SKShadowLabel defaultShadow] set];
    }
    [se_title drawAtPoint:NSMakePoint(kAVMargin + kAVImageSize + kAVImageRightMargin, 8) withAttributes:nil];
  }
}

- (void)highlight:(BOOL)flag {
  BOOL high = se_saFlags.highlight;
  if (XOR(flag, high)) {
    SKSetFlag(se_saFlags.highlight, flag);
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
  /* No action, so don't need to handle event */
  if (!se_action)
    return;
  
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

- (void)keyDown:(NSEvent *)theEvent {
  if (!se_action)
    return;
  
  NSString *chr = [theEvent characters];
  if ([chr length]) {
    switch ([chr characterAtIndex:0]) {
      case ' ':
      case '\r':
      case 0x03:
        [se_target performSelector:se_action withObject:self];
        break;
    }
  }
}

@end

@implementation SEApplicationView (NSAccessibility)

- (BOOL)accessibilityIsIgnored {
  return NO;
}

- (id)accessibilityHitTest:(NSPoint)point {
  return self;
}

- (id)accessibilityFocusedUIElement {
  return self;
}

- (NSArray *)accessibilityActionNames {
  return [NSArray arrayWithObject:NSAccessibilityPressAction];
}

- (NSString *)accessibilityActionDescription:(NSString *)action {
  return NSAccessibilityActionDescription(action);
}

- (void)accessibilityPerformAction:(NSString *)action {
  if ([action isEqualToString:NSAccessibilityPressAction]) {
    [self mouseClick:nil];
  } else {
    [super accessibilityPerformAction:action];
  }
}

- (NSArray *)accessibilityAttributeNames {
  NSMutableArray *attr = [[super accessibilityAttributeNames] mutableCopy];
  if (![attr containsObject:NSAccessibilityValueAttribute])
    [attr addObject:NSAccessibilityValueAttribute];
  if (![attr containsObject:NSAccessibilityEnabledAttribute])
    [attr addObject:NSAccessibilityEnabledAttribute];
  return [attr autorelease];
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
  if ([attribute isEqualToString:NSAccessibilityRoleAttribute])
    return NSAccessibilityButtonRole;
  else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute])
    return NSAccessibilityRoleDescription(NSAccessibilityButtonRole, nil);
  else if ([attribute isEqualToString:NSAccessibilityValueAttribute]) {
    return se_title;
  } else if ([attribute isEqualToString:NSAccessibilityEnabledAttribute]) {
    return SKBool(se_action != NULL);
  }
  else return [super accessibilityAttributeValue:attribute];
}

@end

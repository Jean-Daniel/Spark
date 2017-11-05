/*
 *  SEApplicationView.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEApplicationView.h"

#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkApplication.h>

#import <WonderBox/WBCGFunctions.h>

static const CGFloat kAVMargin = 16;
static const CGFloat kAVImageSize = 26;
static const CGFloat kAVImageRightMargin = 6;

/*
 Recommanded height: 31 pixels.
 */
@implementation SEApplicationView {
@private
  SparkApplication *se_app;

  CGFloat wb_width;
  struct _wb_saFlags {
    unsigned int dark:1;
    unsigned int highlight:1;
    unsigned int reserved:30;
  } wb_saFlags;
}

static inline CGColorRef _ShadowColor() {
  static CGColorRef sShadowColor;
  if (!sShadowColor)
    sShadowColor = CGColorCreateGenericGray(.786, 1);
  return sShadowColor;
}

- (void)setTitle:(NSString *)title {
  if (title != _title) {
    /* Cache informations */
    _title = [title copy];

    wb_width = _title ? [_title sizeWithAttributes:nil].width : 0;
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay:YES];
    //    NSRect frame = [self frame];
    //    NSRect dirty = frame;
    //    if (wb_width > 0) {
    //      CGFloat x = 0;
    //      switch (wb_saFlags.align) {
    //        case 0: /* center */
    //          x = (NSWidth([[self superview] bounds]) - (wb_width + kAVImageSize + kAVImageRightMargin)) / 2;
    //          x -= kAVMargin;
    //          /* Make sure x is an integer value */
    //          x = floor(x);
    //          break;
    //        case 1: /* left */
    //          x = 0;
    //          break;
    //        case 2: /* right */
    //          x = NSWidth([self bounds]) - (wb_width + kAVImageSize + kAVImageRightMargin);
    //
    //          break;
    //      }
    //
    //      frame.origin.x = x;
    //      frame.size.width = wb_width + kAVImageSize + kAVImageRightMargin + 2 * kAVMargin + 1;
    //
    //      if (NSWidth(frame) > NSWidth([self bounds])) {
    //        dirty = frame;
    //      }
    //    } else {
    //      CGFloat x = 0;
    //      switch (wb_saFlags.align) {
    //        case 0: /* center */
    //          x = NSWidth([self bounds]) / 2;
    //          break;
    //        case 1: /* left */
    //          x = 0;
    //          break;
    //        case 2: /* right */
    //          x = NSWidth([self bounds]);
    //          break;
    //      }
    //      frame.origin.x += x;
    //    }
    // [self setFrame:frame];
    // [[self superview] setNeedsDisplayInRect:dirty];
  }
}


- (SparkApplication *)sparkApplication {
  return se_app;
}
- (void)setSparkApplication:(SparkApplication *)anApp {
  if (se_app != anApp) {
    se_app = anApp;
    
		NSString *title = se_app ? [[NSString alloc] initWithFormat:
																NSLocalizedString(@"%@ HotKeys", @"Application HotKeys - Application View Title (%@ => name)"), [se_app name]] : nil;
    self.title = title;

    if (kSparkApplicationSystemUID == [se_app uid]) {
      self.icon = [NSImage imageNamed:@"applelogo"];
    } else {
      self.icon = se_app.icon;
    }
  }
}

- (NSImage *)defaultIcon {
  if ([se_app icon])
    return [se_app icon];
  else
    return [[NSWorkspace sharedWorkspace] iconForFileType:@"'APPL'"];
}

- (void)highlight:(BOOL)flag {
  bool previous = SPXFlagTestAndSet(wb_saFlags.highlight, flag);
  if (previous != wb_saFlags.highlight) {
    [self setNeedsDisplay:YES];
  }
}

#pragma mark -
- (BOOL)acceptsFirstResponder {
  return _action != nil && [[NSApp currentEvent] type] == NSKeyDown;
}

- (BOOL)becomeFirstResponder {
  [self setNeedsDisplay:YES];
  return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
  /* Cleanup Focus ring */
  NSRect frame = [self frame];
  frame.origin.x -= 4;
  frame.origin.y -= 4;
  frame.size.width += 8;
  frame.size.height += 8;
  [[self superview] setNeedsDisplayInRect:frame];
  /* Redraw self */
  [self setNeedsDisplay:YES];
  return [super resignFirstResponder];
}

- (BOOL)isOpaque {
  return NO;
}

- (void)viewDidMoveToWindow {
  /* Set dark if window is not textured */
  BOOL flag = ([[self window] styleMask] & NSTexturedBackgroundWindowMask) == 0;
  SPXFlagSet(wb_saFlags.dark, flag);
}


- (BOOL)mouseDownCanMoveWindow {
  return NO;
}

- (void)mouseClick:(NSEvent *)theEvent {
  if (_action)
    [NSApp sendAction:_action to:_target from:self];
}

- (void)mouseDown:(NSEvent *)theEvent {
  /* No action, so don't need to handle event */
  if (!_action)
    return;

  BOOL keepOn = YES;

  NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  BOOL isInside = [self mouse:mouseLoc inRect:[self bounds]];

  if (isInside) {
    [self highlight:YES];

    while (keepOn) {
      NSEvent *event = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
      if (!event)
        continue;

      mouseLoc = [self convertPoint:[event locationInWindow] fromView:nil];
      isInside = [self mouse:mouseLoc inRect:[self bounds]];

      switch ([event type]) {
        case NSLeftMouseDragged:
          [self highlight:isInside];
          break;
        case NSLeftMouseUp:
          if (isInside) [self mouseClick:event];
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
  if (!_action)
    return;

  NSString *chr = [theEvent characters];
  if ([chr length]) {
    switch ([chr characterAtIndex:0]) {
      case ' ':
      case '\r':
      case 0x03:
        [NSApp sendAction:_action to:_target from:self];
        return;
    }
  }
  [super keyDown:theEvent];
}

- (NSSize)intrinsicContentSize {
  return NSMakeSize(wb_width + kAVImageSize + kAVImageRightMargin + 2 * kAVMargin + 1, NSViewNoIntrinsicMetric);
}

- (void)drawRect:(NSRect)rect {
  if ([self title] || [self icon]) {
    CGContextRef ctxt = [NSGraphicsContext.currentContext graphicsPort];

    CGContextSetShouldAntialias(ctxt, true);
    CGContextSetInterpolationQuality(ctxt, kCGInterpolationHigh);
    // FIXME: userspace scale factor
    CGRect cgrect = CGRectMake(.5, .5, NSWidth([self bounds]) - 1, NSHeight([self bounds]) - 1);
    CGMutablePathRef path = CGPathCreateMutable();
    WBCGPathAddRoundRect(path, NULL, cgrect, 5);

    if (wb_saFlags.dark) {
      CGContextSetGrayStrokeColor(ctxt, 0.50, 0.60);
      CGContextSetGrayFillColor(ctxt, 0.65f, wb_saFlags.highlight ? .40f : .25f);
    } else {
      CGContextSetGrayStrokeColor(ctxt, 0.5, 1);
      CGContextSetGrayFillColor(ctxt, 0, wb_saFlags.highlight ? .15f : .08f);
    }

    /* Draw focus ring if needed */
    BOOL isFirst = _action && [[self window] firstResponder] == self;
    if (isFirst) {
      CGContextSaveGState(ctxt);
      /* Set focus ring */
      NSSetFocusRingStyle(NSFocusRingOnly);
      /* Fill invisible path */
      CGContextAddPath(ctxt, path);
      CGContextFillPath(ctxt);
      CGContextRestoreGState(ctxt);
    }

    CGContextAddPath(ctxt, path);
    CGContextStrokePath(ctxt);

    /* Draw before image if not highlight */
    if (!wb_saFlags.highlight) {
      CGContextAddPath(ctxt, path);
      CGContextFillPath(ctxt);
    }

    /* Draw icon */
    NSImage *icon = [self icon];
    if (icon) {
      NSRect source = NSZeroRect;
      source.size = [icon size];
      /* paint icon with y=3 (instead of 2) because lots of icon look better */
      CGFloat y = round((NSHeight([self bounds]) - kAVImageSize) / 2);
      [icon drawInRect:NSMakeRect(kAVMargin, y, kAVImageSize, kAVImageSize)
              fromRect:source
             operation:NSCompositeSourceOver
              fraction:1];
    }

    if (wb_saFlags.highlight) {
      CGContextAddPath(ctxt, path);
      CGContextFillPath(ctxt);
    }
    CGPathRelease(path);

    /* Draw string */
    if (!wb_saFlags.dark)
      CGContextSetShadowWithColor(ctxt, CGSizeMake(0, -1), 1, _ShadowColor());

    CGFloat y = round((NSHeight([self bounds]) - kAVImageSize + 10) / 2);
    [[self title] drawAtPoint:NSMakePoint(kAVMargin + kAVImageSize + kAVImageRightMargin, y) withAttributes:nil];
  }
}

@end

//@implementation WBImageAndTextView (NSAccessibility)
//
//- (BOOL)accessibilityIsIgnored {
//  return NO;
//}
//
//- (id)accessibilityHitTest:(NSPoint)point {
//  return self;
//}
//
//- (id)accessibilityFocusedUIElement {
//  return self;
//}
//
//- (NSArray *)accessibilityActionNames {
//  return @[NSAccessibilityPressAction];
//}
//
//- (NSString *)accessibilityActionDescription:(NSString *)action {
//  return NSAccessibilityActionDescription(action);
//}
//
//- (void)accessibilityPerformAction:(NSString *)action {
//  if ([action isEqualToString:NSAccessibilityPressAction]) {
//    [self mouseClick:nil];
//  } else {
//    [super accessibilityPerformAction:action];
//  }
//}
//
//- (NSArray *)accessibilityAttributeNames {
//  NSMutableArray *attr = [[super accessibilityAttributeNames] mutableCopy];
//  if (![attr containsObject:NSAccessibilityValueAttribute])
//    [attr addObject:NSAccessibilityValueAttribute];
//  if (![attr containsObject:NSAccessibilityEnabledAttribute])
//    [attr addObject:NSAccessibilityEnabledAttribute];
//  return [attr autorelease];
//}
//
//- (id)accessibilityAttributeValue:(NSString *)attribute {
//  if ([attribute isEqualToString:NSAccessibilityRoleAttribute])
//    return NSAccessibilityButtonRole;
//  else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute])
//    return NSAccessibilityRoleDescription(NSAccessibilityButtonRole, nil);
//  else if ([attribute isEqualToString:NSAccessibilityValueAttribute]) {
//    return [self title];
//  } else if ([attribute isEqualToString:NSAccessibilityEnabledAttribute]) {
//    return @(wb_action != NULL);
//  }
//  else return [super accessibilityAttributeValue:attribute];
//}
//
//@end


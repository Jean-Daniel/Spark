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

// MARK: -
@implementation SEApplicationView

- (id)initWithFrame:(NSRect)frameRect {
  if (self = [super initWithFrame:frameRect]) {
    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"SEApplicationView" bundle:NSBundle.mainBundle];
    NSArray *topLevel = nil;
    if ([nib instantiateWithOwner:nil topLevelObjects:&topLevel]) {
      for (id obj in topLevel) {
        if ([obj isKindOfClass:self.class]) {
          self = obj;
          break;
        }
      }
      self.frame = frameRect;
    } else {
      self = nil;
    }
  }
  return self;
}

- (NSString *)title { return nil; }
- (void)setTitle:(NSString *)title {}

- (NSImage *)icon { return nil; }
- (void)setIcon:(NSImage *)anIcon {}

- (SparkApplication *)sparkApplication { return nil; }
- (void)setSparkApplication:(SparkApplication *)anApp {}

@end

// MARK: -
@interface _SEApplicationView : SEApplicationView

@end

/*
 Recommanded height: 31 pixels.
 */
@implementation _SEApplicationView {
@private
  IBOutlet __weak NSImageView *_image;
  IBOutlet __weak NSTextField *_label;

  struct _wb_saFlags {
    unsigned int dark:1;
    unsigned int highlight:1;
    unsigned int reserved:30;
  } wb_saFlags;
}

@synthesize sparkApplication = _sparkApplication;

- (NSString *)title {
  return _label.stringValue;
}
- (void)setTitle:(NSString *)title {
  _label.stringValue = title;
}

- (NSImage *)icon {
  return _image.image;
}
- (void)setIcon:(NSImage *)anIcon {
  _image.image = anIcon;
}

- (void)setSparkApplication:(SparkApplication *)anApp {
  if (_sparkApplication != anApp) {
    _sparkApplication = anApp;
    
		NSString *title = _sparkApplication ? [[NSString alloc] initWithFormat:
                                           NSLocalizedString(@"%@ HotKeys", @"Application HotKeys - Application View Title (%@ => name)"), _sparkApplication.name] : nil;
    self.title = title;
    if (kSparkApplicationSystemUID == _sparkApplication.uid) {
      self.icon = [NSImage imageNamed:@"applelogo"];
    } else {
      self.icon = _sparkApplication.icon;
    }
  }
}

- (NSImage *)defaultIcon {
  return _sparkApplication.icon ?: [[NSWorkspace sharedWorkspace] iconForFileType:SPXCFToNSString(kUTTypeApplication)];
}

- (void)highlight:(BOOL)flag {
  bool previous = SPXFlagTestAndSet(wb_saFlags.highlight, flag);
  if (previous != wb_saFlags.highlight) {
    [self setNeedsDisplay:YES];
  }
}

#pragma mark -
- (BOOL)acceptsFirstResponder {
  return self.action != nil && [[NSApp currentEvent] type] == NSKeyDown;
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
  if (self.action)
    [NSApp sendAction:self.action to:self.target from:self];
}

- (void)mouseDown:(NSEvent *)theEvent {
  /* No action, so don't need to handle event */
  if (!self.action)
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
  if (!self.action)
    return;

  NSString *chr = theEvent.characters;
  if (chr.length) {
    switch ([chr characterAtIndex:0]) {
      case ' ':
      case '\r':
      case 0x03:
        [NSApp sendAction:self.action to:self.target from:self];
        return;
    }
  }
  [super keyDown:theEvent];
}

- (void)drawRect:(NSRect)rect {
  if (self.title || self.icon) {
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
    BOOL isFirst = self.action && self.window.firstResponder == self;
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
    CGContextAddPath(ctxt, path);
    CGContextFillPath(ctxt);
    CGPathRelease(path);

    /* Draw icon */
//    NSImage *icon = [self icon];
//    if (icon) {
//      NSRect source = NSZeroRect;
//      source.size = [icon size];
//      /* paint icon with y=3 (instead of 2) because lots of icon look better */
//      CGFloat y = round((NSHeight([self bounds]) - kAVImageSize) / 2);
//      [icon drawInRect:NSMakeRect(kAVMargin, y, kAVImageSize, kAVImageSize)
//              fromRect:source
//             operation:NSCompositeSourceOver
//              fraction:1];
//    }

    /* Draw string */
//    if (!wb_saFlags.dark)
//      CGContextSetShadowWithColor(ctxt, CGSizeMake(0, -1), 1, _ShadowColor());
//
//    CGFloat y = round((NSHeight([self bounds]) - kAVImageSize + 10) / 2);
//    [[self title] drawAtPoint:NSMakePoint(kAVMargin + kAVImageSize + kAVImageRightMargin, y) withAttributes:nil];
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


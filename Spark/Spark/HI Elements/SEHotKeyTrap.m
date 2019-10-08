/*
 *  SEHotKeyTrap.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEHotKeyTrap.h"

#import <WonderBox/WonderBox.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

/* Trap shading */
static CGColorRef sShadowColor = NULL;
static CGLayerRef sBorderShading = nil;

static NSDictionary *sTextStyle = nil; /* String style */
static NSDictionary *sPlaceholderStyle = nil; /* Placeholder style */

static CGLayerRef _HKCreateShading(CGContextRef ctxt, NSControlTint tint);

@interface SEHotKeyTrap ()
- (void)save;
- (void)revert;

- (BOOL)isEmpty;
- (BOOL)isTrapping;
- (void)setTrapping:(BOOL)flag;
@end

@implementation SEHotKeyTrap {
@private
  NSString *se_str;
  /* Backup */
  SEHotKey se_bhotkey;

  struct _se_htFlags {
    unsigned int trap:1;
    unsigned int hint:1;
    unsigned int cancel:1;
    unsigned int traponce:1;
    unsigned int disabled:1;
    unsigned int inbutton:1;
    unsigned int highlight:1;
    unsigned int reserved:25;
  } se_htFlags;

  NSTrackingRectTag se_tracker;
}

/* Load default shading */
+ (void)initialize {
  // Do it once
  if (self == [SEHotKeyTrap class]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeControlTint:)
                                                 name:NSControlTintDidChangeNotification
                                               object:nil];
    
    sTextStyle = [[NSDictionary alloc] initWithObjectsAndKeys:
      [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
      [NSColor blackColor], NSForegroundColorAttributeName,
      nil];
    
    sPlaceholderStyle = [[NSDictionary alloc] initWithObjectsAndKeys:
      [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName,
      [NSColor grayColor], NSForegroundColorAttributeName,
      nil];
    
    sShadowColor = WBCGColorCreateGray(0, .80);
  }
}
/* Change default shading */
+ (void)didChangeControlTint:(NSNotification *)notif {
  CGLayerRelease(sBorderShading);
  sBorderShading = nil;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/* If not a mouse down event, start to capture */
- (BOOL)acceptsFirstResponder {
  return YES;
}

- (BOOL)becomeFirstResponder {
  NSEvent *event = [NSApp currentEvent];
  /* If not a mouse down event => trap enabled. */
  /* Event is null if we are the first key view. We want to avoid trap without user interaction */
  if (event && NSEventTypeLeftMouseDown != [event type]) {
    [self setTrapping:YES];
  }
  return YES;
}

- (BOOL)needsPanelToBecomeKey {
  return YES;
}

/* If was trapping, save and stop */
- (BOOL)resignFirstResponder {
  if ([self isTrapping]) {
    [self save];
    [self setTrapping:NO];
  }
  return YES;
}
/* If was trapping, save and stop */
- (void)windowDidResignKey:(NSNotification *)notification {
  if ([self isTrapping]) {
    [self save];
    [self setTrapping:NO];
  }
}

/* HotKey call back:
- First get notification info.
- Then use double tab hack to avoid dead end trap (people that does not use mouse could not like it).
- Save new hotKey and compute display string.
- If trap once, set trapping to false.
*/
- (void)didCatchHotKey:(NSNotification *)aNotification {
  if ([self isTrapping]) {
    NSDictionary *info = [aNotification userInfo];
    uint16_t nkey = (uint16_t)[info[kHKEventKeyCodeKey] integerValue];
    UInt32 nmodifier = (UInt32)[info[kHKEventModifierKey] integerValue];
    /* Anti trap hack. If pressed tab and tab is already saved, stop recording */
    if (se_bhotkey.keycode == kHKVirtualTabKey && (se_bhotkey.modifiers & NSEventModifierFlagDeviceIndependentFlagsMask) == 0 &&
        nkey == se_bhotkey.keycode && nmodifier == se_bhotkey.modifiers) {
      /* Will call -resignFirstResponder */
      [[self window] makeFirstResponder:[self nextValidKeyView]];
    } else {
      se_bhotkey.keycode = nkey;
      se_bhotkey.modifiers = nmodifier;
      se_bhotkey.character = (UniChar)[info[kHKEventCharacterKey] integerValue];

      se_str = [HKKeyMap stringRepresentationForCharacter:se_bhotkey.character modifiers:se_bhotkey.modifiers];
      if (se_htFlags.traponce)
        [self setTrapping:NO];
      else
        [self setNeedsDisplay:YES];
    }
  }
}

/* Track window change to register 'catch hotkey' event and 'resign key' events */
- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
  /* window must be a trapping capable window */
  if (newWindow && ![newWindow respondsToSelector:@selector(setTrapping:)])
    SPXThrowException(NSInvalidArgumentException, @"%@ could not be used in window that does not responds to -setTrapping:", [self class]);
  
  [(id)[self window] setTrapping:NO];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:[self window]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didCatchHotKey:)
                                               name:kHKTrapWindowDidCatchKeyNotification
                                             object:newWindow];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(windowDidResignKey:)
                                               name:NSWindowDidResignKeyNotification
                                             object:newWindow];
}

#pragma mark -
#pragma mark View Drawing

#define kHKTrapHeight        22
#define kHKTrapMinimumWidth  48
#define CAPS_WIDTH           19
#define LEFT_MARGIN          1.5f
#define RIGHT_MARGIN         1.5f

// Prevent from being too small
- (void)setFrameSize:(NSSize)newSize {
  NSSize correctedSize = newSize;
  correctedSize.height = kHKTrapHeight;
  if (correctedSize.width < kHKTrapMinimumWidth) correctedSize.width = kHKTrapMinimumWidth;
  
  [super setFrameSize: correctedSize];
}

- (void)setFrame:(NSRect)frameRect {
  NSRect correctedFrarme = frameRect;
  correctedFrarme.size.height = kHKTrapHeight;
  if (correctedFrarme.size.width < kHKTrapMinimumWidth) correctedFrarme.size.width = kHKTrapMinimumWidth;
  
  [super setFrame: correctedFrarme];
}

- (void)drawRect:(NSRect)frame {
  CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
  CGContextSaveGState(ctxt);
  
  CGContextSetGrayFillColor(ctxt, 1.f, 1.f);
  
  NSRect bounds = [self bounds];
  bounds.size.height = kHKTrapHeight;
  bounds.origin.x = LEFT_MARGIN;
  bounds.size.width = NSWidth(bounds) - (LEFT_MARGIN + RIGHT_MARGIN);
  
  if ([self isTrapping]) {
    /* If trapping, round cell with 2px border and right caps with snapback icon */
    CGMutablePathRef field = CGPathCreateMutable();
    WBCGPathAddRoundRect(field, NULL, CGRectMake(NSMinX(bounds) + 2, 2, NSWidth(bounds) - CAPS_WIDTH, NSHeight(bounds) - 4), (NSHeight(bounds) - 4) / 2);
    CGMutablePathRef border = CGPathCreateMutable();
    WBCGPathAddRoundRect(border, NULL, CGRectMake(NSMinX(bounds), 0, NSWidth(bounds), NSHeight(bounds)), NSHeight(bounds) / 2);
    
    /* Draw white field */
    CGContextBeginPath(ctxt);
    CGContextAddPath(ctxt, field);
    CGContextDrawPath(ctxt, kCGPathFill);
    
    /* we do not want to draw anything outside of the field, so clip */
    CGContextAddPath(ctxt, border);
    CGContextClip(ctxt);
    
    /* we have to clip temporary, so save state */
    CGContextSaveGState(ctxt);
    /* Fill solid border one time with shadow */
    CGContextSetShadowWithColor(ctxt, CGSizeMake(0, -1), 2, sShadowColor);
    
    /* Now we can begin the layer */
    CGContextBeginTransparencyLayer(ctxt, NULL);
    
    CGContextAddPath(ctxt, field);
    CGContextAddPath(ctxt, border);
    CGContextEOClip(ctxt);
    
    if (!sBorderShading)
      sBorderShading = _HKCreateShading(ctxt, [NSColor currentControlTint]);
    
    CGContextDrawLayerInRect(ctxt, NSRectToCGRect(bounds), sBorderShading);
    
    CGContextEndTransparencyLayer(ctxt);
    /* Restore clipping path */
    CGContextRestoreGState(ctxt);
    
    if (se_htFlags.highlight) {
      CGContextSetRGBFillColor(ctxt, 0.2, 0.2, 0.2, 0.35);
      CGContextFillRect(ctxt, NSRectToCGRect(bounds));
    }

    CGContextSaveGState(ctxt);
    CGContextAddPath(ctxt, field);
    CGContextClip(ctxt);
    
    NSString *text = nil;
    NSDictionary *style = sPlaceholderStyle;
    /* Draw string content */
    if (se_htFlags.hint) {
      if (se_htFlags.cancel) {
        NSString *key = [HKKeyMap stringRepresentationForCharacter:_hotKey.character modifiers:_hotKey.modifiers];
        text = key ? [NSString stringWithFormat:NSLocalizedStringFromTable(@"Revert to %@", @"SEHotKeyTrap", @"Revert to - placeholder(%@ => shortcut)"), key] : 
          NSLocalizedStringFromTable(@"Cancel", @"SEHotKeyTrap", @"Cancel - placeholder");
      } else {
//        if (se_character == se_bhotkey.character && se_modifier == se_bhotkey.modifiers && se_keycode == se_bhotkey.keycode) {
//          text = NSLocalizedStringFromTable(@"Cancel", @"SEHotKeyTrap", @"Cancel - placeholder");
//        } else {
        NSString *key = [HKKeyMap stringRepresentationForCharacter:se_bhotkey.character modifiers:se_bhotkey.modifiers];
        text = key ? [NSString stringWithFormat:NSLocalizedStringFromTable(@"Save %@", @"SEHotKeyTrap", @"Save - placeholder (%@ => shortcut)"), key] : 
          NSLocalizedStringFromTable(@"Cancel", @"SEHotKeyTrap", @"Cancel - placeholder");
//        }
      }
    } else if (se_str) {
      text = se_str;
      style = sTextStyle;
    } else {
      // draw placeholder
      text = NSLocalizedStringFromTable(@"Type hotkey", @"SEHotKeyTrap", @"Type HotKey - placeholder");
    }
    CGFloat width = [text sizeWithAttributes:style].width;

    [text drawAtPoint:NSMakePoint(NSMidX(bounds) - (CAPS_WIDTH + width) / 2.0, 4.5) withAttributes:style];
    
    /* Restore clipping path */
    CGContextRestoreGState(ctxt);
    
    CGPathRelease(border);
    CGPathRelease(field);
    
    /* Draw snap back arrow, this is the last step, so we do not have to save state */
    CGContextSetGrayFillColor(ctxt, 1.f, 1.f);
    
    if (se_htFlags.cancel) { /* Draw snap back arrow */
      CGContextTranslateCTM(ctxt, NSMaxX(bounds) - CAPS_WIDTH + 4.5f, 5);
    } else { /* Draw commit arrow */
      CGContextTranslateCTM(ctxt, NSMaxX(bounds) - CAPS_WIDTH + 4.5f, 17);
      CGContextScaleCTM(ctxt, 1, -1);
    }
    CGContextBeginPath(ctxt);
    CGContextMoveToPoint(ctxt, 0, 7.5);
    CGContextAddLineToPoint(ctxt, 4, 3.5);
    CGContextAddLineToPoint(ctxt, 4, 6);
    CGContextAddCurveToPoint(ctxt, 6, 6, 7, 5, 7, 4);
    CGContextAddCurveToPoint(ctxt, 7, 3, 7.5, 0.5, 2, 0);
    CGContextAddCurveToPoint(ctxt, 7, 0, 9, 1.5, 9, 5);
    CGContextAddCurveToPoint(ctxt, 9, 7.2, 7, 9, 4, 9);
    CGContextAddLineToPoint(ctxt, 4, 11.5);
    CGContextClosePath(ctxt);
    CGContextFillPath(ctxt);
  } else {
    /* Draw rounded field with 1px gray border and the delete button if needed. */
    
    /* Draw field with light gray border */
    CGContextSetGrayStrokeColor(ctxt, 0.667, 1);
    CGContextBeginPath(ctxt);
    WBCGContextAddRoundRect(ctxt, CGRectMake(NSMinX(bounds) + 1, 1.5, NSWidth(bounds) - 2, NSHeight(bounds) - 3), (NSHeight(bounds) - 3) / 2);
    CGContextClosePath(ctxt);
    CGContextDrawPath(ctxt, kCGPathFillStroke);
    
    if (![self isEmpty]) {
      // Draw shortcut string
      CGFloat width = [se_str sizeWithAttributes:sTextStyle].width;
      NSPoint point;
      if (se_htFlags.disabled)
        point = NSMakePoint(NSMidX(bounds) - width / 2.0, 4.5);
      else
        point = NSMakePoint(NSMidX(bounds) - (CAPS_WIDTH + width) / 2.0, 4.5);
      [se_str drawAtPoint:point withAttributes:se_htFlags.disabled ? sPlaceholderStyle : sTextStyle];
      
      if (!se_htFlags.disabled) {
        /* Draw round delete button */
        if (se_htFlags.highlight) {
          CGContextSetGrayFillColor(ctxt, 0.542, 1);
        } else {
          CGContextSetGrayFillColor(ctxt, 0.789, 1);
        }
        
        CGContextMoveToPoint(ctxt, NSMaxX(bounds) - 18.5f + 14, 4 + 7);
        CGContextAddArc(ctxt, NSMaxX(bounds) - 18.5f + 7, 4 + 7, 7, 0, 2 * M_PI, true);
        //CGContextAddEllipseInRect(ctxt, CGRectMake(NSMaxX(bounds) - 18.5f, 4, 14, 14));
        CGContextFillPath(ctxt);
        
        CGFloat length = 3;
        CGContextTranslateCTM(ctxt, NSMaxX(bounds) - 11.5f, 11);
        
        CGContextSetLineWidth(ctxt, 1.25);
        CGContextSetGrayStrokeColor(ctxt, 1, 1);
        
        CGContextMoveToPoint(ctxt, -length, -length);
        CGContextAddLineToPoint(ctxt, length, length);
        CGContextMoveToPoint(ctxt, length, -length);
        CGContextAddLineToPoint(ctxt, -length, length);
        CGContextStrokePath(ctxt);
      }
    } else {
      // draw placeholder
      NSString *placeholder = NSLocalizedStringFromTable(@"click to edit", @"SEHotKeyTrap", @"click to edit - placeholder");
      CGFloat width = [placeholder sizeWithAttributes:sPlaceholderStyle].width;
      [placeholder drawAtPoint:NSMakePoint(NSMidX(bounds) - width / 2.f, 4.5) withAttributes:sPlaceholderStyle];
    }
  }
  CGContextRestoreGState(ctxt);
}

- (void)clear {
  if (!se_htFlags.trap) {
    se_str = nil;
    _hotKey.character = kHKNilUnichar;
    _hotKey.keycode = kHKInvalidVirtualKeyCode;
    [self setNeedsDisplay:YES];
  }
}

- (void)keyDown:(NSEvent *)theEvent {
  NSInteger modifiers = [theEvent modifierFlags] & SEValidModifiersFlags;
  unichar chr = [[theEvent characters] length] > 0 ? [[theEvent characters] characterAtIndex:0] : 0;
  /* navigation */
  switch (chr) {
    case 25: // END OF MEDIUM (aka backtab) ?
    case '\t':
      if (modifiers == 0) {
        [[self window] makeFirstResponder:[self nextValidKeyView]];
        return;
      } else if ((modifiers & NSEventModifierFlagShift) == NSEventModifierFlagShift) {
        [[self window] makeFirstResponder:[self previousValidKeyView]];
        return;
      }
      break;
  }
  if (([theEvent modifierFlags] & SEValidModifiersFlags) == 0 && chr) {
    if (se_htFlags.trap) {
      switch (chr) {
        case '\e':
          /* No modifier and cancel pressed */
          [self revert];
          [self setTrapping:NO];
          return;
        case '\r':
        case 0x03:
          [self save];
          [self setTrapping:NO];
          return;
      }
    } else {
      switch (chr) {
        /* Delete */
        case 0x007f:
        case NSDeleteFunctionKey:
          [self clear];
          [self setNeedsDisplay:YES];
          return;
          /* Space */
        case ' ':
          [self setTrapping:YES];
          return;
      }
    }
  }
  [super keyDown:theEvent];
}

- (IBAction)validate:(id)sender {
  if (se_htFlags.trap) {
    [self save];
    [self setTrapping:NO];
  }
}

- (IBAction)cancel:(id)sender {
  if (se_htFlags.trap) {
    [self revert];
    [self setTrapping:NO];
  }
}
- (IBAction)delete:(id)sender {
  if (!se_htFlags.trap && ![self isEmpty]) {
    [self clear];
  }
}

#pragma mark -
#pragma mark Event Handling
- (void)setHotKey:(SEHotKey)anHotkey {
  _hotKey = anHotkey;
  se_bhotkey = anHotkey;
  /* Update string representation */
  se_str = [HKKeyMap stringRepresentationForCharacter:_hotKey.character modifiers:_hotKey.modifiers];
  /* Refresh */
  [self setNeedsDisplay:YES];
}

- (BOOL)isEnabled {
  return se_htFlags.disabled == 0;
}
- (void)setEnabled:(BOOL)flag {
  SPXFlagSet(se_htFlags.disabled, !flag);
}

- (BOOL)isEmpty {
  return se_str == nil;
}

- (BOOL)isInButtonRect:(NSPoint)point {
  NSRect button = NSZeroRect;
  if ([self isTrapping]) {
    button = NSMakeRect(NSWidth([self bounds]) - CAPS_WIDTH + 4, 2, CAPS_WIDTH - 4, kHKTrapHeight - 4);    
  } else if (![self isEmpty]) {
    button = NSMakeRect(NSWidth([self bounds]) - 20, 4, 14, 14);
  }
  return [self mouse:point inRect:button];
}

- (void)save {
  _hotKey = se_bhotkey;
  [NSApp sendAction:_action to:_target from:self];
}

- (void)revert {
  se_str = [HKKeyMap stringRepresentationForCharacter:_hotKey.character modifiers:_hotKey.modifiers];
}

- (BOOL)isTrapping {
  return se_htFlags.trap;
}

- (void)setTrapping:(BOOL)flag {
  BOOL trap = se_htFlags.trap;
  if (!se_htFlags.disabled && spx_xor(flag, trap)) {
    SPXFlagSet(se_htFlags.trap, flag);
    if (se_htFlags.trap) {
      NSAssert([[self window] firstResponder] == self, @"Must be first responder");
      se_bhotkey = _hotKey; /* init edited value */
      NSPoint mouse = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
      se_htFlags.hint = [self isInButtonRect:mouse] ? 1 : 0;
      se_tracker = [self addTrackingRect:NSMakeRect(NSWidth([self bounds]) - CAPS_WIDTH + 4, 2, CAPS_WIDTH - 4, kHKTrapHeight - 4)
                                owner:self userData:nil assumeInside:se_htFlags.hint];
    } else {
      [self removeTrackingRect:se_tracker];
    }
    [self setNeedsDisplay:YES];
    [(id)[self window] setTrapping:flag];
  }
}

- (void)mouseEntered:(NSEvent *)theEvent {
  se_htFlags.hint = 1;
  [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)event {
  se_htFlags.hint = 0;
  [self setNeedsDisplay:YES];
}

- (void)highlight:(BOOL)flag {
  BOOL highlight = se_htFlags.highlight;
  if (spx_xor(flag, highlight)) {
    SPXFlagSet(se_htFlags.highlight, flag);
    [self setNeedsDisplay:YES];
  }
}

- (void)mouseClick:(NSEvent *)theEvent {
  NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  BOOL inButton = [self isInButtonRect:mouseLoc];
  if (se_htFlags.inbutton && inButton) {
    if (![self isTrapping]) {
      [self clear];
    } else {
      /* Check if we use cancel mode */
      if (se_htFlags.cancel) {
        [self revert];
      } else {
        [self save];
      }
      [self setTrapping:NO];
    }
  } else if (!se_htFlags.inbutton && !inButton) {
    if (![self isTrapping]) {
      [self setTrapping:YES];
    } else {
      [self save];
      [self setTrapping:NO];
    }  
  }
}

- (void)mouseDown:(NSEvent *)theEvent {
  if (se_htFlags.disabled)
    return;
  
  BOOL keepOn = YES;
  BOOL isInside = YES;
  NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  se_htFlags.inbutton = [self isInButtonRect:mouseLoc];
  if (se_htFlags.inbutton)
    [self highlight:YES];
  
  while (keepOn) {
    theEvent = [[self window] nextEventMatchingMask: NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged];
    mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    isInside = [self mouse:mouseLoc inRect:[self bounds]];
    
    switch ([theEvent type]) {
      case NSEventTypeLeftMouseDragged:
        [self highlight:se_htFlags.inbutton && [self isInButtonRect:mouseLoc]];
        break;
      case NSEventTypeLeftMouseUp:
        if (isInside) [self mouseClick:theEvent];
        [self highlight:NO];
        keepOn = NO;
        break;
      default:
        /* Ignore any other kind of event. */
        break;
    }
  };
  
  return;
}

@end

#pragma mark -
#pragma mark Shading Support
static const 
WBGradientDefinition sAquaShadingInfo = {
  kWBGradientColorSpace_RGB,
  kWBInterpolationLinear,
  {
    {
      1,
      WBGradientColorRGB(.0, .320, .810, 1),
      WBGradientColorRGB(.300, .600, .945, 1),
      kWBInterpolationDefault
    }
  },
};

static const 
WBGradientDefinition sGraphiteShadingInfo = {
  kWBGradientColorSpace_RGB,
  kWBInterpolationLinear,
  {
    {
      1,
      WBGradientColorRGB(.310, .400, .510, 1),
      WBGradientColorRGB(.550, .600, .700, 1),
      kWBInterpolationDefault
    }
  },
};

CGLayerRef _HKCreateShading(CGContextRef ctxt, NSControlTint tint) {
  const WBGradientDefinition *info = NULL;
  switch (tint) {
    case NSGraphiteControlTint:
      info = &sGraphiteShadingInfo;
      break;
    case NSBlueControlTint:
    default:
      info = &sAquaShadingInfo;
      break;
  }

  WBGradientBuilder *builder = [[WBGradientBuilder alloc] initWithDefinition:info];
  return [builder newLayerWithVerticalGradient:kHKTrapHeight context:ctxt];
}

@implementation SEHotKeyTrap (NSAccessibility)

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
  return @[NSAccessibilityConfirmAction, NSAccessibilityCancelAction, NSAccessibilityDeleteAction];
}

- (NSString *)accessibilityActionDescription:(NSString *)action {
  return NSAccessibilityActionDescription(action);
}

- (void)accessibilityPerformAction:(NSString *)action {
  if ([action isEqualToString:NSAccessibilityConfirmAction]) {
    if (se_htFlags.trap) {
      [self validate:nil];
    } else {
      [self setTrapping:YES];
    }
  } else if ([action isEqualToString:NSAccessibilityCancelAction]) {
    [self cancel:nil];
  } else if ([action isEqualToString:NSAccessibilityDeleteAction]) {
    [self delete:nil];
  } else {
    [super accessibilityPerformAction:action];
  }
}

- (NSArray *)accessibilityAttributeNames {
  NSMutableArray *attr = [[super accessibilityAttributeNames] mutableCopy];
  if (![attr containsObject:NSAccessibilityValueAttribute])
    [attr addObject:NSAccessibilityValueAttribute];
  if (![attr containsObject:NSAccessibilitySelectedAttribute])
    [attr addObject:NSAccessibilitySelectedAttribute];
  return attr;
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
  if ([attribute isEqualToString:NSAccessibilityRoleAttribute])
    return @"SparkHotKeyFieldRole";
  else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute])
    return @"hotkey field";
  else if ([attribute isEqualToString:NSAccessibilityValueAttribute]) {
    if (se_htFlags.trap) {
      return [HKKeyMap speakableStringRepresentationForCharacter:se_bhotkey.character modifiers:se_bhotkey.modifiers];
    } else if (![self isEmpty]) {
      return [HKKeyMap speakableStringRepresentationForCharacter:_hotKey.character modifiers:_hotKey.modifiers];
    } else {
      return nil;
    }
  } else if ([attribute isEqualToString:NSAccessibilityHelpAttribute]) {
    if (se_htFlags.trap) 
      return @"type a keystroke combination and confirm to save it";
    else
      return @"confirm to edit keystroke combination";
  } else if ([attribute isEqualToString:NSAccessibilitySelectedAttribute]) {
    return @(se_htFlags.trap != 0);
  }
  else return [super accessibilityAttributeValue:attribute];
}

@end

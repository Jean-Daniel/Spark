/*
 *  SETableView.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SETableView.h"

#import <ShadowKit/SKCGFunctions.h>

NSString * const SETableSeparator = @"-\e";

@implementation SETableViewCell

static 
NSShadow *sHighlightShadow = nil;

+ (void)initialize {
  if ([SETableViewCell class] == self) {
    sHighlightShadow = [[NSShadow alloc] init];
    [sHighlightShadow setShadowColor:[NSColor colorWithCalibratedWhite:.35 alpha:.5]];
    [sHighlightShadow setShadowOffset:NSMakeSize(0, -1)];
    [sHighlightShadow setShadowBlurRadius:0];
  }
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  if ([[self title] isEqualToString:SETableSeparator]) {
    [[NSColor lightGrayColor] setStroke];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(cellFrame), NSMidY(cellFrame)) 
                              toPoint:NSMakePoint(NSMaxX(cellFrame), NSMidY(cellFrame))];
  } else {
    if ([self isHighlighted]) {
      [[NSGraphicsContext currentContext] saveGraphicsState];
      [sHighlightShadow set];
      [self setTextColor:[NSColor whiteColor]];
      [super drawWithFrame:cellFrame inView:controlView];
      [self setTextColor:[NSColor controlTextColor]];
      [[NSGraphicsContext currentContext] restoreGraphicsState];
    } else {
      [super drawWithFrame:cellFrame inView:controlView];
    }
  }
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  return nil;
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength {
  [self setTextColor:[NSColor blackColor]];
  [super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

@end

@implementation SETableView

- (NSImage *)highlightedCellColor {
  static NSImage *highlighted = nil;
  if (!highlighted) {
    highlighted = [[NSImage imageNamed:@"Highlight"] retain];
    [highlighted setFlipped:YES];
  }
  if (!se_highlight) {
    [self setHighlightShading:[NSColor colorWithCalibratedRed:.340f
                                                        green:.606f
                                                         blue:.890f
                                                        alpha:1]
                       bottom:[NSColor colorWithCalibratedRed:0
                                                        green:.312f
                                                         blue:.790f
                                                        alpha:1]
                       border:[NSColor colorWithCalibratedRed:.239f
                                                        green:.482f
                                                         blue:.855f
                                                        alpha:1]];
  }
  return ([[self window] isKeyWindow] && [[self window] firstResponder] == self) ? se_highlight : highlighted;
}

- (void)setHighlightShading:(NSColor *)aColor bottom:(NSColor *)end border:(NSColor *)border {
  SKSimpleShadingInfo ctxt;
  [[aColor colorUsingColorSpaceName:NSDeviceRGBColorSpace] getRed:&ctxt.start[0] green:&ctxt.start[1] blue:&ctxt.start[2] alpha:&ctxt.start[3]];
  [[end colorUsingColorSpaceName:NSDeviceRGBColorSpace] getRed:&ctxt.end[0] green:&ctxt.end[1] blue:&ctxt.end[2] alpha:&ctxt.end[3]];
  NSImage *img = SKCGCreateVerticalShadingImage(64, [self rowHeight] + 2, SKCGSimpleShadingFunction, &ctxt);
  
  if (border) {
    [img lockFocus];
    [border setStroke];
    float y = 0.5;
    [NSBezierPath strokeLineFromPoint:NSMakePoint(0, y) toPoint:NSMakePoint(64, y)];
    [img unlockFocus];
  }
  
  se_highlight = [img retain];
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
  NSImage *img = [self highlightedCellColor];
  NSRect imgRect = NSZeroRect;
  imgRect.size = [img size];
  [img drawInRect:[self rectOfRow:[self selectedRow]] fromRect:imgRect operation:NSCompositeSourceOver fraction:1];
}

/* Nasty private override */
- (void)_drawDropHighlightOnRow:(int)row {
  /* As it is a private method, we have to avoid recursive call,
  even if it does not occured actually */
  if (!se_lock) {
    se_lock = YES;
    CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(ctxt);
    
    CGRect rect = CGRectFromNSRect([self rectOfRow:row]);
    CGContextClipToRect(ctxt, rect);
    rect.origin.x += 1;
    rect.origin.y += 1;
    rect.size.width -= 2;
    rect.size.height -= 2;
    
    /* draw background */
    SKCGContextAddRoundRect(ctxt, rect, 5);
    CGContextSetRGBFillColor(ctxt, 0.027f, 0.322f, 0.843f, .15f);
    CGContextFillPath(ctxt);
    
    SKCGContextAddRoundRect(ctxt, rect, 5);
    CGContextSetRGBStrokeColor(ctxt, 0.027f, 0.322f, 0.843f, 1);
    CGContextSetLineWidth(ctxt, 2);
    CGContextStrokePath(ctxt);
    
    CGContextRestoreGState(ctxt);
    se_lock = NO;
  }
}

- (void)textDidEndEditing:(NSNotification *)aNotification {
  NSString *text = [[aNotification object] string];
  /* Notify data source */
  if (SKDelegateHandle([self dataSource], tableView:setObjectValue:forTableColumn:row:))
    [[self dataSource] tableView:self
                  setObjectValue:text
                  forTableColumn:[[self tableColumns] objectAtIndex:0]
                             row:[self editedRow]];
  
  [[[[self tableColumns] objectAtIndex:0] dataCell] endEditing:[aNotification object]];
  [[self window] makeFirstResponder:self];
  /* Reload change */
  [self reloadData];
}

@end

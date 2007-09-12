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

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
  [self setTextColor:[NSColor blackColor]];
  [super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

@end

@implementation SETableView

- (void)dealloc {
  CGLayerRelease(se_highlight);
  [super dealloc];
}

static const 
SKSimpleShadingInfo sHighlightShadingInfo = {
  {.659, .718, .804, 1},
  {.610, .680, .770, 1},
  NULL,
};

- (CGLayerRef)highlightedCellColor {
  static CGLayerRef sHighlighted = nil;
  if (!sHighlighted) {
    CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
    sHighlighted = SKCGCreateVerticalShadingLayer(ctxt, CGSizeMake(64, [self rowHeight] + 2), SKCGSimpleShadingFunction, (void *)&sHighlightShadingInfo);
    CGContextRef gctxt = CGLayerGetContext(sHighlighted);
    /* up line */
    CGContextSetRGBStrokeColor(gctxt, .686, .741, .820, 1);
    CGPoint line[2] = {{0, .5}, {64, .5}};
    CGContextStrokeLineSegments(gctxt, line, 2);
    /* bottom line */
    CGContextSetRGBStrokeColor(gctxt, .588, .651, .745, 1);
    CGPoint line2[] = {{0, [self rowHeight] + 1.5}, {64, [self rowHeight] + 1.5}};
    CGContextStrokeLineSegments(gctxt, line2, 2);
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
  return ([[self window] isKeyWindow] && [[self window] firstResponder] == self) ? se_highlight : sHighlighted;
}

- (void)setHighlightShading:(NSColor *)aColor bottom:(NSColor *)end border:(NSColor *)border {
  SKSimpleShadingInfo ctxt;
  ctxt.fct = NULL;
  [[aColor colorUsingColorSpaceName:NSDeviceRGBColorSpace] getRed:&ctxt.start[0] green:&ctxt.start[1] blue:&ctxt.start[2] alpha:&ctxt.start[3]];
  [[end colorUsingColorSpaceName:NSDeviceRGBColorSpace] getRed:&ctxt.end[0] green:&ctxt.end[1] blue:&ctxt.end[2] alpha:&ctxt.end[3]];
  se_highlight = SKCGCreateVerticalShadingLayer([[NSGraphicsContext currentContext] graphicsPort], 
                                                CGSizeMake(64, [self rowHeight] + 2), SKCGSimpleShadingFunction, &ctxt);
  
  CGFloat r, g, b, a;
  [[border colorUsingColorSpaceName:NSDeviceRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
  CGContextRef gctxt = CGLayerGetContext(se_highlight);
  CGContextSetRGBStrokeColor(gctxt, r, g, b, a);
  CGPoint line[2] = {{0, .5}, {64, .5}};
  CGContextStrokeLineSegments(gctxt, line, 2);
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
  CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
  CGContextDrawLayerInRect(ctxt, CGRectFromNSRect([self rectOfRow:[self selectedRow]]), [self highlightedCellColor]);
}

/* Nasty private override */
- (void)_drawDropHighlightOnRow:(NSInteger)row {
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

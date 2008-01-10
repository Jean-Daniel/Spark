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
  [super dealloc];
}

static const 
SKCGSimpleShadingInfo sHighlightShadingInfo = {
  {.443, .522, .671, 1},
  {.651, .690, .812, 1},
  NULL,
};

static const
SKCGSimpleShadingInfo sFocusShadingInfo = {
  {.000, .312, .790, 1},
  {.340, .606, .890, 1},
  NULL,
};

- (CGLayerRef)highlightedCellColor {
  static CGLayerRef sHasFocus = nil;
  static CGLayerRef sHighlighted = nil;
  if (!sHighlighted) {
    sHighlighted = SKCGLayerCreateWithVerticalShading([[NSGraphicsContext currentContext] graphicsPort],
                                                      CGSizeMake(64, [self rowHeight] + 2), true, 
                                                      SKCGShadingSimpleShadingFunction, &sHighlightShadingInfo);
    /* border-top */
    CGContextRef gctxt = CGLayerGetContext(sHighlighted);
    CGContextSetRGBStrokeColor(gctxt, .509, .627, .753, 1);
    CGPoint line[2] = {{0, .5}, {64, .5}};
    CGContextStrokeLineSegments(gctxt, line, 2);
  }
  if (!sHasFocus) {
    sHasFocus = SKCGLayerCreateWithVerticalShading([[NSGraphicsContext currentContext] graphicsPort], 
                                                   CGSizeMake(64, [self rowHeight] + 2), true, 
                                                   SKCGShadingSimpleShadingFunction, &sFocusShadingInfo);
    /* border-top */
    CGContextRef gctxt = CGLayerGetContext(sHasFocus);
    CGContextSetRGBStrokeColor(gctxt, .271, .502, .784, 1);
    CGPoint line[2] = {{0, .5}, {64, .5}};
    CGContextStrokeLineSegments(gctxt, line, 2);
  }
  return ([[self window] isKeyWindow] && [[self window] firstResponder] == self) ? sHasFocus : sHighlighted;
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
  CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
  CGRect rect = NSRectToCGRect([self rectOfRow:[self selectedRow]]);
  CGContextDrawLayerInRect(ctxt, rect, [self highlightedCellColor]);
}

/* Nasty private override */
- (void)_drawDropHighlightOnRow:(NSInteger)row {
  /* As it is a private method, we have to avoid recursive call,
  even if it does not occured actually */
  if (!se_lock) {
    se_lock = YES;
    CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(ctxt);
    
    CGRect rect = NSRectToCGRect([self rectOfRow:row]);
    CGContextClipToRect(ctxt, rect);
    rect = CGRectInset(rect, 1, 1);
    
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

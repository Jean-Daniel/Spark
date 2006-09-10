/*
 *  SETableView.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import "SETableView.h"

#import <ShadowKit/SKCGFunctions.h>

NSString * const SETableSeparator = @"-\e";

@implementation SETableViewCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  if ([[self title] isEqualToString:SETableSeparator]) {
    [[NSColor lightGrayColor] setStroke];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(cellFrame), NSMidY(cellFrame)) 
                              toPoint:NSMakePoint(NSMaxX(cellFrame), NSMidY(cellFrame))];
  } else {
    if ([self isHighlighted]) {
      cellFrame.origin.y++;
      [self setTextColor:[NSColor colorWithDeviceWhite:0.35 alpha:.5]];
      [super drawWithFrame:cellFrame inView:controlView];
      
      cellFrame.origin.y--;
      [self setTextColor:[NSColor whiteColor]]; 
      [super drawWithFrame:cellFrame inView:controlView];
    } else {
      [self setTextColor:[NSColor blackColor]];
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
  @synchronized ([SETableView class]) {
    if (nil == highlighted) {
      highlighted = [[NSImage imageNamed:@"Highlight"] retain];
      [highlighted setFlipped:YES];
    }
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

#if 0
//- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns
//                                   event:(NSEvent*)dragEvent offset:(NSPointPointer)dragImageOffset {
- (NSImage *)dragImageForRows:(NSArray *)dragRows event:(NSEvent *)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset {
  NSImage *anImage = [super dragImageForRows:dragRows event:dragEvent dragImageOffset:dragImageOffset];
  
  NSArray *columns = [self tableColumns];
  if ([columns count] < 2)
    return anImage;
  
  float width = [[columns objectAtIndex:0] width];
  width += [[columns objectAtIndex:1] width];
  dragImageOffset->x = 0;
  NSSize size = NSMakeSize(width+1, [anImage size].height +1);
  [anImage setSize:size];
  
  int count = [dragRows count];
  int i;
  float offset = MAXFLOAT;
  for (i=0; i<count; i++) {
    offset = MIN(NSMinY([self rectOfRow:[[dragRows objectAtIndex:i] intValue]]), offset);
  }
  offset--;
  [anImage lockFocus];
  [NSBezierPath setDefaultLineWidth:0];
  [[NSGraphicsContext currentContext] setShouldAntialias:NO];  
  [[NSColor colorWithCalibratedWhite:0.80 alpha:0.45] setFill];
  [[NSColor grayColor] setStroke];
  for (i=0; i<count; i++) {
    NSRect imgRect = [self rectOfRow:[[dragRows objectAtIndex:i] intValue]];
    imgRect.size.width = width;
    imgRect.size.height -= 2;
    imgRect.origin.y -= offset;
    imgRect.origin.y = [anImage size].height - imgRect.origin.y - NSHeight(imgRect);
    
    [NSBezierPath fillRect:imgRect];
    //    NSRectFillUsingOperation(imgRect, NSCompositeDestinationOver);
    [NSBezierPath strokeRect:imgRect];    
  }
  [anImage unlockFocus];
  return anImage;
}
#endif

@end

//
//  CustomToolbar.m
//  Spark Editor
//
//  Created by Fox on 17/08/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "CustomToolbar.h"

@implementation CustomToolbar

- (void)drawRect:(NSRect)rect {
  [[NSColor colorWithPatternImage:[NSImage imageNamed:@"Toolbar"]] set];
  NSRectFill([self bounds]);
}

@end

@implementation ToolbarButtonCell

- (id)initWithCoder:(NSCoder *)decoder {
  if (self = [super initWithCoder:decoder]) {
    [self setShowsStateBy:NSNoCellMask];
    [self setHighlightsBy:NSContentsCellMask];
  }
  return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  if ([self state] == NSOnState) {
    NSPoint p1, p2;
    p1 = NSMakePoint(NSMaxX(cellFrame) -1, NSMinY(cellFrame));
    p2 = NSMakePoint(NSMaxX(cellFrame) -1, NSMaxY(cellFrame));

    id context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];
    [context setShouldAntialias:NO];
    [NSBezierPath setDefaultLineWidth:1];
    [[NSColor colorWithCalibratedRed:0.65f green:0.65f blue:0.65f alpha:0.90f] setStroke];

    [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
    p1.x = p2.x = NSMinX(cellFrame);
    [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
    
    [context restoreGraphicsState];
  }
  [super drawWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  if ([self state] == NSOnState) {
    NSRect frame = cellFrame;
    frame.size.width -= 2;
    frame.origin.x += 1;
    [[NSColor colorWithCalibratedRed:0.87f green:0.87f blue:0.87f alpha:0.95f] set];
    NSRectFill(frame);
  }
  [super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
/*
 *  SETriggerCell.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "SETriggerCell.h"

@implementation SETriggerCell

- (void)setDrawLineOver:(BOOL)flag {
  se_line = flag;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  [super drawInteriorWithFrame:cellFrame inView:controlView];
  
  if (se_line) {
    float twidth = [[self title] sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
      [self font], NSFontAttributeName, nil]].width;
    
    float y = NSMinY(cellFrame) + 7.5f;
    twidth = MIN(NSWidth(cellFrame) - 4, twidth + 2);
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(cellFrame) + 2, y) toPoint:NSMakePoint(NSMinX(cellFrame) + twidth, y)];
  }
}

@end

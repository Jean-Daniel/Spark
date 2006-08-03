//
//  SETriggerCell.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 03/08/06.
//  Copyright 2006 Adamentium. All rights reserved.
//

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
    twidth = MIN(NSWidth(cellFrame) - 4, twidth + 1);
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(cellFrame) + 2, y) toPoint:NSMakePoint(NSMinX(cellFrame) + twidth, y)];
  }
}

@end

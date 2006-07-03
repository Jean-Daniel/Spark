//
//  Extension.m
//  Spark
//
//  Created by Fox on Mon Jan 12 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "CustomTableView.h"
#import <HotKeyToolKit/HotKeyToolKit.h>

NSString * const kCustomTableViewDidBecomeFirstResponder = @"CustomTableViewDidBecomeFirstResponder";

@implementation CustomTableView

- (BOOL)becomeFirstResponder {
  if ([super becomeFirstResponder]) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kCustomTableViewDidBecomeFirstResponder object:self];
    return YES;
  }
  return NO;
}

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

@end

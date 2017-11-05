//
//  SESeparatorCellView.m
//  Spark
//
//  Created by Jean-Daniel on 03/11/2017.
//

#import "SESeparatorCellView.h"

NSString * const SETableSeparator = @"-\e";

@implementation SESeparatorCellView

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];
  [NSColor.lightGrayColor setFill];
  NSRectFill(dirtyRect);
}

@end

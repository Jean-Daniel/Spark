//
//  SETableView.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 07/07/06.
//  Copyright 2006 Shadow Lab. All rights reserved.
//

#import "SETableView.h"

@implementation SETableViewCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
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
  static NSImage *highlighted = nil, *highlightedH = nil;
  @synchronized ([SETableView class]) {
    if (nil == highlighted) {
      highlighted = [[NSImage imageNamed:@"Highlight"] retain];
      [highlighted setFlipped:YES];
      highlightedH = [[NSImage imageNamed:@"HighlightFocus"] retain];
      [highlightedH setFlipped:YES];
    }
  }
  return ([[self window] isKeyWindow] && [[self window] firstResponder] == self) ? highlightedH : highlighted;
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
  NSImage *img = [self highlightedCellColor];
  NSRect imgRect = NSZeroRect;
  imgRect.size = [img size];
  [img drawInRect:[self rectOfRow:[self selectedRow]] fromRect:imgRect operation:NSCompositeSourceOver fraction:1];
}

- (void)textDidEndEditing:(NSNotification *)aNotification {
  //[super textDidEndEditing:aNotification];
  NSString *text = [[aNotification object] string];
  [[self dataSource] tableView:self
                setObjectValue:text
                forTableColumn:[[self tableColumns] objectAtIndex:0]
                           row:[self editedRow]];
  
  [[[[self tableColumns] objectAtIndex:0] dataCell] endEditing:[aNotification object]];
  [[self window] makeFirstResponder:self];
  [self reloadData];
  
//  [self setNeedsDisplayInRect:[self rectOfRow:[self selectedRow]]];
  //[self selectRow:[self selectedRow] byExtendingSelection:NO];  
}

@end

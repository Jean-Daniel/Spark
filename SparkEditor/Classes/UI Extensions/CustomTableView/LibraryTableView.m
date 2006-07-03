//
//  LibrarySortDecriptor.m
//  Spark
//
//  Created by Fox on Sat Jan 10 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "LibraryTableView.h"
#import "KeyLibraryList.h"
#import "ActionPlugInList.h"

@interface ListTableHeaderCell : NSTableHeaderCell {
}

+ (NSImage *)headerCellColor;

@end

@interface ListeTableCornerView : NSView {
}
@end

@implementation ListeTableCornerView

- (void)drawRect:(NSRect)frame {
  id image = [ListTableHeaderCell headerCellColor];
  if (image) {
    NSRect dest = [self frame];
    dest.origin = NSZeroPoint;
    [image drawInRect:dest fromRect:NSMakeRect(0, 0, [image size].width, [image size].height) operation:NSCompositeSourceAtop fraction:1];
  }
}

- (BOOL)isFlipped {
  return YES;
}

@end

@implementation ListTableHeaderCell 

- (void)mouseDown:(NSEvent *)theEvent {
}

+ (NSImage *)headerCellColor {
  static NSImage *img = nil;
  if (nil == img) {
    img = [NSImage imageNamed:@"HeaderCell"];
  }
  return img;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  id image = [ListTableHeaderCell headerCellColor];
  if (image) {
    [image drawInRect:cellFrame fromRect:NSMakeRect(0, 0, [image size].width, [image size].height) operation:NSCompositeSourceAtop fraction:1];
  }
  [super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end

@implementation ListTableCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  [self setTextColor:[self isHighlighted] ? [NSColor whiteColor] : [NSColor blackColor]];
  [super drawWithFrame:cellFrame inView:controlView];
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  return nil;
}

@end

@implementation ListTableView

- (void)swizzleHeaderCell {
  id items = [[self tableColumns] objectEnumerator];
  id col;
  while (col = [items nextObject]) {
    id cell = [col headerCell];
    
    SKSwizzleIsaPointer(cell, [ListTableHeaderCell class]);
  }
}

- (void)awakeFromNib {
  [self swizzleHeaderCell];
  [self setCornerView:[[[ListeTableCornerView alloc] init] autorelease]];
}

- (NSImage *)highlightedCellColor {
  static NSImage *highlighted = nil, *highlightedH = nil;
  @synchronized ([self class]) {
    if (nil == highlighted) {
      highlighted = [[NSImage imageNamed:@"ListHighlight"] retain];
      highlightedH = [[NSImage imageNamed:@"ListHighlight_h"] retain];
    }
  }
  return ([[self window] isKeyWindow] && [[self window] firstResponder] == self) ? highlightedH : highlighted;
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
  id img = [self highlightedCellColor];
  NSRect imgRect = NSZeroRect;
  imgRect.size = [img size];
  [img drawInRect:[self rectOfRow:[self selectedRow]] fromRect:imgRect operation:NSCompositeSourceAtop fraction:1];
}

@end

@implementation LibraryTableView

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
  unsigned int op = NSDragOperationDelete;
  if (isLocal) {
    op = NSDragOperationCopy | NSDragOperationGeneric | NSDragOperationMove | NSDragOperationDelete;
  }
  return op;
}

- (void)dragImage:(NSImage *)anImage at:(NSPoint)imageLoc offset:(NSSize)mouseOffset event:(NSEvent *)theEvent pasteboard:(NSPasteboard *)pboard source:(id)sourceObject slideBack:(BOOL)slideBack {
  [super dragImage:anImage at:imageLoc offset:mouseOffset event:theEvent pasteboard:pboard source:sourceObject slideBack:NO];
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
  if (operation == NSDragOperationNone) {
    NSShowAnimationEffect(NSAnimationEffectPoof, //NSAnimationEffectDisappearingItemDefault,
                          [NSEvent mouseLocation],
                          NSZeroSize,
                          nil, nil, nil);
  }
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
  int row;
  if ( (row = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]]) != -1) {
    [self selectRow:row byExtendingSelection:NO];
  }
  return [super menuForEvent:theEvent];
}

@end

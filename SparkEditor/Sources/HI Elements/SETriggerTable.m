/*
 *  SETriggerTable.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SETriggerTable.h"

#import <WonderBox/WBIndexSetIterator.h>

@implementation SETriggerTable

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
  if (NSDraggingContextWithinApplication == context) {
    return NSDragOperationCopy | NSDragOperationGeneric | NSDragOperationMove | NSDragOperationDelete;
  } 
  return NSDragOperationNone;
}

- (void)mouseDown:(NSEvent *)anEvent {
  if ([anEvent clickCount] == 2) {
    NSInteger row = [self rowAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil]];
    if (row != -1) {
      id target = [self target];
      SEL doubleAction = [self doubleAction];
      [self sendAction:doubleAction to:target];
    }
  } else if ([anEvent clickCount] == 1 && ([anEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSAlternateKeyMask) {
    if (SPXDelegateHandle([self delegate], tableView:shouldHandleOptionClick:) && ![[self delegate] tableView:self shouldHandleOptionClick:anEvent]) {
      // do nothing
    } else {
      [super mouseDown:anEvent];
    }
  } else {
    [super mouseDown:anEvent];
  }
}

- (void)keyDown:(NSEvent *)anEvent {
  if (([anEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) == 0) {
    NSString *chr = [anEvent characters];
    if ([chr isEqualToString:@" "] && SPXDelegateHandle([self delegate], spaceDownInTableView:)) {
      [[self delegate] spaceDownInTableView:self];
      return;
    }
  }
  [super keyDown:anEvent];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
  return [menuItem action] == @selector(selectAll:);
}

//- (void)dragImage:(NSImage *)anImage at:(NSPoint)imageLoc offset:(NSSize)mouseOffset event:(NSEvent *)theEvent pasteboard:(NSPasteboard *)pboard source:(id)sourceObject slideBack:(BOOL)slideBack {
//  WBTrace();
//  if (!_isDragging) { /* First Enter */
//    _isDragging = YES;
//    _dragImg = anImage;
//    NSRect rect = NSMakeRect(imageLoc.x, imageLoc.y, 0, 0);
//    [self dragPromisedFilesOfTypes:[NSArray arrayWithObject:@"pdf"] fromRect:rect source:sourceObject slideBack:slideBack event:theEvent]; 
//  } else { /* second Enter */
//    SPXDebug(@"%@", [pboard types]);
//    [super dragImage:(_dragImg ? _dragImg : anImage) at:imageLoc offset:mouseOffset event:theEvent pasteboard:pboard source:sourceObject slideBack:slideBack];
//    _isDragging = NO;
//    _dragImg = nil;
//  }
//}

- (NSImage *)badgeWithCount:(NSUInteger)count {
  NSImage *img = nil;
  if (count < 100) {
    img = [NSImage imageNamed:@"badge-1&2"];
  }
  else if (count > 100 && count < 1000) {
    img = [NSImage imageNamed:@"badge-3"];
  }
  else if (count > 1000 && count < 10000) {
    img = [NSImage imageNamed:@"badge-4"];
  }
  else if (count > 10000) {
    img = [NSImage imageNamed:@"badge-5"];
  }
  NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor whiteColor], NSForegroundColorAttributeName,
    [NSFont systemFontOfSize:12], NSFontAttributeName, nil];
  NSString *str = [NSString stringWithFormat:@"%ld", (long)count];
  NSSize size = [str sizeWithAttributes:attr];
  /* backup image before edit */
  img = [[img copy] autorelease];
  if (img) {
    CGFloat x = ([img size].width - size.width) / 2;
    CGFloat y =  ([img size].height - size.height) / 2;
    [img lockFocus];
    [str drawAtPoint:NSMakePoint(x, y+1) withAttributes:attr];
    [img unlockFocus];
  }
  return img;
}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows 
                            tableColumns:(NSArray *)tableColumns 
                                   event:(NSEvent*)dragEvent 
                                  offset:(NSPointPointer)dragImageOffset
                                   image:(NSImage *)anImage {
  if ([tableColumns count] < 2 || ![dragRows count])
    return anImage;
  
  CGFloat width = [[tableColumns objectAtIndex:0] width];
  width += [[tableColumns objectAtIndex:1] width];
  dragImageOffset->x = 0;
  
  NSSize size = NSMakeSize(width + 1, [anImage size].height + 1);
  [anImage setSize:size];
  
  CGFloat offset = CGFLOAT_MAX;
  WBIndexesIterator(idx, dragRows) {
    offset = MIN(NSMinY([self rectOfRow:idx]), offset);
  }
  offset--;
  
  /* Draw borders */
  [anImage lockFocus];
  CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
  CGContextSaveGState(ctxt);
  
  CGContextSetLineWidth(ctxt, 0);
  CGContextSetShouldAntialias(ctxt, false);
  CGContextSetGrayFillColor(ctxt, .80f, .45f);
  CGContextSetGrayStrokeColor(ctxt, .50f, 1);
  
  WBIndexesIterator(idx, dragRows) {
    NSRect rect = [self rectOfRow:idx];
    rect.size.width = width;
    rect.size.height -= 2;
    rect.origin.y -= offset;
    rect.origin.y = [anImage size].height - rect.origin.y - rect.size.height;
    
    NSRectFillUsingOperation(rect, NSCompositeDestinationOver);
    [NSBezierPath strokeRect:rect];
  }
  
  NSImage *badge = [self badgeWithCount:[dragRows count]];
  if ([anImage size].height < [badge size].height) {
    size = NSMakeSize([anImage size].width, [badge size].height);
    [anImage setSize:size];
  }
  [badge compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
  
  CGContextRestoreGState(ctxt);
  [anImage unlockFocus];
  
  return anImage;
}
  
- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows 
                            tableColumns:(NSArray *)tableColumns 
                                   event:(NSEvent*)dragEvent 
                                  offset:(NSPointPointer)dragImageOffset {
  NSImage *anImage = [super dragImageForRowsWithIndexes:dragRows
                                           tableColumns:tableColumns
                                                  event:dragEvent
                                                 offset:dragImageOffset];
  
  return [self dragImageForRowsWithIndexes:dragRows
                              tableColumns:tableColumns
                                     event:dragEvent
                                    offset:dragImageOffset
                                     image:anImage];
}

@end

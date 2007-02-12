/*
 *  SETriggerTable.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SETriggerTable.h"

#import <ShadowKit/SKExtensions.h>

@implementation SETriggerTable

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
  if (isLocal) {
    return NSDragOperationCopy | NSDragOperationGeneric | NSDragOperationMove | NSDragOperationDelete;
  } 
  return NSDragOperationNone;
}

- (void)mouseDown:(NSEvent *)anEvent {
  if ([anEvent clickCount] == 2) {
    id target = [self target];
    SEL doubleAction = [self doubleAction];
    if (target && doubleAction) {
      [target performSelector:doubleAction withObject:self];
    }
  } else if ([anEvent clickCount] == 1 && ([anEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSAlternateKeyMask) {
    if (SKDelegateHandle([self delegate], tableView:shouldHandleOptionClick:) && ![[self delegate] tableView:self shouldHandleOptionClick:anEvent]) {
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
    if ([chr isEqualToString:@" "] && SKDelegateHandle([self delegate], spaceDownInTableView:)) {
      [[self delegate] spaceDownInTableView:self];
      return;
    }
  }
  [super keyDown:anEvent];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
  return [menuItem action] == @selector(selectAll:);
}

//- (void)dragImage:(NSImage *)anImage at:(NSPoint)imageLoc offset:(NSSize)mouseOffset event:(NSEvent *)theEvent pasteboard:(NSPasteboard *)pboard source:(id)sourceObject slideBack:(BOOL)slideBack {
//  ShadowTrace();
//  if (!_isDragging) { /* First Enter */
//    _isDragging = YES;
//    _dragImg = anImage;
//    NSRect rect = NSMakeRect(imageLoc.x, imageLoc.y, 0, 0);
//    [self dragPromisedFilesOfTypes:[NSArray arrayWithObject:@"pdf"] fromRect:rect source:sourceObject slideBack:slideBack event:theEvent]; 
//  } else { /* second Enter */
//    DLog(@"%@", [pboard types]);
//    [super dragImage:(_dragImg ? _dragImg : anImage) at:imageLoc offset:mouseOffset event:theEvent pasteboard:pboard source:sourceObject slideBack:slideBack];
//    _isDragging = NO;
//    _dragImg = nil;
//  }
//}

- (NSImage *)badgeWithCount:(unsigned)count {
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
  NSString *str = [NSString stringWithFormat:@"%i", count];
  NSSize size = [str sizeWithAttributes:attr];
  /* backup image before edit */
  img = [[img copy] autorelease];
  float x = ([img size].width - size.width) / 2;
  float y =  ([img size].height - size.height) / 2;
  [img lockFocus];
  [str drawAtPoint:NSMakePoint(x, y+1) withAttributes:attr];
  [img unlockFocus];
  return img;
}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows 
                            tableColumns:(NSArray *)tableColumns 
                                   event:(NSEvent*)dragEvent 
                                  offset:(NSPointPointer)dragImageOffset {
  NSImage *anImage = [super dragImageForRowsWithIndexes:dragRows
                                           tableColumns:tableColumns
                                                  event:dragEvent
                                                 offset:dragImageOffset];
  
  if ([tableColumns count] < 2 || ![dragRows count])
    return anImage;
  
  float width = [[tableColumns objectAtIndex:0] width];
  width += [[tableColumns objectAtIndex:1] width];
  dragImageOffset->x = 0;
  
  NSSize size = NSMakeSize(width + 1, [anImage size].height + 1);
  [anImage setSize:size];
  
  
  int idx;
  float offset = MAXFLOAT;
  SKIndexEnumerator *indexes = [dragRows indexEnumerator];
  while ((idx = [indexes nextIndex]) != NSNotFound) {
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
  
  indexes = [dragRows indexEnumerator];
  while ((idx = [indexes nextIndex]) != NSNotFound) {
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

- (NSImage *)dragImageForRows:(NSArray *)dragRows event:(NSEvent *)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset {
  NSMutableIndexSet *idxes = [NSMutableIndexSet indexSet];
  unsigned count = [dragRows count];
  while (count-- > 0) {
    [idxes addIndex:[[dragRows objectAtIndex:count] unsignedIntValue]];
  }
  return [self dragImageForRowsWithIndexes:idxes tableColumns:[self tableColumns] event:dragEvent offset:dragImageOffset];
}

@end

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

- (BOOL)validateMenuItem:(NSMenuItem*)anItem {
  if ([anItem action] == @selector(delete:)) {
    return [self numberOfSelectedRows] != 0;
  }
  return YES;
}

- (IBAction)delete:(id)sender {
  if ([[self delegate] respondsToSelector:@selector(deleteSelectionInTableView:)]) {
    [[self delegate] deleteSelectionInTableView:self];
  } else {
    NSBeep();
  }
}

- (void)keyDown:(NSEvent *)theEvent {
  switch ([theEvent keyCode]) {
    case kVirtualDeleteKey:
    case kVirtualForwardDeleteKey:
      [self delete:nil];
      break;
    case kVirtualReturnKey:
    case kVirtualEnterKey:
      if ([self target] && [self doubleAction] && [[self target] respondsToSelector:[self doubleAction]]) {
        [[self target] performSelector:[self doubleAction] withObject:self];
      }
      break;
    default:
      [super keyDown:theEvent];
  }
}

- (NSImage *)dragImageForRows:(NSArray *)dragRows event:(NSEvent *)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset {
  id anImage = [super dragImageForRows:dragRows event:dragEvent dragImageOffset:dragImageOffset];
  
  id columns = [self tableColumns];
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
    
    NSRectFillUsingOperation(imgRect, NSCompositeDestinationOver);
    [NSBezierPath strokeRect:imgRect];    
  }
  [anImage unlockFocus];
  return anImage;
}

@end

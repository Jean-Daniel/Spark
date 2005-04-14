//
//  CustomOutlineView.m
//  Spark Editor
//
//  Created by Fox on 10/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "CustomOutlineView.h"
#import <HotKeyToolKit/HotKeyToolKit.h>

@implementation CustomOutlineView

- (BOOL)validateMenuItem:(NSMenuItem*)anItem {
  if ([anItem action] == @selector(delete:)) {
    return [self numberOfSelectedRows] != 0;
  }
  return YES;
}

- (IBAction)delete:(id)sender {
  if ([[self delegate] respondsToSelector:@selector(deleteSelectionInOutlineView:)]) {
    [[self delegate] deleteSelectionInOutlineView:self];
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
    default:
      [super keyDown:theEvent];
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

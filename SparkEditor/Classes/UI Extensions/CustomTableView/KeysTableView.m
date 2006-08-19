//
//  KeysTableView.m
//  Spark
//
//  Created by Fox on Wed Jan 14 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "KeysTableView.h"
#import <SparkKit/SparkShadow.h>

@implementation KeysTableView

- (void)dealloc {
  [self unregisterDraggedTypes];
  [super dealloc];
}

- (void)awakeFromNib {
  if ([NSColor currentControlTint] == NSBlueControlTint) {
    [self setGridColor:[NSColor colorWithCalibratedRed:0.85 green:0.85 blue:0.85 alpha:0.75]];
    [self setGridStyleMask:NSTableViewSolidHorizontalGridLineMask];
  }
}

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
  if (isLocal) {
    return NSDragOperationCopy | NSDragOperationGeneric | NSDragOperationMove | NSDragOperationDelete;
  } 
  return NSDragOperationEvery;
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

/*
- (NSImage *)dragImageForRows:(NSArray *)dragRows event:(NSEvent *)dragEvent dragImageOffset:(NSPointPointer)dragImageOffset {
...
//  if (count > 0) {
//    id badge = [self badgeWithCount:count];
//    NSSize size = NSMakeSize(width,
//                             MAX([anImage size].height, [badge size].height));
//    
//    [anImage setSize:size];
//    [anImage lockFocus];
//    [badge compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
//    [anImage unlockFocus];
//  }
  return anImage;
}

*/
//- (NSImage *)badgeWithCount:(int)count {
//  id img = nil;
//  if (count > 0 && count < 100) {
//    img = [NSImage imageNamed:@"countBadge1&2"];
//  }
//  else if (count > 100 && count < 1000) {
//    img = [NSImage imageNamed:@"countBadge3"];
//  }
//  else if (count > 1000 && count < 10000) {
//    img = [NSImage imageNamed:@"countBadge4"];
//  }
//  else if (count > 10000) {
//    img = [NSImage imageNamed:@"countBadge5"];
//  }
//  id attr = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor whiteColor], NSForegroundColorAttributeName,
//    [NSFont systemFontOfSize:12], NSFontAttributeName, nil];
//  id str = [NSString stringWithFormat:@"%i", count];
//  NSSize size = [str sizeWithAttributes:attr];
//  img = [[img copy] autorelease];
//  float x = ([img size].width - size.width) / 2;
//  float y =  ([img size].height - size.height) / 2;
//  [img lockFocus];
//  [str drawAtPoint:NSMakePoint(x, y+1) withAttributes:attr];
//  [img unlockFocus];
//  return img;
//}

@end

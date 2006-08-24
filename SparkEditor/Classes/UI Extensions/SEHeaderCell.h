/*
 *  SEHeaderCell.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@interface SEHeaderCell : NSTextFieldCell {
  NSImage *se_background;
}

@end

@interface SEHeaderCellCorner : NSView {
  NSImage *se_background;
}

@end

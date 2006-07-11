/*
 *  SEHeaderCell.h
 *  Spark Editor
 *
 *  Created by Grayfox on 05/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
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

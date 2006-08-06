//
//  SETableView.h
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 07/07/06.
//  Copyright 2006 Shadow Lab. All rights reserved.
//

#import <ShadowKit/SKTableView.h>
#import <ShadowKit/SKImageAndTextCell.h>

SK_PRIVATE
NSString * const SETableSeparator;

@interface SETableView : SKTableView {
  @private
  NSImage *se_highlight;
}

- (void)setHighlightShading:(NSColor *)aColor bottom:(NSColor *)end border:(NSColor *)border;

@end

@interface SETableViewCell : SKImageAndTextCell {
  
}

@end

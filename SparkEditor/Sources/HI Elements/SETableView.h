/*
 *  SETableView.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKTableView.h>
#import <ShadowKit/SKImageAndTextCell.h>

SK_PRIVATE
NSString * const SETableSeparator;

@interface SETableView : SKTableView {
  @private
  BOOL se_lock;
}

@end

@interface SETableViewCell : SKImageAndTextCell {
  
}

@end

/*
 *  SETableView.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import WBHEADER(WBTableView.h)
#import WBHEADER(WBImageAndTextCell.h)

WB_PRIVATE
NSString * const SETableSeparator;

@interface SETableView : WBTableView {
  @private
  BOOL se_lock;
}

@end

@interface SETableViewCell : WBImageAndTextCell {
  
}

@end

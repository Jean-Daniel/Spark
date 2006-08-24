/*
 *  SETriggerCell.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKImageAndTextCell.h>

@interface SETriggerCell : SKImageAndTextCell {
  @private
  BOOL se_line;
}

- (void)setDrawLineOver:(BOOL)flag;

@end

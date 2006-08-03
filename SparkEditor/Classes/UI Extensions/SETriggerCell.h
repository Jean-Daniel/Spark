//
//  SETriggerCell.h
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 03/08/06.
//  Copyright 2006 Adamentium. All rights reserved.
//

#import <ShadowKit/SKImageAndTextCell.h>

@interface SETriggerCell : SKImageAndTextCell {
  @private
  BOOL se_line;
}

- (void)setDrawLineOver:(BOOL)flag;

@end

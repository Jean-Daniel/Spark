//
//  GrayscaleAction.m
//  MySparkAction
//
//  Created by Fox on Sat Mar 20 2004.
//  Copyright (c) 2004 shadowlab. All rights reserved.
//

#import "GrayscaleAction.h"

@implementation GrayscaleAction

extern Boolean CGDisplayUsesForceToGray();
extern void CGDisplayForceToGray(Boolean gray);

- (SparkAlert *)execute {
  CGDisplayForceToGray(!CGDisplayUsesForceToGray());
  return nil;
}

@end

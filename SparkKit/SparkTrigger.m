/*
 *  SparkTrigger.m
 *  SparkKit
 *
 *  Created by Grayfox on 05/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkTrigger.h>

@implementation SparkTrigger


- (IBAction)trigger:(id)sender {
  if ([sp_target respondsToSelector:sp_action]) {
    [sp_target performSelector:sp_action withObject:self];
  }
}

@end

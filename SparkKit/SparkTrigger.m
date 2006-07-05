/*
 *  SparkTrigger.m
 *  SparkKit
 *
 *  Created by Grayfox on 05/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkTrigger.h>

@implementation SparkTrigger

#pragma mark Copying
- (id)copyWithZone:(NSZone *)aZone {
  SparkTrigger *copy = [super copyWithZone:aZone];
  return copy;
}

#pragma mark Coding
- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
}
- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    // 
  }
  return self;
}

#pragma mark Implementation
- (id)target {
  return sp_target;
}
- (void)setTarget:(id)target {
  sp_target = target;
}

- (SEL)action {
  return sp_action;
}
- (void)setAction:(SEL)action {
  sp_action = action;
}

- (IBAction)trigger:(id)sender {
  if ([sp_target respondsToSelector:sp_action]) {
    [sp_target performSelector:sp_action withObject:self];
  } else {
    NSBeep();
  }
}

- (BOOL)setRegistred:(BOOL)flag {
  return NO;
}

@end

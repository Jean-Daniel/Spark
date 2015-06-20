/*
 *  WBLevelView.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

enum {
  kWBLevelViewMaxLevel = 16,
};

@interface WBLevelView : NSView

@property(nonatomic) BOOL zero;

@property(nonatomic) NSUInteger level;

@property(nonatomic) BOOL drawsLevelIndicator;

@end

/*
 *  SKLevelView.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

enum {
  kSKLevelViewMaxLevel = 16,
};

@interface SKLevelView : NSView {
  struct _sk_svFlags {
    unsigned int zero:1;
    unsigned int hide:1;
    unsigned int level:5;
    unsigned int reserved:23;
  } sk_svFlags;
}

- (BOOL)zero;
- (void)setZero:(BOOL)flag;

- (NSUInteger)level;
- (void)setLevel:(NSUInteger)level;

- (BOOL)drawsLevelIndicator;
- (void)setDrawsLevelIndicator:(BOOL)flag;

@end

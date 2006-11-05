/*
 *  SEApplicationView.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkApplication;
@interface SEApplicationView : NSView {
  @private
  SparkApplication *se_app;

  float se_width;
  NSImage *se_icon;
  NSString *se_title;
  
  id se_target;
  SEL se_action;
  struct _se_saFlags {
    unsigned int dark:1;
    unsigned int align:4;
    unsigned int highlight:1;
    unsigned int reserved:26;
  } se_saFlags;
}

- (void)setIcon:(NSImage *)anImage;
- (void)setTitle:(NSString *)title;

- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)anApp;

- (id)target;
- (void)setTarget:(id)aTarget;

- (SEL)action;
- (void)setAction:(SEL)anAction;

@end

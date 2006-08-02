/*
 *  SEApplicationView.h
 *  Spark Editor
 *
 *  Created by Grayfox on 14/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkApplication;
@interface SEApplicationView : NSView {
  @private
  SparkApplication *se_app;

  float se_width;
  NSImage *se_icon;
  NSString *se_title;
  BOOL se_highlight;
  
  id se_target;
  SEL se_action;
}

- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)anApp;

- (id)target;
- (void)setTarget:(id)aTarget;

- (SEL)action;
- (void)setAction:(SEL)anAction;

@end

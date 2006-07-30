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
  SparkApplication *se_app;
  
  float se_width;
  NSString *se_title;
}

- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)anApp;

@end

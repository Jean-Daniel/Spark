/*
 *  SEApplicationView.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKApplicationView.h>

@class SparkApplication;
@interface SEApplicationView : SKApplicationView {
  @private
  SparkApplication *se_app;
}

- (SparkApplication *)sparkApplication;
- (void)setSparkApplication:(SparkApplication *)anApp;

@end

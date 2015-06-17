/*
 *  SEApplicationView.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <WonderBox/WBApplicationView.h>

@class SparkApplication;
@interface SEApplicationView : WBImageAndTextView

@property(nonatomic, retain) SparkApplication *sparkApplication;

@end

/*
 *  SEApplicationView.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkApplication;
@interface SEApplicationView : NSView

@property(nonatomic, retain) NSImage *icon;
@property(nonatomic, copy) NSString *title;

@property(nonatomic, retain) id target;
@property(nonatomic, assign) SEL action;

@property(nonatomic, retain) SparkApplication *sparkApplication;

@end

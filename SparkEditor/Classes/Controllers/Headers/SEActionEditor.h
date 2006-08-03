/*
 *  SEActionEditor.h
 *  Spark Editor
 *
 *  Created by Grayfox on 09/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKViewController.h>

@class SparkAction, SparkApplication;
@class SEHotKeyTrap, SEApplicationView;
@interface SEActionEditor : SKViewController {
  IBOutlet SEApplicationView *appField;
  IBOutlet NSView *pluginView;
  IBOutlet SEHotKeyTrap *trap;
  @private
  NSMutableArray *se_plugins;
}

- (void)setSparkAction:(SparkAction *)anAction;
- (void)setApplication:(SparkApplication *)anApplication;

@end

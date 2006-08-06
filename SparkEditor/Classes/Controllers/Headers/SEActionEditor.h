/*
 *  SEActionEditor.h
 *  Spark Editor
 *
 *  Created by Grayfox on 09/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKViewController.h>

@class SEHotKeyTrap, SEApplicationView;
@class SparkAction, SparkApplication, SparkPlugIn;
@interface SEActionEditor : SKViewController {
  IBOutlet SEApplicationView *appField;
  IBOutlet NSView *pluginView;
  IBOutlet SEHotKeyTrap *trap;

  IBOutlet id typeField;
}

- (void)setActionType:(SparkPlugIn *)type;
- (void)setSparkAction:(SparkAction *)anAction;
- (void)setApplication:(SparkApplication *)anApplication;

@end

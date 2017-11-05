/*
 *  AppleScriptActionPlugin.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

@class OSAScript, OSAScriptController;
@interface AppleScriptActionPlugin : SparkActionPlugIn {
  IBOutlet OSAScriptController *ibScriptController;
}

@property(nonatomic, copy) NSURL *scriptFile;

- (IBAction)open:(id)sender;
- (IBAction)import:(id)sender;

- (IBAction)launchEditor:(id)sender;

@property(nonatomic) NSInteger selectedTab;

- (NSAlert *)compileScript:(OSAScript *)script;

@end

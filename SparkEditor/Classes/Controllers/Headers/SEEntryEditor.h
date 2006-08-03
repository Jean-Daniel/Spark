/*
 *  SEEntryEditor.h
 *  Spark Editor
 *
 *  Created by Grayfox on 09/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKWindowController.h>

@class SparkApplication;
@class SETriggerEntry, SEActionEditor;
@interface SEEntryEditor : SKWindowController {
  @private
  SEActionEditor *se_editor;
}

- (void)setEntry:(SETriggerEntry *)anEntry;
- (void)setApplication:(SparkApplication *)anApplication;

@end

/*
 *  DocumentActionPlugIn.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>
#import "DocumentAction.h"

@class DAApplicationMenu;
@interface DocumentActionPlugin : SparkActionPlugIn {
@private
  IBOutlet NSTextField *ibName;
  IBOutlet DAApplicationMenu *ibMenu;
}

- (IBAction)chooseDocument:(id)sender;

@property(nonatomic, copy) NSString *url;

@property(nonatomic) DocumentActionType action;

@property(nonatomic, copy) NSString *document;

@property(nonatomic, copy) NSString *application;

@property(nonatomic) NSInteger tabIndex;

@property(nonatomic) BOOL displayWithMenu;

@property(nonatomic, copy) NSString *documentName;

@property(nonatomic, retain) NSImage *documentIcon;

@end

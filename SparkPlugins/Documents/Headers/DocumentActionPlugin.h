/*
 *  DocumentActionPlugIn.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>

@class DAApplicationMenu;
@interface DocumentActionPlugin : SparkActionPlugIn {
  @private
	IBOutlet NSTextField *ibName;
  IBOutlet DAApplicationMenu *ibMenu;
  
  NSImage *da_icon;
  NSString *da_name;
  NSString *da_path;
}

- (IBAction)chooseDocument:(id)sender;

- (NSString *)url;
- (void)setUrl:(NSString *)anUrl;

- (int)action;
- (void)setAction:(int)anAction;

- (NSString *)document;
- (void)setDocument:(NSString *)aPath;

- (NSString *)application;
- (void)setApplication:(NSString *)aPath;

- (int)tabIndex;
- (void)setTabIndex:(int)newTabIndex;

- (BOOL)displayWithMenu;
- (void)setDisplayWithMenu:(BOOL)newDisplayWithMenu;

- (NSString *)documentName;
- (void)setDocumentName:(NSString *)newDocName;

- (NSImage *)documentIcon;
- (void)setDocumentIcon:(NSImage *)newDocIcon;

@end

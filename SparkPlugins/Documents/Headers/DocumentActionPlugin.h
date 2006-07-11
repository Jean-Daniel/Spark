//
//  DocumentActionPlugIn.h
//  Short-Cut
//
//  Created by Fox on Mon Dec 08 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//


#import "DocumentAction.h"

SPARK_PRIVATE
NSString * const kDocumentActionBundleIdentifier;

#define kDocumentActionBundle		[NSBundle bundleWithIdentifier:kDocumentActionBundleIdentifier]

@interface DocumentActionPlugin : SparkActionPlugIn {
  @private
  IBOutlet id appMenu;
  IBOutlet id nameField;
  DocumentActionType action;
  
  NSString *_docPath;
  NSString *_docName;
  NSImage *_docIcon;
  int flags;
}

- (IBAction)chooseDocument:(id)sender;

- (NSString *)shortDescription;
- (void)setFile:(NSString *)file;

- (NSString *)name;
- (NSString *)appPath;
@end

@interface DocumentActionPlugin (KVC_Compliance)
- (DocumentActionType)action;
- (void)setAction:(DocumentActionType)newAction;

- (int)tabIndex;
- (void)setTabIndex:(int)newTabIndex;

- (BOOL)displayWithMenu;
- (void)setDisplayWithMenu:(BOOL)newDisplayWithMenu;

- (NSString *)docName;
- (void)setDocName:(NSString *)newDocName;

- (NSImage *)docIcon;
- (void)setDocIcon:(NSImage *)newDocIcon;
@end
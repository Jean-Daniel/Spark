//
//  DocumentActionPlugIn.h
//  Short-Cut
//
//  Created by Fox on Mon Dec 08 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkPluginAPI.h>

@interface DocumentActionPlugin : SparkActionPlugIn {
  @private
  IBOutlet NSPopUpButton *ibMenu;
  IBOutlet NSTextField *ibName;
  
  int da_flags;
  NSImage *da_icon;
  NSString *da_name;
  NSString *da_path;
}

- (IBAction)chooseDocument:(id)sender;

- (void)setFile:(NSString *)file;

- (int)tabIndex;
- (void)setTabIndex:(int)newTabIndex;

- (BOOL)displayWithMenu;
- (void)setDisplayWithMenu:(BOOL)newDisplayWithMenu;

- (NSString *)documentName;
- (void)setDocumentName:(NSString *)newDocName;

- (NSImage *)documentIcon;
- (void)setDocumentIcon:(NSImage *)newDocIcon;

@end

/*
 *  SEPlugInInstaller.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <WonderBox/WonderBox.h>

@interface SEPlugInInstaller : WBWindowController {
@private
  IBOutlet NSMatrix *ibMatrix;
  IBOutlet NSTextField *ibInfo;
  IBOutlet NSTextField *ibExplain;
}

- (void)setPlugIn:(NSString *)path;

- (IBAction)update:(id)sender;
- (IBAction)install:(id)sender;

@end

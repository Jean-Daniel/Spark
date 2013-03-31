/*
 *  SEFirstRun.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <WonderBox/WBWindowController.h>

@interface SEFirstRun : WBWindowController {
  @private
  IBOutlet NSTextView *ibText;
  IBOutlet NSButton *ibStartNow;
  IBOutlet NSButton *ibAutoStart;
}

- (IBAction)close:(id)sender;

@end

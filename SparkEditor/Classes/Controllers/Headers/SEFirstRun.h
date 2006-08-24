/*
 *  SEFirstRun.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKWindowController.h>

@interface SEFirstRun : SKWindowController {
  IBOutlet NSTextView *ibText;
  IBOutlet NSButton *ibStartNow;
  IBOutlet NSButton *ibAutoStart;
}

@end

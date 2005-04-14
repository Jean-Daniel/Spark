//
//  FirstRunController.h
//  Spark
//
//  Created by Fox on Sat Feb 21 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface FirstRunController : NSWindowController {
  BOOL run;
  BOOL autorun;
}
- (IBAction)closeSheet:(id)sender;

@end

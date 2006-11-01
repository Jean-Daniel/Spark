//
//  ApplicationMenu.h
//  Spark
//
//  Created by Fox on Thu Feb 19 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ApplicationMenu : NSPopUpButton {
  BOOL da_custom;
}

- (NSMenuItem *)itemForPath:(NSString *)path;
- (void)loadAppForDocument:(NSString *)path;

@end

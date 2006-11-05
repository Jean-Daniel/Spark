/*
 *  DAApplicationMenu.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@interface DAApplicationMenu : NSPopUpButton {
  BOOL da_custom;
}

- (NSMenuItem *)itemForPath:(NSString *)path;
- (void)loadAppForDocument:(NSString *)path;

@end

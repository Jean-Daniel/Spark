//
//  SparkAEHandle.h
//  SparkServer
//
//  Created by Fox on 21/08/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSApplication (SparkAEHandle)

- (NSArray *)hotkeys;
- (int)countOfHotkeys;
- (id)objectInHotkeysAtIndex:(int)index;

@end

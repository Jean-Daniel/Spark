/*
 *  SEVirtualPlugIn.m
 *  Spark Editor
 *
 *  Created by Grayfox on 09/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "SEVirtualPlugIn.h"


@implementation SEVirtualPlugIn

+ (id)pluginWithName:(NSString *)name icon:(NSImage *)icon {
  return [[[self alloc] initWithName:name icon:icon] autorelease];
}

- (id)initWithName:(NSString *)name icon:(NSImage *)icon {
  if (self = [super init]) {
    [self setName:name];
    [self setIcon:icon];
  }
  return self;
}

- (void)dealloc {
  [super dealloc];
}

@end

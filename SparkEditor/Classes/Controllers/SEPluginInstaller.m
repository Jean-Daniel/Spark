/*
 *  SEPluginInstaller.m
 *  Spark Editor
 *
 *  Created by Grayfox on 14/11/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "SEPluginInstaller.h"

@implementation SEPluginInstaller

- (id)init {
  if (self = [super init]) {
  }
  return self;
}

- (void)dealloc {
  
  [super dealloc];
}

#pragma mark -
- (IBAction)update:(id)sender {
  [ibInfo setHidden:[ibMatrix selectedRow] == 0];
}

@end

/*
 *  SEEntryCache.m
 *  Spark Editor
 *
 *  Created by Grayfox on 16/01/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 */

#import "SEEntryCache.h"


@implementation SEEntryCache

- (id)init {
  if (self = [super init]) {
  }
  return self;
}

- (void)dealloc {
  if (se_entries) CFRelease(se_entries);
  [super dealloc];
}


@end

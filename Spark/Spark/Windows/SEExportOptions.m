//
//  SEExportOptions.m
//  Spark Editor
//
//  Created by Grayfox on 28/10/07.
//  Copyright 2007 Shadow Lab. All rights reserved.
//

#import "SEExportOptions.h"

@implementation SEExportOptions

- (id)init {
  if (self = [super initWithNibName:@"SEExportOptions" bundle:nil]) {
    
  }
  return self;
}

- (BOOL)strike {
  return [uiStrike state] == NSControlStateValueOn;
}

- (BOOL)includeIcons {
  return [uiIcons state] == NSControlStateValueOn;
}

@end

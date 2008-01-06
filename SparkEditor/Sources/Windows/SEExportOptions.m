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
  if (self = [super initWithNibName:@"SEExport" bundle:nil]) {
    
  }
  return self;
}

- (BOOL)includeIcons {
  return [uiIcons state] == NSOnState;
}
- (NSInteger)groupBy {
  return [[uiGroup selectedItem] tag];
}


@end

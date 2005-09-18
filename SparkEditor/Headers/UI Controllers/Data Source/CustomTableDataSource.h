//
//  CustomTableDataSource.h
//  Spark
//
//  Created by Fox on Wed Jan 14 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "Extensions.h"
#import "SKTableDataSource.h"

@interface CustomTableDataSource : SKTableDataSource {
  NSString *_pboardType;
}
#pragma mark -
- (NSString *)pasteboardType;
- (void)setPasteboardType:(NSString *)type;

@end

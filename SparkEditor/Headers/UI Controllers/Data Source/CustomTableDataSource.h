//
//  CustomTableDataSource.h
//  Spark
//
//  Created by Fox on Wed Jan 14 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "Extensions.h"

typedef NSComparisonResult (*CompareFunction)(id, id, void *);
typedef BOOL (*FilterFunction)(NSString *, id, void *);

@interface CustomTableDataSource : NSArrayController {
  NSString *_pboardType;
  NSString *_searchString;
  FilterFunction _filter;
  void *_filterCtxt;
  CompareFunction _compare;
}
#pragma mark -
- (NSString *)pasteboardType;
- (void)setPasteboardType:(NSString *)type;

#pragma mark -
- (CompareFunction)compareFunction;
- (void)setCompareFunction:(CompareFunction)function;

#pragma mark -
- (IBAction)search:(id)sender;
- (NSString *)searchString;
- (void)setSearchString:(NSString *)aString;
- (FilterFunction)filterFunction;
- (void)setFilterFunction:(FilterFunction)function context:(void *)ctxt;

@end

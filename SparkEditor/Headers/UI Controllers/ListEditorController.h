//
//  ListEditorController.h
//  Spark
//
//  Created by Fox on Thu Jan 22 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "ObjectEditorController.h"
@class SparkKeyList;

@interface ListEditorController : ObjectEditorController {
  NSString *name;
  IBOutlet id title;
  IBOutlet id objectController;
@private
  SparkObjectList *_list;
  Class _listClass;
}

- (Class)listClass;
- (void)setListClass:(Class)listClass;

- (IBAction)create:(id)sender;
- (IBAction)update:(id)sender;

#pragma mark List Properties
- (NSString *)name;
- (void)setName:(NSString *)newName;

@end

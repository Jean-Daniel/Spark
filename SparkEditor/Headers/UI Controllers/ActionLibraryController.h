//
//  ActionLibraryController.h
//  Spark Editor
//
//  Created by Grayfox on 17/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LibraryController.h"

extern NSString * const kSparkActionPBoardType;

@interface ActionLibraryController : LibraryController {
  NSMutableArray *_actionsLists;
}

- (NSArray *)actionsLists;

@end

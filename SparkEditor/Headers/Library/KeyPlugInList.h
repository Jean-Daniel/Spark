//
//  KeyPlugInList.h
//  Spark Editor
//
//  Created by Grayfox on 18/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit.h>

@interface KeyPlugInList : SparkKeyList <NSCopying> {
  id _plugIn;
}

- (id)initWithPlugIn:(SparkPlugIn *)plugIn;
+ (id)listWithPlugIn:(SparkPlugIn *)plugIn;

- (void)reload;
- (SparkPlugIn *)plugIn;
- (void)setPlugIn:(SparkPlugIn *)plugIn;

@end

@interface MultipleActionsKeyList : SparkKeyList <NSCopying> {
}

- (void)reload;
@end
//
//  ActionPlugInList.h
//  Spark
//
//  Created by Fox on Fri Jan 09 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit.h>

@interface ActionPlugInList : SparkActionList <NSCopying> {
  id _plugIn;
}

- (id)initWithPlugIn:(SparkPlugIn *)plugIn;
+ (id)listWithPlugIn:(SparkPlugIn *)plugIn;

- (void)reload;
- (SparkPlugIn *)plugIn;
- (void)setPlugIn:(SparkPlugIn *)plugIn;

@end

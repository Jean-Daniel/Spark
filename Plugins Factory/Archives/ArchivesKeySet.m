//
//  ZipKeySet.m
//  Spark
//
//  Created by Fox on Tue Feb 17 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "ArchivesKeySet.h"

#if defined (DEBUG)
#warning Debug defined in ArchivesHotKey!
#endif

@implementation ArchivesKeySet

- (void)setHotKey:(SparkHotKey *)key {

}

- (NSAlert *)controllerShouldConfigKey {
  return nil;
}


- (void)configHotKey {
}


@end

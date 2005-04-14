//
//  ZipHotKey.h
//  Spark
//
//  Created by Fox on Tue Feb 17 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit.h>

typedef enum {
  kZipFormat = 1,
  kCpioFormat = 2
} ArchiveFormat;

@interface ArchivesHotKey : SparkHotKey {
  ArchiveFormat format;
}

@end

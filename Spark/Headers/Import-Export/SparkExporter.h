//
//  SparkExporter.h
//  Spark
//
//  Created by Fox on Fri Feb 27 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const OSType kSparkKeyFileType;
extern NSString * const kSparkKeyFileExtension;

extern const OSType kSparkListFileType;
extern NSString * const kSparkListFileExtension;

extern NSString * const kSparkExportListKey;
extern NSString * const kSparkExportListObjects;
extern NSString * const kSparkExportListVersion;
extern NSString * const kSparkExportListContentType;

extern NSString * const kSparkExportLists;
extern NSString * const kSparkExportHotKeys;
extern NSString * const kSparkExportActions;
extern NSString * const kSparkExportApplications;

typedef enum {
  kSparkListFormat,
  kHTMLFormat
} SparkExportFormat;

@class SparkObjectList;
@interface SparkExporter : NSObject {
}

- (id)initWithFormat:(NSInteger)format;
- (BOOL)exportList:(SparkObjectList *)list toFile:(NSString *)file;

- (void)setIcon:(NSString *)iconName forFile:(id)file;

@end
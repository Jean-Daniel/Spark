//
//  ChoosePanel.h
//  Spark Editor
//
//  Created by Grayfox on 03/10/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
  kSparkHotKey,
  kSparkAction,
  kSparkApplication
} SparkObjectType;

@interface ChoosePanel : NSWindowController {
  IBOutlet id libraryView;
  IBOutlet id defaultButton;
  id _library;
  id _object;
}

- (id)initWithObjectType:(SparkObjectType)type;
- (id)object;

@end

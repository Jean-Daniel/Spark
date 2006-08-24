/*
 *  SEBuiltInPlugin.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkActionPlugIn.h>

@interface SEIgnorePlugin : SparkActionPlugIn {

}

- (int)type;

@end

@interface SEInheritsPlugin : SparkActionPlugIn {
  
}

- (int)type;

@end


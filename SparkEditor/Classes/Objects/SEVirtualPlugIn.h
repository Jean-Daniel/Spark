/*
 *  SEVirtualPlugIn.h
 *  Spark Editor
 *
 *  Created by Grayfox on 09/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPlugIn.h>

SK_PRIVATE
NSArray *gSortByNameDescriptors;

@interface SEVirtualPlugIn : SparkPlugIn {

}

+ (id)pluginWithName:(NSString *)name icon:(NSImage *)icon;
- (id)initWithName:(NSString *)name icon:(NSImage *)icon;

@end

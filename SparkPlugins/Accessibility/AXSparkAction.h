//
//  AXSparkAction.h
//  Spark Plugins
//
//  Created by Jean-Daniel Dupas on 27/11/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import <SparkKit/SparkPlugInAPI.h>

@interface AXSparkAction : SparkAction <NSCopying> {
@private
  NSString *ax_title;
  NSString *ax_subtitle;
}

- (NSString *)menuTitle;
- (void)setMenuTitle:(NSString *)menuTitle;

- (NSString *)menuItemTitle;
- (void)setMenuItemTitle:(NSString *)menuTitle;

@end

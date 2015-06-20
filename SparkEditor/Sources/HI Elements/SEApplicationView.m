/*
 *  SEApplicationView.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEApplicationView.h"

#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkApplication.h>

@implementation SEApplicationView {
@private
  SparkApplication *se_app;
}

- (SparkApplication *)sparkApplication {
  return se_app;
}
- (void)setSparkApplication:(SparkApplication *)anApp {
  if (se_app != anApp) {
    se_app = anApp;
    
		NSString *title = se_app ? [[NSString alloc] initWithFormat:
																NSLocalizedString(@"%@ HotKeys", @"Application HotKeys - Application View Title (%@ => name)"), [se_app name]] : nil;
    self.title = title;

    if (kSparkApplicationSystemUID == [se_app uid]) {
      self.icon = [NSImage imageNamed:@"applelogo"];
    } else {
      self.icon = se_app.icon;
    }
  }
}

- (NSImage *)defaultIcon {
  if ([se_app icon])
    return [se_app icon];
  else
    return [[NSWorkspace sharedWorkspace] iconForFileType:@"'APPL'"];
}

@end

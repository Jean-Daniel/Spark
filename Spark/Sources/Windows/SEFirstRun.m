/*
 *  SEFirstRun.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEFirstRun.h"

#import "SDVersion.h"
#import "SEPreferences.h"
#import "SELibraryDocument.h"
#import "SEServerConnection.h"

#import <SparkKit/SparkKit.h>

@implementation SELibraryDocument (SEFirstRun)

- (void)displayFirstRunIfNeeded {
  NSUInteger version = [[NSUserDefaults standardUserDefaults] integerForKey:kSparkVersionKey];
  if (0 == version) {
    /* SparkEditor preferences does not exists */
    
  }
  if (version < kSparkEditorVersion) {
    SEFirstRun *first = [[SEFirstRun alloc] initWithWindowNibName:@"SEFirstRun"];
    [first setReleasedWhenClosed:YES];
    NSWindow *window = first.window;
    NSAssert(window, @"window required");
    [self.windowForSheet beginSheet:window completionHandler:NULL];
  }
}

@end

@implementation SEFirstRun

+ (NSString *)frameAutoSaveName {
  return nil;
}

- (void)awakeFromNib {
  NSString *path = [[NSBundle mainBundle] pathForResource:NSLocalizedStringFromTable(@"Read First", @"Resources", @"Read First file name")
                                                   ofType:@"rtf"];
  NSURL *url = [NSURL fileURLWithPath:path];
  NSTextStorage *storage = [[NSTextStorage alloc] initWithURL:url documentAttributes:nil];
  [[ibText layoutManager] replaceTextStorage:storage];
}

- (IBAction)close:(NSButton *)sender {
  /* First, set preferences to avoid second call */
  [[NSUserDefaults standardUserDefaults] setInteger:kSparkEditorVersion forKey:kSparkVersionKey];
  if ([ibStartNow state] == NSOnState && ![[SEServerConnection defaultConnection] isRunning]) {
    SELaunchSparkDaemon(NULL);
  }
  SEPreferencesSetLoginItemStatus(NSOnState == [ibAutoStart state]);
  [super close:sender];
}

@end

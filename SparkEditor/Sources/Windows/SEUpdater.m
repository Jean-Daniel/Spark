//
//  SEUpdater.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 18/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SEUpdater.h"
#import <ShadowKit/SKUpdater.h>
#import <ShadowKit/SKSingleton.h>

SKSingleton(SEUpdater, sharedUpdater);

@implementation SEUpdater

- (id)init {
  if (self = [super init]) {
    
  }
  return self;
}

- (void)dealloc {
  [se_updater cancel];
  [se_updater release];
  [super dealloc];
}

- (void)runInBackground {
  if (!se_updater) {
    se_updater = [[SKUpdater alloc] initWithURL:[NSURL URLWithString:NSLocalizedStringFromTable(@"UPDATE_FILE_URL", @"Update", 
                                                                                                @"URL of the update file (.xml or .plist).")]
                                       delegate:self];
  }
}

- (void)check {
  if (se_updater && [se_updater status] == kSKUpdaterWaitNetwork) {
    [se_updater cancel];
    [se_updater release];
  }
  se_updater = [[SKUpdater alloc] initWithURL:[NSURL URLWithString:NSLocalizedStringFromTable(@"UPDATE_FILE_URL", @"Update", 
                                                                                              @"URL of the update file (.xml or .plist).")]
                                     delegate:self];
}

/* Network is down */
- (BOOL)updaterShouldWaitNetworkConnection:(SKUpdater *)updater {
  
}

/* Required: Network unreachable or download failed */
- (void)updater:(SKUpdater *)updater errorOccured:(NSError *)anError {
}

/* Required: Properties found */
- (NSURL *)updater:(SKUpdater *)updater shouldDownloadUpdate:(NSDictionary *)properties {
}

/* Update download */
- (void)updater:(SKUpdater *)updater downloadProgress:(SInt64)progress {
}

/* Update downloaded */
- (void)updater:(SKUpdater *)updater didDownloadUpdate:(NSString *)path {
}

@end

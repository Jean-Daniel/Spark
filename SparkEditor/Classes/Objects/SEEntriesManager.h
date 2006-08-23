//
//  SEEntriesManager.h
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 22/08/06.
//  Copyright 2006 Adamentium. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SparkLibrary, SparkApplication, SparkPlugIn;
@class SETriggerEntrySet, SEEntryEditor, SETriggerEntry;
@interface SEEntriesManager : NSObject {
  @private
  SEEntryEditor *se_editor;
  SparkApplication *se_app;
  SETriggerEntrySet *se_globals;
  SETriggerEntrySet *se_snapshot;
  SETriggerEntrySet *se_overwites;
}

/* All globals entries */
- (SETriggerEntrySet *)globals;
/* Current entryset */
- (SETriggerEntrySet *)snapshot;
/* Current application entries */
- (SETriggerEntrySet *)overwrites;

- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)anApplication;

- (void)createEntry:(SparkPlugIn *)aPlugin modalForWindow:(NSWindow *)aWindow;
- (void)editEntry:(SETriggerEntry *)anEntry modalForWindow:(NSWindow *)aWindow;

@end

SK_PRIVATE
NSString * const SEApplicationDidChangeNotification;
SK_PRIVATE
NSString * const SEEntriesManagerDidReloadNotification;

@interface SEEntriesManager (ShadowSingleton)

+ (SEEntriesManager *)sharedManager;

@end

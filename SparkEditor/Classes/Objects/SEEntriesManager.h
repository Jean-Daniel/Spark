/*
 *  SEEntriesManager.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkLibrary, SparkApplication, SparkPlugIn;
@class SETriggerEntrySet, SEEntryEditor, SETriggerEntry;
@interface SEEntriesManager : NSObject {
  @private
  SEEntryEditor *se_editor;
  SparkApplication *se_app;
  SETriggerEntrySet *se_globals;
  SETriggerEntrySet *se_snapshot;
  SETriggerEntrySet *se_overwrites;
}

/* All globals entries */
- (SETriggerEntrySet *)globals;
/* Current entryset */
- (SETriggerEntrySet *)snapshot;
/* Current application entries */
- (SETriggerEntrySet *)overwrites;

- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)anApplication;

- (void)removeEntries:(NSArray *)entries;

- (void)createEntry:(SparkPlugIn *)aPlugin modalForWindow:(NSWindow *)aWindow;
- (void)editEntry:(SETriggerEntry *)anEntry modalForWindow:(NSWindow *)aWindow;

@end

SK_PRIVATE
NSString * const SEApplicationDidChangeNotification;
SK_PRIVATE
NSString * const SEEntriesManagerDidReloadNotification;
SK_PRIVATE
NSString * const SEEntriesManagerDidCreateEntryNotification;

@interface SEEntriesManager (ShadowSingleton)

+ (SEEntriesManager *)sharedManager;

@end

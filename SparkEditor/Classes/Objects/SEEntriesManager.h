/*
 *  SEEntriesManager.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkLibrary, SparkApplication, SparkPlugIn;
@class SESparkEntrySet, SEEntryEditor;
@class SparkEntry;
@interface SEEntriesManager : NSObject {
  @private
  SEEntryEditor *se_editor;
  SparkApplication *se_app;
  SESparkEntrySet *se_globals;
  SESparkEntrySet *se_snapshot;
  SESparkEntrySet *se_overwrites;
}

- (void)reload;

/* All globals entries */
- (SESparkEntrySet *)globals;
/* Current entryset */
- (SESparkEntrySet *)snapshot;
/* Current application entries */
- (SESparkEntrySet *)overwrites;

- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)anApplication;

- (unsigned)removeEntries:(NSArray *)entries;

- (SparkEntry *)createWeakEntryForEntry:(SparkEntry *)anEntry;

- (void)createEntry:(SparkPlugIn *)aPlugin modalForWindow:(NSWindow *)aWindow;
- (void)editEntry:(SparkEntry *)anEntry modalForWindow:(NSWindow *)aWindow;

@end

SK_PRIVATE
NSString * const SEApplicationDidChangeNotification;
SK_PRIVATE
NSString * const SEEntriesManagerDidReloadNotification;
SK_PRIVATE
NSString * const SEEntriesManagerDidCreateEntryNotification;

SK_PRIVATE
NSString * const SEEntriesManagerDidUpdateEntryNotification;
SK_PRIVATE
NSString * const SEEntriesManagerDidCreateWeakEntryNotification;

@interface SEEntriesManager (ShadowSingleton)

+ (SEEntriesManager *)sharedManager;

@end

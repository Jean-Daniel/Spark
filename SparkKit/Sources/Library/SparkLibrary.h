/*
 *  SparkLibrary.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

SPARK_EXPORT
NSPropertyListFormat SparkLibraryFileFormat;

SPARK_EXPORT
NSString * const kSparkLibraryFileExtension;

SPARK_EXPORT
NSString * const kSparkLibraryDefaultFileName;

SPARK_EXPORT
NSURL *SparkLibraryFolder(void);

enum {
  kSparkLibraryReserved = 0xff,
};

enum {
  kSparkApplicationSystemUID = 0,
  kSparkApplicationFinderUID = 1,
};

SPARK_EXPORT
const NSUInteger kSparkLibraryCurrentVersion;

#pragma mark -
@class SparkLibrary, SparkObjectSet, SparkEntryManager;

SPARK_EXPORT
SparkLibrary *SparkActiveLibrary(void);
SPARK_EXPORT
bool SparkSetActiveLibrary(SparkLibrary *library);

SPARK_EXPORT
void SparkLibraryRegisterLibrary(SparkLibrary *library);
SPARK_EXPORT
void SparkLibraryUnregisterLibrary(SparkLibrary *library);

SPARK_EXPORT
void SparkLibraryDeleteIconCache(SparkLibrary *library);

SPARK_EXPORT
SparkLibrary *SparkLibraryGetLibraryWithUUID(NSUUID *uuid);
SPARK_EXPORT
SparkLibrary *SparkLibraryGetLibraryAtURL(NSURL *path, BOOL create);


#pragma mark -
@class SparkIconManager, SparkEntryManager;
@class SparkList, SparkAction, SparkTrigger, SparkApplication;
SPARK_OBJC_EXPORT
@interface SparkLibrary : NSObject {
@protected
  SparkIconManager *_icons;
}

- (instancetype)initWithURL:(NSURL *)anURL;

@property(nonatomic, readonly) SparkApplication *systemApplication;

@property(nonatomic, readonly) NSUUID *uuid;

@property(nonatomic, copy, setter=setURL:) NSURL *URL;

@property(nonatomic, retain) NSUndoManager *undoManager;

- (void)enableNotifications;
- (void)disableNotifications;

- (NSNotificationCenter *)notificationCenter;

- (BOOL)isLoaded;

- (BOOL)load:(__autoreleasing NSError **)error;
- (void)unload;

- (SparkObjectSet *)listSet;
- (SparkObjectSet *)actionSet;
- (SparkObjectSet *)triggerSet;
- (SparkObjectSet *)applicationSet;

- (SparkEntryManager *)entryManager;

- (BOOL)synchronize;
- (BOOL)writeToURL:(NSURL *)anURL atomically:(BOOL)flag;

- (SparkIconManager *)iconManager;

- (NSFileWrapper *)fileWrapper:(__autoreleasing NSError **)outError;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(__autoreleasing NSError **)outError;

@end

/* Notifications support */
SPARK_EXPORT
NSString * const SparkNotificationObjectKey;
SPARK_EXPORT
NSString * const SparkNotificationUpdatedObjectKey;

SPARK_INLINE
id SparkNotificationObject(NSNotification *aNotification) {
  return [[aNotification userInfo] objectForKey:SparkNotificationObjectKey];
}

SPARK_INLINE
id SparkNotificationUpdatedObject(NSNotification *aNotification) {
  return [[aNotification userInfo] objectForKey:SparkNotificationUpdatedObjectKey];
}

SPARK_INLINE
void SparkLibraryPostNotification(SparkLibrary *library, NSString *name, id sender, id object) {
  [[library notificationCenter] postNotificationName:name
                                              object:sender
                                            userInfo:object ? [NSDictionary dictionaryWithObject:object
                                                                                          forKey:SparkNotificationObjectKey] : nil];
}
SPARK_INLINE
void SparkLibraryPostUpdateNotification(SparkLibrary *library, NSString *name, id sender, id replaced, id object) {
  [[library notificationCenter] postNotificationName:name
                                              object:sender
                                            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      object, SparkNotificationObjectKey,
                                                      replaced, SparkNotificationUpdatedObjectKey, nil]];
}

// MARK: Debugger
SPARK_EXPORT
void SparkDumpTriggers(SparkLibrary *aLibrary);

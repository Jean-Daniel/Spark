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
NSString *SparkLibraryFolder(void);

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
BOOL SparkSetActiveLibrary(SparkLibrary *library);

SPARK_EXPORT
void SparkLibraryRegisterLibrary(SparkLibrary *library);
SPARK_EXPORT
void SparkLibraryUnregisterLibrary(SparkLibrary *library);

SPARK_EXPORT
void SparkLibraryDeleteIconCache(SparkLibrary *library);

SPARK_EXPORT
SparkLibrary *SparkLibraryGetLibraryWithUUID(CFUUIDRef uuid);
SPARK_EXPORT
SparkLibrary *SparkLibraryGetLibraryAtPath(NSString *path, BOOL create);

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

#pragma mark -
@class SparkIconManager, SparkEntryManager;
@class SparkList, SparkAction, SparkTrigger, SparkApplication;
SPARK_CLASS_EXPORT
@interface SparkLibrary : NSObject {
  @private
  NSString *sp_file;
  CFUUIDRef sp_uuid;
  NSUInteger sp_version;
  
  SparkObjectSet *sp_objects[4];
  SparkIconManager *sp_icons;
  SparkEntryManager *sp_relations;
  
  struct _sp_slFlags {
    unsigned int loaded:1;
    unsigned int unnotify:1;
    unsigned int reserved:30;
  } sp_slFlags;
  
  /* Model synchronization */
  NSUndoManager *sp_undo;
  NSNotificationCenter *sp_center;
  
  /* Preferences */
  NSMutableDictionary *sp_prefs;
  
  /* reserved objects */
  SparkApplication *sp_system;
}

- (SparkApplication *)systemApplication;

- (id)initWithPath:(NSString *)path;

- (CFUUIDRef)uuid;

- (NSString *)path;
- (void)setPath:(NSString *)file;

- (NSUndoManager *)undoManager;
- (void)setUndoManager:(NSUndoManager *)aManager;

- (void)enableNotifications;
- (void)disableNotifications;
- (NSNotificationCenter *)notificationCenter;

- (BOOL)isLoaded;

- (BOOL)load:(NSError **)error;
- (void)unload;

- (NSEnumerator *)listEnumerator;
- (NSEnumerator *)entryEnumerator;
- (NSEnumerator *)actionEnumerator;
- (NSEnumerator *)triggerEnumerator;
- (NSEnumerator *)applicationEnumerator;

- (SparkEntryManager *)entryManager;
   
- (BOOL)synchronize;
- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)flag;

- (SparkIconManager *)iconManager;

- (NSFileWrapper *)fileWrapper:(NSError **)outError;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError;

@end

#pragma mark Debugger
SPARK_EXPORT
void SparkDumpTriggers(SparkLibrary *aLibrary);

/*
 *  SparkLibrary.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkActionLoader.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkEntryManager.h>

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkFunctions.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkIconManager.h>
#import <SparkKit/SparkBuiltInAction.h>

#import WBHEADER(WBCFContext.h)
#import WBHEADER(WBExtensions.h)
#import WBHEADER(WBFSFunctions.h)
#import WBHEADER(WBLSFunctions.h)
#import WBHEADER(WBSerialization.h)
#import WBHEADER(WBAppKitExtensions.h)

#import "SparkLibraryPrivate.h"
#import "SparkEntryManagerPrivate.h"

NSString * const kSparkLibraryFileExtension = @"splib";

NSPropertyListFormat SparkLibraryFileFormat = NSPropertyListBinaryFormat_v1_0;

static NSString * const kSparkActionsFile = @"SparkActions";
static NSString * const kSparkTriggersFile = @"SparkTriggers";
static NSString * const kSparkApplicationsFile = @"SparkApplications";

static NSString * const kSparkArchiveFile = @"SparkRelationships";

NSString * const kSparkLibraryPreferencesFile = @"SparkPreferences.plist";

#if defined(DEBUG)
// FIXME: Unified library for 64 bit
#if __LP64__
NSString * const kSparkLibraryDefaultFileName = @"Spark Library - Debug - 64.splib";
#else
NSString * const kSparkLibraryDefaultFileName = @"Spark Library - Debug.splib";
#endif

#elif __LP64__
NSString * const kSparkLibraryDefaultFileName = @"Spark Library - 64.splib";
#else
NSString * const kSparkLibraryDefaultFileName = @"Spark Library.splib";
#endif

static
NSString *SparkLibraryIconFolder(SparkLibrary *library);

/* Notifications */
NSString * const SparkWillSetActiveLibraryNotification = @"SparkWillSetActiveLibrary";
NSString * const SparkDidSetActiveLibraryNotification = @"SparkDidSetActiveLibrary";

NSString * const SparkNotificationObjectKey = @"SparkNotificationObject";
NSString * const SparkNotificationUpdatedObjectKey = @"SparkNotificationUpdatedObject";

#define kSparkLibraryVersion_1_0		0x0100
#define kSparkLibraryVersion_2_0		0x0200
#define kSparkLibraryVersion_2_1		0x0201

const NSUInteger kSparkLibraryCurrentVersion = kSparkLibraryVersion_2_1;

@interface SparkLibrary (SparkLibraryLoader)
/* Initializer */
- (void)setInfo:(NSDictionary *)plist;

- (BOOL)loadFromWrapper:(NSFileWrapper *)wrapper error:(NSError **)error;
- (BOOL)readLibraryFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)error;

@end

@interface SparkLibrary (SparkLegacyReader)
- (BOOL)importv1LibraryFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)error;
- (BOOL)importTriggerListFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)error;
@end

@interface SparkEntryManager (SparkVersion1Library)
- (void)removeEntriesForAction:(SparkUID)action;
@end

@implementation SparkLibrary

+ (void)initialize {
  if ([SparkLibrary class] == self) {
    /* Register Built-In Plugin (and make sure other plugins are loaded) */
    [[SparkActionLoader sharedLoader] registerPlugInClass:[SparkBuiltInActionPlugin class]];
  }
}

- (SparkApplication *)systemApplication {
  if (!sp_system) {
    sp_system = [[SparkApplication systemApplication] retain];
    [sp_system setLibrary:self];
  }
  return sp_system;
}

#pragma mark -
- (id)init {
  if (self = [self initWithPath:nil]) {
    /* Init infos */
    [self setInfo:nil];
    /* Load empty library */
    [self loadFromWrapper:nil error:nil];
  }
  return self;
}

- (id)initWithPath:(NSString *)path {
  if (self = [super init]) {
    [self setPath:path];    
  }
  return self;
}

- (void)dealloc {
  WBTrace();
  /* Avoid useless undo */
  [sp_undo release];
  sp_undo = nil;
  
  /* Unload library */
  if ([self isLoaded])
    [self unload];
  
  [sp_center release];
  
  /* Release others */
  [sp_file release];
  if (sp_uuid) CFRelease(sp_uuid);
  [super dealloc];
}

- (NSUInteger)hash {
  return sp_uuid ? CFHash(sp_uuid) : 0;
}

- (BOOL)isEqual:(id)object {
  if (![[object class] isSubclassOfClass:[self class]])
    return NO;
  if (!sp_uuid) return ![object uuid];
  if (![object uuid]) return !sp_uuid;
  return CFEqual(sp_uuid, [object uuid]);
}

#pragma mark -
#pragma mark Managers Accessors
- (SparkEntryManager *)entryManager {
  return sp_relations;
}

- (SparkIconManager *)iconManager {
  return sp_icons;
}

- (SparkObjectSet *)listSet {
  return sp_objects[kSparkListSet];
}
- (SparkObjectSet *)actionSet {
  return sp_objects[kSparkActionSet];
}
- (SparkObjectSet *)triggerSet {
  return sp_objects[kSparkTriggerSet];
}
- (SparkObjectSet *)applicationSet {
  return sp_objects[kSparkApplicationSet];
}

- (NSEnumerator *)listEnumerator {
  return [sp_objects[kSparkListSet] objectEnumerator];
}
- (NSEnumerator *)entryEnumerator {
  return [sp_relations entryEnumerator];
}

- (NSEnumerator *)actionEnumerator {
  return [sp_objects[kSparkActionSet] objectEnumerator];
}
- (NSEnumerator *)triggerEnumerator {
  return [sp_objects[kSparkTriggerSet] objectEnumerator];
}
- (NSEnumerator *)applicationEnumerator {
  return [sp_objects[kSparkApplicationSet] objectEnumerator];
}

#pragma mark -
- (CFUUIDRef)uuid {
  return sp_uuid;
}

- (NSUndoManager *)undoManager {
  return sp_undo;
}
- (void)setUndoManager:(NSUndoManager *)aManager {
  WBSetterRetain(sp_undo, aManager);
}

- (void)enableNotifications {
	NSParameterAssert(sp_slFlags.unnotify > 0);
  sp_slFlags.unnotify--;
}
- (void)disableNotifications {
	NSParameterAssert(sp_slFlags.unnotify < 255);
  sp_slFlags.unnotify++;
}
- (NSNotificationCenter *)notificationCenter {
  if (sp_slFlags.unnotify > 0) {
		return nil;
	}
  
  if (!sp_center) {
    sp_center = [[NSNotificationCenter alloc] init];
  }
  return sp_center;
}

#pragma mark FileSystem Methods
- (NSString *)path {
  return sp_file;
}

- (void)setPath:(NSString *)file {
  if (file != sp_file) {
    [sp_file release];
    sp_file = [[file stringByStandardizingPath] retain];
    
    if (![self isLoaded]) {
      /* Init UUID & version */
      NSString *path = sp_file ? [sp_file stringByAppendingPathComponent:@"Info.plist"] : nil;
      NSDictionary *dict = path ? [[NSDictionary alloc] initWithContentsOfFile:path] : nil;
      [self setInfo:dict];
      [dict release];
    }
    /* Update icon path */
    if (sp_icons && ![sp_icons path] && sp_file)
      [sp_icons setPath:SparkLibraryIconFolder(self)];
  }
}

- (BOOL)synchronize {
  if ([self path]) {
    if ([self isLoaded]) {
      if ([self writeToFile:[self path] atomically:YES]) {
        sp_version = kSparkLibraryCurrentVersion;
        return YES;
      }
    } else {
      DLog(@"WARNING: sync unloaded library");
    }
  } else {
    [NSException raise:NSInvalidArgumentException format:@"You Must set a file before synchronizing"];
  }
  return NO;
}

- (BOOL)isLoaded {
  return sp_slFlags.loaded;
}

- (BOOL)load:(NSError **)error {
  if ([self isLoaded])
    [NSException raise:NSInternalInconsistencyException format:@"<%@ %p> is already loaded.", [self class], self];
  
  BOOL result = NO;
  /* disable undo while loading */
  [sp_undo disableUndoRegistration];
  
  NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithPath:[self path]];
  if (wrapper) {
    @try {
      result = [self loadFromWrapper:wrapper error:error];
    } @catch (id exception) {
      result = NO;
      WBLogException(exception);
      if (error)
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
    }
    [wrapper release];
  } else if (error) {
    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:nil];
  }
  /* restaure undo manager */
  [sp_undo enableUndoRegistration];
  
  return result;
}

- (void)unload {
  if (![self isLoaded])
    [NSException raise:NSInternalInconsistencyException format:@"<%@ %p> is not loaded.", [self class], self];
  
  WBFlagSet(sp_slFlags.loaded, NO);
  
  /* Preferences */
  [sp_prefs release];
  sp_prefs = nil;
  
  /* Release relation table */
  [sp_relations setLibrary:nil];
  [sp_relations release];
  sp_relations = nil;
  
  /* Release defaults libraries */
  NSUInteger idx = kSparkSetCount;
  while (idx-- > 0) {
    [sp_objects[idx] setLibrary:nil];
    [sp_objects[idx] release];
    sp_objects[idx] = nil;
  }
  
  /* Release Icon cache */
  [sp_icons release];
  sp_icons = nil;
}

#pragma mark Read/Write
- (void)initReservedObjects {
  /* Init Finder Application */
  NSString *path = WBLSFindApplicationForSignature(kSparkFinderSignature);
	if (!path && kSparkFinderSignature != 'MACS') {
		WLog(@"invalid finder signature, try with default signature ('MACS')");
		path = WBLSFindApplicationForSignature('MACS');
	}
  if (path) {
    SparkApplication *finder = [[SparkApplication alloc] initWithPath:path];
    if (finder) {
      [finder setUID:kSparkApplicationFinderUID];
      [[self applicationSet] addObject:finder];
      [finder release];
    } else {
      WLog(@"Invalid Finder Application: %@", finder);
    }
  }
}
- (void)saveReservedObjects {
  /* write reserved objects status into preferences */
  SparkApplication *finder = [self applicationWithUID:kSparkApplicationFinderUID];
  if (finder)
    [[self preferences] setObject:WBBool(![finder isEnabled]) forKey:@"SparkFinderDisabled"];
}
- (void)restoreReservedObjects {
  /* called after library loading, restore reserved objects status from preferences */
  SparkApplication *finder = [self applicationWithUID:kSparkApplicationFinderUID];
  if (finder) {
    BOOL disabled = [[[self preferences] objectForKey:@"SparkFinderDisabled"] boolValue];
    [finder setEnabled:!disabled];
  }
}

- (NSFileWrapper *)fileWrapper:(NSError **)outError {
  if (outError) *outError = nil;
  
  /* if not loaded, return disk representation */
  if (![self isLoaded])
    return [self path] ? [[[NSFileWrapper alloc] initWithPath:[self path]] autorelease] : nil;
  
  NSFileWrapper *library = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
  [library setFilename:kSparkLibraryDefaultFileName];
  
  NSFileWrapper *file;
  /* SparkActions */
  file = [[self actionSet] fileWrapper:outError];
  require(file != nil, bail);
  
  [file setPreferredFilename:kSparkActionsFile];
  [library addFileWrapper:file];
  
  /* SparkHotKeys */
  file = [[self triggerSet] fileWrapper:outError];
  require(file != nil, bail);
  
  [file setPreferredFilename:kSparkTriggersFile];
  [library addFileWrapper:file];
  
  /* SparkApplications */
  file = [[self applicationSet] fileWrapper:outError];
  require(file != nil, bail);
  
  [file setPreferredFilename:kSparkApplicationsFile];
  [library addFileWrapper:file];
  
  /* Spark releationships (entries + lists) */
  NSMutableData *archive = [NSMutableData data];
  SparkLibraryArchiver *writer = [[SparkLibraryArchiver alloc] initForWritingWithMutableData:archive];
  [writer encodeObject:[self entryManager] forKey:@"entries"];
  [writer encodeObject:[[self listSet] objects] forKey:@"lists"];
  [writer finishEncoding];
  
  file = [[NSFileWrapper alloc] initRegularFileWithContents:archive];
  require(file != nil, bail);
  
  [file setPreferredFilename:kSparkArchiveFile];
  [library addFileWrapper:file];
  [file release];
  
  [self saveReservedObjects];
  
  /* Preferences */
  NSData *data = [NSPropertyListSerialization dataFromPropertyList:sp_prefs
                                                            format:NSPropertyListXMLFormat_v1_0
                                                  errorDescription:nil];
  if (data)
    [library addRegularFileWithContents:data preferredFilename:kSparkLibraryPreferencesFile];
  
  
  /* Library infos */
  NSString *uuid = sp_uuid ? (id)CFUUIDCreateString(kCFAllocatorDefault, sp_uuid) : nil;
  NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
    WBUInteger(kSparkLibraryCurrentVersion), @"Version",
    uuid, @"UUID",
    nil];
  [uuid release];
  data = [NSPropertyListSerialization dataFromPropertyList:info
                                                    format:NSPropertyListXMLFormat_v1_0
                                          errorDescription:nil];
  require(data != nil, bail);
  
  [library addRegularFileWithContents:data preferredFilename:@"Info.plist"];
  
  return [library autorelease];
  
bail:
  [library release];
  
  if (outError && !*outError) *outError = [NSError errorWithDomain:kSparkErrorDomain code:-1 userInfo:nil];
  return nil;
}

- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)flag {
  NSParameterAssert(file != nil);
  
  NSFileWrapper* wrapper = [self fileWrapper:nil];
  if (wrapper && [wrapper writeToFile:file atomically:flag updateFilenames:NO]) {
    [sp_icons synchronize];
    return YES;
  }
  return NO;  
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError {
  if ([self isLoaded])
    [NSException raise:NSInternalInconsistencyException format:@"<%@ %p> is already loaded.", [self class], self];
  
  NSDictionary *wrappers = [fileWrapper fileWrappers];
  NSData *data = [[wrappers objectForKey:@"Info.plist"] regularFileContents];
  require(data != nil, bail);
  
  NSDictionary *info = [NSPropertyListSerialization propertyListFromData:data 
                                                        mutabilityOption:NSPropertyListImmutable
                                                                  format:NULL
                                                        errorDescription:NULL];
  require(info != nil, bail);
  /* Init info plist */
  [self setInfo:info];
  return [self loadFromWrapper:fileWrapper error:outError];
bail:
    return NO;
}

@end

#pragma mark -
@implementation SparkLibrary (SparkLibraryLoader)

- (void)setInfo:(NSDictionary *)plist {
  if (plist) {
    /* Load uuid */
    NSString *uuid = [plist objectForKey:@"UUID"];
    if (uuid) {
      CFUUIDRef uuidref = CFUUIDCreateFromString(kCFAllocatorDefault, (CFStringRef)uuid);
      if (uuidref) {
        if (sp_uuid) CFRelease(sp_uuid);
        sp_uuid = uuidref;
      }
      NSAssert(sp_uuid != NULL, @"Invalid null UUID");
    } else {
      if (sp_uuid) CFRelease(sp_uuid);
      sp_uuid = CFUUIDCreate(kCFAllocatorDefault);
    }
    /* Library version */
    sp_version = WBIntegerValue([plist objectForKey:@"Version"]);
  } else {
    sp_version = kSparkLibraryCurrentVersion;
    
    if (sp_uuid) CFRelease(sp_uuid);
    sp_uuid = CFUUIDCreate(kCFAllocatorDefault);
  }
}

- (BOOL)loadFromWrapper:(NSFileWrapper *)wrapper error:(NSError **)error {
  NSParameterAssert(![self isLoaded]);
  
  BOOL result = NO;
  
  /* Preferences */
  sp_prefs = [[NSMutableDictionary alloc] init];
  
  /* Create icon manager only for editor */
  if (SparkGetCurrentContext() == kSparkEditorContext && !sp_icons) {
    sp_icons = [[SparkIconManager alloc] initWithLibrary:self path:SparkLibraryIconFolder(self)];
  }
  
  /* Create defaults libraries */
  for (NSUInteger idx = 0; idx < kSparkSetCount; idx++) {
    sp_objects[idx] = [[SparkObjectSet alloc] initWithLibrary:self];
  }
  
  [self initReservedObjects];
  
  if (wrapper) {
    switch (sp_version) {
      case kSparkLibraryVersion_1_0:
        /* Create relation table */
        sp_relations = [[SparkEntryManager alloc] initWithLibrary:self];
        result = [self importv1LibraryFromFileWrapper:wrapper error:error];
        break;
      case kSparkLibraryVersion_2_0:
      case kSparkLibraryVersion_2_1:
        result = [self readLibraryFromFileWrapper:wrapper error:error];
        break;
    }
  } else {
    /* Load an empty/new library */
    result = YES;
		sp_relations = [[SparkEntryManager alloc] initWithLibrary:self];
  }
  
  if (result) {
    WBFlagSet(sp_slFlags.loaded, YES);
    
    SparkObject *object;
    NSMutableArray *invalids = nil;
    SparkEntryManager *manager = [self entryManager];
    
    /* Actions */
    NSEnumerator *objects = [self actionEnumerator];
    while (object = [objects nextObject]) {
      if (![manager containsEntryForAction:(SparkAction *)object]) {
        if (!invalids) invalids = [[NSMutableArray alloc] init];
        [invalids addObject:object];
      }
    }
    if (invalids) {
      [[self actionSet] removeObjectsInArray:invalids];
      DLog(@"Remove orphans actions: %@", invalids);
      [invalids release];
      invalids = nil;
    }
    
    /* Triggers */
    objects = [self triggerEnumerator];
    while (object = [objects nextObject]) {
      if (![manager containsEntryForTrigger:(SparkTrigger *)object]) {
        if (!invalids) invalids = [[NSMutableArray alloc] init];
        [invalids addObject:object];
      }
    }
    if (invalids) {
      [[self triggerSet] removeObjectsInArray:invalids];
      DLog(@"Remove orphans triggers: %@", invalids);
      [invalids release];
    }
    
    [self restoreReservedObjects];
  } else {
    [self unload];
  }
  
  return result;
}

- (BOOL)readLibraryFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)error {
  BOOL ok = NO;
  NSDictionary *files = [wrapper fileWrappers];
  
  /* load preferences */
  NSData *data = [[files objectForKey:kSparkLibraryPreferencesFile] regularFileContents];
  if (data) {
    NSDictionary *prefs = [NSPropertyListSerialization propertyListFromData:data 
                                                           mutabilityOption:NSPropertyListImmutable
                                                                     format:NULL
                                                           errorDescription:NULL];
    if (prefs)
      [sp_prefs setDictionary:prefs];
  }
  
  SparkObjectSet *set = [self actionSet];
  ok = [set readFromFileWrapper:[files objectForKey:kSparkActionsFile] error:error];
  require(ok, bail);
  
  set = [self triggerSet];
  ok = [set readFromFileWrapper:[files objectForKey:kSparkTriggersFile] error:error];
  require(ok, bail);
  
  set = [self applicationSet];
  ok = [set readFromFileWrapper:[files objectForKey:kSparkApplicationsFile] error:error];
  require(ok, bail);

  switch (sp_version) {
    case kSparkLibraryVersion_2_0:
      sp_relations = [[SparkEntryManager alloc] initWithLibrary:self];
      ok = [sp_relations readFromFileWrapper:[files objectForKey:@"SparkEntries"] error:error];
      require(ok, bail);
      /* convert trigger list into entry list */
      ok = [self importTriggerListFromFileWrapper:[files objectForKey:@"SparkLists"] error:error];
      require(ok, bail);
      break;
    case kSparkLibraryVersion_2_1: {
      data = [[files objectForKey:kSparkArchiveFile] regularFileContents];
      SparkLibraryUnarchiver *reader = [[SparkLibraryUnarchiver alloc] initForReadingWithData:data library:self];
      /* decode entry manager */
      sp_relations = [[reader decodeObjectForKey:@"entries"] retain];
      /* decode lists */
      NSArray *lists = [reader decodeObjectForKey:@"lists"];
      if (lists)
        [[self listSet] addObjectsFromArray:lists];
      [reader release];
    }
      break;
  }
  
  return YES;
bail:
  return NO;
}

@end

#pragma mark -
#pragma mark Utilities Functions
static
NSString *_SparkLibraryCopyUUIDString(SparkLibrary *aLibrary) {
  CFUUIDRef uuid = [aLibrary uuid];
  return uuid ? (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid) : NULL;
}

NSString *SparkLibraryFolder() {
  NSString *folder = [WBFSFindFolder(kApplicationSupportFolderType, kUserDomain, true) stringByAppendingPathComponent:kSparkFolderName];
  if (folder && ![[NSFileManager defaultManager] fileExistsAtPath:folder]) {
    WBFSCreateFolder((CFStringRef)folder);
  }
  return folder;
}

NSString *SparkLibraryIconFolder(SparkLibrary *library) {
  NSCParameterAssert([library uuid]);
  NSString *icons = [SparkLibraryFolder() stringByAppendingPathComponent:@"Icons"];
  NSString *uuidstr = _SparkLibraryCopyUUIDString(library);
  if (uuidstr) {
    icons = [icons stringByAppendingPathComponent:(id)uuidstr];
    [uuidstr release];
  } else {
    [NSException raise:NSInternalInconsistencyException format:@"Error while creating string from uuid"];
  }
  return icons;
}

static
NSString *SparkLibraryPreviousLibraryPath() {
  NSString *folder = [WBFSFindFolder(kPreferencesFolderType, kUserDomain, false) stringByAppendingPathComponent:kSparkFolderName];
  return [folder stringByAppendingPathComponent:@"Spark3 Library.splib"];
}
static
NSString *SparkLibraryVersion1LibraryPath() {
  NSString *folder = [WBFSFindFolder(kPreferencesFolderType, kUserDomain, false) stringByAppendingPathComponent:kSparkFolderName];
  return [folder stringByAppendingPathComponent:@"SparkLibrary.splib"];
}

WB_INLINE 
NSString *SparkDefaultLibraryPath(void) {
  return [SparkLibraryFolder() stringByAppendingPathComponent:kSparkLibraryDefaultFileName];
}

#pragma mark Multi Library Support
static
NSMutableArray *sLibraries = nil;

static
void SparkLibraryCleanup() {
  if (SparkGetCurrentContext() == kSparkEditorContext) {
    NSMutableArray *uuids = [[NSMutableArray alloc] init];
    NSUInteger cnt = [sLibraries count];
    while (cnt-- > 0) {
      SparkLibrary *lib = [sLibraries objectAtIndex:cnt];
      NSString *uuidstr = _SparkLibraryCopyUUIDString(lib);
      if (uuidstr) {
        [uuids addObject:uuidstr];
        [uuidstr release];
      }
    }
    /* Browse icons folder and remove folder without libraries */
    NSString *file;
    NSString *folder = [SparkLibraryFolder() stringByAppendingPathComponent:@"Icons"];
    NSEnumerator *files = [[[NSFileManager defaultManager] directoryContentsAtPath:folder] objectEnumerator];
    while (file = [files nextObject]) {
      if (![uuids containsObject:file]) {
        DLog(@"Remove icons: %@", file);
        [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceDestroyOperation
                                                     source:folder
                                                destination:nil
                                                      files:[NSArray arrayWithObject:file]
                                                        tag:NULL];
      }
    }
    [uuids release];
  }
}

static 
void SparkInitLibraries() {
  if (sLibraries)
    return;
  
  sLibraries = [[NSMutableArray alloc] init];
  
  NSString *file = nil;
  NSString *folder = SparkLibraryFolder();
  NSEnumerator *files = [[[NSFileManager defaultManager] directoryContentsAtPath:folder] objectEnumerator];
  while (file = [files nextObject]) {
    if ([[file pathExtension] isEqualToString:kSparkLibraryFileExtension]) {
      /* Find a Spark Library */
      SparkLibrary *library = [[SparkLibrary alloc] initWithPath:[folder stringByAppendingPathComponent:file]];
      if (library) {
        [sLibraries addObject:library];
      }
    }
  }
  
  SparkLibraryCleanup();
}

SparkLibrary *SparkLibraryGetLibraryAtPath(NSString *path, BOOL create) {
  if (!sLibraries) SparkInitLibraries();
  
  NSUInteger cnt = [sLibraries count];
  path = [path stringByStandardizingPath];
  while (cnt-- > 0) {
    SparkLibrary *lib = [sLibraries objectAtIndex:cnt];
    if ([lib path] && [[lib path] isEqualToString:path])
      return lib;
  }
  SparkLibrary *library = nil;
  if (create) {
    library = [[SparkLibrary alloc] initWithPath:path];
    [sLibraries addObject:library];
    [library release];
  }
  return library;
}

SparkLibrary *SparkLibraryGetLibraryWithUUID(CFUUIDRef uuid) {
  if (!sLibraries) SparkInitLibraries();
  
  NSUInteger cnt = [sLibraries count];
  while (cnt-- > 0) {
    SparkLibrary *lib = [sLibraries objectAtIndex:cnt];
    NSCAssert([lib uuid] != NULL, @"Invalid Library (null uuid)");
    if (CFEqual([lib uuid], uuid))
      return lib;
  }
  return nil;
}

void SparkLibraryDeleteIconCache(SparkLibrary *library) {
  /* Remove icon cache */
  NSString *icons = [[library iconManager] path];
  if (icons) {
    NSString *parent = [icons stringByDeletingLastPathComponent];
    if (parent) {
      [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceDestroyOperation
                                                   source:parent
                                              destination:nil
                                                    files:[NSArray arrayWithObject:[icons lastPathComponent]]
                                                      tag:NULL];
    }
  }
}

void SparkLibraryRegisterLibrary(SparkLibrary *library) {
  if (sLibraries && ![sLibraries containsObject:library])
    [sLibraries addObject:library];
}

void SparkLibraryUnregisterLibrary(SparkLibrary *library) {
  if (sLibraries) {
    [sLibraries removeObject:library];
  }
}

static SparkLibrary *sActiveLibrary = nil;
SparkLibrary *SparkActiveLibrary() {
  static bool loading = false;
  if (!sActiveLibrary) {
    if (loading) {
      [NSException raise:NSInternalInconsistencyException format:@"%s() is not reentrant", __func__];
    }
    
    loading = true;
    BOOL resync = NO;
    /* Get default library path */
    NSString *path = SparkDefaultLibraryPath();
    SparkLibrary *active = SparkLibraryGetLibraryAtPath(path, NO);
    if (!active) {
      /* First, try to find library in old location */
      NSString *old = SparkLibraryPreviousLibraryPath();
      if (![[NSFileManager defaultManager] fileExistsAtPath:old]) {
        /* Try to find an old version library */
        old = SparkLibraryVersion1LibraryPath();
        if ([[NSFileManager defaultManager] fileExistsAtPath:old]) {
          resync = YES;
          active = [[SparkLibrary alloc] initWithPath:old];
        } else {
          resync = YES;
          active = [[SparkLibrary alloc] init];
        }
      } else {
        /* Version 3 library exists in old location */
        if ([[NSFileManager defaultManager] movePath:old toPath:path handler:nil]) {
          active = [[SparkLibrary alloc] initWithPath:path];
        } else {
          resync = YES;
          active = [[SparkLibrary alloc] initWithPath:old];
        }
      }
    }
    
    /* Read library */
    if (![active isLoaded] && ![active load:nil]) {
      loading = false;
      [active release];
      active = nil;
      [NSException raise:NSInternalInconsistencyException format:@"An error prevent default library loading"];
    } else if (resync) {
      [active setPath:path];
      [active synchronize];
    }
    if (active) {
      SparkSetActiveLibrary(active);
      [active release];
    }
    loading = false;
  }
  return sActiveLibrary;
}

BOOL SparkSetActiveLibrary(SparkLibrary *library) {
  NSCParameterAssert(!library || [library isLoaded]);
  if (sActiveLibrary != library) {
    // will set active library
    [[NSNotificationCenter defaultCenter]
      postNotificationName:SparkWillSetActiveLibraryNotification object:sActiveLibrary];
    
    SparkLibraryRegisterLibrary(library);
    [sActiveLibrary release];
    sActiveLibrary = [library retain];
    // did set active library
    [[NSNotificationCenter defaultCenter]
      postNotificationName:SparkDidSetActiveLibraryNotification object:sActiveLibrary];
  }
  // Notify
  return YES;
}

#pragma mark -
void SparkDumpTriggers(SparkLibrary *aLibrary) {
  SparkTrigger *trigger = nil;
  NSEnumerator *triggers = [aLibrary triggerEnumerator];
  fprintf(stderr, "Triggers: %lu\n {", (long)[[aLibrary triggerSet] count]);
  while (trigger = [triggers nextObject]) {
    fprintf(stderr, "\t- %u: %s\n", [trigger uid], [[trigger triggerDescription] UTF8String]);
  }
  fprintf(stderr, "}\n");
}

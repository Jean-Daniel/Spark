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

#import <WonderBox/WonderBox.h>

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
NSString * const kSparkLibraryDefaultFileName = @"Spark Library - Debug.splib";
#else
NSString * const kSparkLibraryDefaultFileName = @"Spark Library.splib";
#endif

static
NSURL *SparkLibraryIconFolder(SparkLibrary *library);

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
- (BOOL)importTriggerListFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)error;
@end

@interface SparkEntryManager (SparkVersion1Library)
- (void)removeEntriesForAction:(SparkUID)action;
@end

@implementation SparkLibrary {
@private
  NSUUID *_uuid;
  NSUInteger _version;

  SparkObjectSet *_objects[4];
  SparkEntryManager *_relations;

  struct _sp_slFlags {
    unsigned int loaded:1;
    unsigned int unnotify:8;
    unsigned int syncPrefs:1;
    unsigned int reserved:22;
  } _slFlags;

  /* Model synchronization */
  NSNotificationCenter *_center;

  /* Preferences */
  NSMutableDictionary *_prefs;
  SparkPreference *_preferences;

  /* reserved objects */
  SparkApplication *_system;
}

@synthesize URL = _url;

+ (void)initialize {
  if ([SparkLibrary class] == self) {
    /* Register Built-In PlugIn (and make sure other plugins are loaded) */
    [[SparkActionLoader sharedLoader] loadPlugIns];
    [[SparkActionLoader sharedLoader] registerPlugInClass:[SparkBuiltInActionPlugIn class]];
  }
}

- (SparkApplication *)systemApplication {
  if (!_system) {
    _system = [SparkApplication systemApplication];
    [_system setLibrary:self];
  }
  return _system;
}

#pragma mark -
- (id)init {
  if (self = [self initWithURL:nil]) {
    /* Init infos */
    [self setInfo:nil];
    /* Load empty library */
    [self loadFromWrapper:nil error:nil];
  }
  return self;
}

- (id)initWithURL:(NSURL *)anURL {
  if (self = [super init]) {
    [self setURL:anURL];
  }
  return self;
}

- (void)dealloc {
  /* Avoid useless undo */
  _undoManager = nil;
  
  /* Unload library */
  if ([self isLoaded])
    [self unload];
}

- (NSUInteger)hash {
  return _uuid ? _uuid.hash : 0;
}

- (BOOL)isEqual:(id)object {
  if (![[object class] isSubclassOfClass:[self class]])
    return NO;
  if (!_uuid) return ![object uuid];
  if (![object uuid]) return !_uuid;
  return [_uuid isEqual:[object uuid]];
}

#pragma mark -
#pragma mark Managers Accessors
- (SparkEntryManager *)entryManager {
  return _relations;
}

- (SparkIconManager *)iconManager {
  return _icons;
}

- (SparkObjectSet *)listSet {
  return _objects[kSparkListSet];
}
- (SparkObjectSet *)actionSet {
  return _objects[kSparkActionSet];
}
- (SparkObjectSet *)triggerSet {
  return _objects[kSparkTriggerSet];
}
- (SparkObjectSet *)applicationSet {
  return _objects[kSparkApplicationSet];
}

#pragma mark -
- (void)enableNotifications {
	NSParameterAssert(_slFlags.unnotify > 0);
  _slFlags.unnotify--;
}

- (void)disableNotifications {
	NSParameterAssert(_slFlags.unnotify < 255);
  _slFlags.unnotify++;
}

- (NSNotificationCenter *)notificationCenter {
  if (_slFlags.unnotify > 0) {
		return nil;
	}
  
  if (!_center) {
    _center = [[NSNotificationCenter alloc] init];
  }
  return _center;
}

#pragma mark Preferences
- (SparkPreference *)preferences {
  if (!_preferences)
    _preferences = [[SparkPreference alloc] initWithLibrary:self];
  return _preferences;
}

#pragma mark FileSystem Methods
- (void)setURL:(NSURL *)url {
  if (url != _url) {
    _url = [url URLByStandardizingPath];
    
    if (![self isLoaded]) {
      /* Init UUID & version */
      NSURL *path = _url ? [_url URLByAppendingPathComponent:@"Info.plist"] : nil;
      NSDictionary *dict = path ? [[NSDictionary alloc] initWithContentsOfURL:path] : nil;
      [self setInfo:dict];
    }
    /* Update icon path */
    if (_icons && !_icons.URL && _url)
      _icons.URL = SparkLibraryIconFolder(self);
  }
}

- (BOOL)synchronize {
  if (self.URL) {
    if ([self isLoaded]) {
      if ([self writeToURL:self.URL atomically:YES]) {
        _version = kSparkLibraryCurrentVersion;
        return YES;
      }
    } else {
      spx_debug("WARNING: sync unloaded library");
    }
  } else {
    SPXThrowException(NSInvalidArgumentException, @"You must set a file before synchronizing");
  }
  return NO;
}

- (BOOL)isLoaded {
  return _slFlags.loaded;
}

- (BOOL)load:(__autoreleasing NSError **)error {
  if ([self isLoaded])
    SPXThrowException(NSInternalInconsistencyException, @"<%@ %p> is already loaded.", [self class], self);
  
  BOOL result = NO;
  /* disable undo while loading */
  [_undoManager disableUndoRegistration];
  
  NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithURL:self.URL options:0 error:error];
  if (wrapper) {
    @try {
      result = [self loadFromWrapper:wrapper error:error];
    } @catch (id exception) {
      result = NO;
      spx_log_exception(exception);
      if (error)
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
    }
  }
  /* restaure undo manager */
  [_undoManager enableUndoRegistration];
  
  return result;
}

- (void)unload {
  if (![self isLoaded])
    SPXThrowException(NSInternalInconsistencyException, @"<%@ %p> is not loaded.", [self class], self);
  
  SPXFlagSet(_slFlags.loaded, NO);
  
  /* Preferences */
  _prefs = nil;
  
  /* Release relation table */
  [_relations setLibrary:nil];
  _relations = nil;
  
  /* Release defaults libraries */
  NSInteger idx = kSparkSetCount;
  while (idx-- > 0) {
    // _objects[idx].library = nil;
    _objects[idx] = nil;
  }
  
  /* Release Icon cache */
  _icons = nil;
}

#pragma mark Read/Write
- (void)initReservedObjects {
  /* Init Finder Application */
  NSURL *url = [NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:kSparkFinderBundleIdentifier];
	if (!url && ![@"com.apple.finder" isEqualToString:kSparkFinderBundleIdentifier]) {
		spx_log("invalid finder application, try with default identifier ('MACS')");
		url = [NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:@"com.apple.finder"];
	}
  if (url) {
    SparkApplication *finder = [[SparkApplication alloc] initWithURL:url];
    if (finder) {
      finder.uid = kSparkApplicationFinderUID;
      [self.applicationSet addObject:finder];
    } else {
      spx_log("Invalid Finder Application: %@", finder);
    }
  }
}

- (void)saveReservedObjects {
  /* write reserved objects status into preferences */
  SparkApplication *finder = [self applicationWithUID:kSparkApplicationFinderUID];
  if (finder)
    [[self prefStorage] setObject:@(![finder isEnabled]) forKey:@"SparkFinderDisabled"];
}

- (void)restoreReservedObjects {
  /* called after library loading, restore reserved objects status from preferences */
  SparkApplication *finder = [self applicationWithUID:kSparkApplicationFinderUID];
  if (finder) {
    BOOL disabled = [[self prefStorage][@"SparkFinderDisabled"] boolValue];
    [finder setEnabled:!disabled];
  }
}

- (NSFileWrapper *)fileWrapper:(__autoreleasing NSError **)outError {
  if (outError)
    *outError = nil;
  
  /* if not loaded, return disk representation */
  if (![self isLoaded])
    return self.URL ? [[NSFileWrapper alloc] initWithURL:self.URL options:0 error:outError] : nil;

  NSMutableDictionary *files = [NSMutableDictionary dictionary];
  do {
    NSFileWrapper *file;
    /* SparkActions */
    file = [[self actionSet] fileWrapper:outError];
    if (!file) break;
    files[kSparkActionsFile] = file;

    /* SparkHotKeys */
    file = [[self triggerSet] fileWrapper:outError];
    if (!file) break;
    files[kSparkTriggersFile] = file;

    /* SparkApplications */
    file = [[self applicationSet] fileWrapper:outError];
    if (!file) break;
    files[kSparkApplicationsFile] = file;

    /* Spark releationships (entries + lists) */
    NSMutableData *archive = [NSMutableData data];
    SparkLibraryArchiver *writer = [[SparkLibraryArchiver alloc] initForWritingWithMutableData:archive];
    [writer encodeObject:self.entryManager forKey:@"entries"];
    [writer encodeObject:self.listSet.allObjects forKey:@"lists"];
    [writer finishEncoding];

    file = [[NSFileWrapper alloc] initRegularFileWithContents:archive];
    if (!file) break;
    files[kSparkArchiveFile] = file;

    [self saveReservedObjects];

    NSFileWrapper *library = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:files];
    [library setFilename:kSparkLibraryDefaultFileName];

    /* Preferences */
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:_prefs
                                                              format:NSPropertyListXMLFormat_v1_0
                                                             options:0 error:NULL];
    if (data)
      [library addRegularFileWithContents:data preferredFilename:kSparkLibraryPreferencesFile];

    /* Library infos */
    NSDictionary *info = @{ @"Version": @(kSparkLibraryCurrentVersion),
                            @"UUID": [_uuid UUIDString] };
    data = [NSPropertyListSerialization dataWithPropertyList:info
                                                      format:NSPropertyListXMLFormat_v1_0
                                                     options:0 error:NULL];
    if (!data) break;
    
    [library addRegularFileWithContents:data preferredFilename:@"Info.plist"];
    
    return library;
  } while (0);
  if (outError)
    *outError = [NSError errorWithDomain:kSparkErrorDomain code:-1 userInfo:nil];
  return nil;
}

- (BOOL)writeToURL:(NSURL *)file atomically:(BOOL)flag {
  NSParameterAssert(file != nil);
  
  NSFileWrapper* wrapper = [self fileWrapper:nil];
  if ([wrapper writeToURL:file options:NSFileWrapperWritingAtomic
      originalContentsURL:nil error:NULL]) {
    [_icons synchronize];
    return YES;
  }
  return NO;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError * __autoreleasing *)outError {
  if ([self isLoaded])
    SPXThrowException(NSInternalInconsistencyException, @"<%@ %p> is already loaded.", [self class], self);
  
  NSDictionary *wrappers = [fileWrapper fileWrappers];
  NSData *data = [wrappers[@"Info.plist"] regularFileContents];
  if (!data)
    return NO;
  
  NSDictionary *info = [NSPropertyListSerialization propertyListWithData:data
                                                                 options:NSPropertyListImmutable
                                                                  format:NULL error:NULL];
  if (!info)
    return NO;
  /* Init info plist */
  [self setInfo:info];
  return [self loadFromWrapper:fileWrapper error:outError];
}

@end

#pragma mark -
@implementation SparkLibrary (SparkLibraryLoader)

- (void)setInfo:(NSDictionary *)plist {
  if (plist) {
    /* Load uuid */
    NSString *uuid = plist[@"UUID"];
    if (uuid) {
      _uuid = [[NSUUID alloc] initWithUUIDString:uuid];
      NSAssert(_uuid != NULL, @"Invalid null UUID");
    } else {
      _uuid = [NSUUID UUID];
    }
    /* Library version */
    _version = [plist[@"Version"] integerValue];
  } else {
    _version = kSparkLibraryCurrentVersion;
    _uuid = [NSUUID UUID];
  }
}

- (BOOL)loadFromWrapper:(NSFileWrapper *)wrapper error:(NSError * __autoreleasing *)error {
  NSParameterAssert(![self isLoaded]);
  
  BOOL result = NO;
  
  /* Preferences */
  _prefs = [[NSMutableDictionary alloc] init];
  
  /* Create icon manager only for editor */
  if (SparkGetCurrentContext() == kSparkContext_Editor && !_icons) {
    _icons = [[SparkIconManager alloc] initWithLibrary:self URL:SparkLibraryIconFolder(self)];
  }
  
  /* Create defaults libraries */
  for (NSUInteger idx = 0; idx < kSparkSetCount; idx++) {
    _objects[idx] = [[SparkObjectSet alloc] initWithLibrary:self];
  }
  
  [self initReservedObjects];
  
  if (wrapper) {
    switch (_version) {
      case kSparkLibraryVersion_1_0:
        if (error)
          *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
        return NO;
      case kSparkLibraryVersion_2_0:
      case kSparkLibraryVersion_2_1:
        result = [self readLibraryFromFileWrapper:wrapper error:error];
        break;
    }
  } else {
    /* Load an empty/new library */
    result = YES;
		_relations = [[SparkEntryManager alloc] initWithLibrary:self];
  }
  
  if (result) {
    SPXFlagSet(_slFlags.loaded, YES);
    
    __block NSMutableArray *invalids = nil;
    SparkEntryManager *manager = [self entryManager];
    
    /* Actions */
    [self.actionSet enumerateObjectsUsingBlock:^(SparkAction *action, BOOL *stop) {
      if (![manager containsEntryForAction:action]) {
        if (!invalids)
          invalids = [[NSMutableArray alloc] init];
        [invalids addObject:action];
      }
    }];
    if (invalids) {
      [self.actionSet removeObjectsInArray:invalids];
      spx_debug("Remove orphans actions: %@", invalids);
      invalids = nil;
    }
    
    /* Triggers */
    [self.triggerSet enumerateObjectsUsingBlock:^(SparkTrigger *trigger, BOOL *stop) {
      if (![manager containsEntryForTrigger:trigger]) {
        if (!invalids)
          invalids = [[NSMutableArray alloc] init];
        [invalids addObject:trigger];
      }
    }];
    if (invalids) {
      [self.triggerSet removeObjectsInArray:invalids];
      spx_debug("Remove orphans triggers: %@", invalids);
    }
    
    [self restoreReservedObjects];
  } else {
    [self unload];
  }
  
  return result;
}

- (BOOL)readLibraryFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError * __autoreleasing *)error {
  BOOL ok = NO;
  NSDictionary *files = [wrapper fileWrappers];
  
  /* load preferences */
  NSData *data = [files[kSparkLibraryPreferencesFile] regularFileContents];
  if (data) {
    NSDictionary *prefs = [NSPropertyListSerialization propertyListWithData:data
                                                                    options:NSPropertyListImmutable
                                                                     format:NULL error:NULL];
    if (prefs)
      [_prefs setDictionary:prefs];
  }
  
  SparkObjectSet *set = self.actionSet;
  ok = [set readFromFileWrapper:files[kSparkActionsFile] error:error];
  spx_require(ok, bail);
  
  set = self.triggerSet;
  ok = [set readFromFileWrapper:files[kSparkTriggersFile] error:error];
  spx_require(ok, bail);
  
  set = self.applicationSet;
  ok = [set readFromFileWrapper:files[kSparkApplicationsFile] error:error];
  spx_require(ok, bail);

  switch (_version) {
    case kSparkLibraryVersion_2_0:
      _relations = [[SparkEntryManager alloc] initWithLibrary:self];
      ok = [_relations readFromFileWrapper:files[@"SparkEntries"] error:error];
      spx_require(ok, bail);
      /* convert trigger list into entry list */
      ok = [self importTriggerListFromFileWrapper:files[@"SparkLists"] error:error];
      spx_require(ok, bail);
      break;
    case kSparkLibraryVersion_2_1: {
      data = [files[kSparkArchiveFile] regularFileContents];
      SparkLibraryUnarchiver *reader = [[SparkLibraryUnarchiver alloc] initForReadingWithData:data library:self];
      /* decode entry manager */
      _relations = [reader decodeObjectForKey:@"entries"];
      /* decode lists */
      NSArray *lists = [reader decodeObjectForKey:@"lists"];
      if (lists)
        [[self listSet] addObjectsFromArray:lists];
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
  return [aLibrary.uuid UUIDString];
}

NSURL *SparkLibraryFolder(void) {
  NSURL *url = [NSFileManager.defaultManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
  NSURL *folder = [url URLByAppendingPathComponent:kSparkFolderName];
  if (folder && ![url checkResourceIsReachableAndReturnError:NULL]) {
    [[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:NULL];
  }
  return folder;
}

NSURL *SparkLibraryIconFolder(SparkLibrary *library) {
  NSCParameterAssert([library uuid]);
  NSURL *icons = [SparkLibraryFolder() URLByAppendingPathComponent:@"Icons"];
  NSString *uuidstr = _SparkLibraryCopyUUIDString(library);
  if (uuidstr) {
    icons = [icons URLByAppendingPathComponent:uuidstr];
  } else {
    SPXThrowException(NSInternalInconsistencyException, @"Error while creating string from uuid");
  }
  return icons;
}

static
NSURL *SparkLibraryPreviousLibraryPath(void) {
  NSURL *url = [NSFileManager.defaultManager URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL];
  NSURL *folder = [[url URLByAppendingPathComponent:@"Preferences"] URLByAppendingPathComponent:kSparkFolderName];
  return [folder URLByAppendingPathComponent:@"Spark3 Library.splib"];
}

static
NSURL *SparkLibraryVersion1LibraryPath(void) {
  NSURL *url = [NSFileManager.defaultManager URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL];
  NSURL *folder = [[url URLByAppendingPathComponent:@"Preferences"] URLByAppendingPathComponent:kSparkFolderName];
  return [folder URLByAppendingPathComponent:@"SparkLibrary.splib"];
}

WB_INLINE 
NSURL *SparkDefaultLibraryPath(void) {
  return [SparkLibraryFolder() URLByAppendingPathComponent:kSparkLibraryDefaultFileName];
}

#pragma mark Multi Library Support
static
NSMutableArray *sLibraries = nil;

static
void SparkLibraryCleanup(void) {
  if (SparkGetCurrentContext() == kSparkContext_Editor) {
    NSMutableArray *uuids = [[NSMutableArray alloc] init];
    for (SparkLibrary *lib in sLibraries) {
      NSString *uuidstr = _SparkLibraryCopyUUIDString(lib);
      if (uuidstr)
        [uuids addObject:uuidstr];
    }
    /* Browse icons folder and remove folder without libraries */
    NSURL *file;
    NSURL *folder = [SparkLibraryFolder() URLByAppendingPathComponent:@"Icons"];
    NSDirectoryEnumerator *files = [[NSFileManager defaultManager] enumeratorAtURL:folder
                                                        includingPropertiesForKeys:nil
                                                                           options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                      errorHandler:nil];
    while (file = [files nextObject]) {
      if (![uuids containsObject:file.lastPathComponent]) {
        spx_debug("Remove icons: %@", file);
        [[NSFileManager defaultManager] removeItemAtURL:file error:NULL];
      }
    }
  }
}

static 
void SparkInitLibraries(void) {
  if (sLibraries) return;
  
  sLibraries = [[NSMutableArray alloc] init];

  NSURL *folder = SparkLibraryFolder();
  NSDirectoryEnumerator *files = [[NSFileManager defaultManager] enumeratorAtURL:folder
                                                      includingPropertiesForKeys:nil
                                                                         options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                    errorHandler:nil];
  for (NSURL *file in files) {
    if ([file.pathExtension isEqualToString:kSparkLibraryFileExtension]) {
      /* Find a Spark Library */
      SparkLibrary *library = [[SparkLibrary alloc] initWithURL:file];
      if (library)
        [sLibraries addObject:library];
    }
  }
  
  SparkLibraryCleanup();
}

SparkLibrary *SparkLibraryGetLibraryAtURL(NSURL *url, BOOL create) {
  if (!sLibraries)
    SparkInitLibraries();

  url = [NSURL URLByResolvingAliasFileAtURL:url options:NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithoutMounting error:NULL];
  if (!url)
    return nil;

  for (SparkLibrary *lib in sLibraries) {
    if ([lib.URL isEqual:url])
      return lib;
  }
  SparkLibrary *library = nil;
  if (create) {
    library = [[SparkLibrary alloc] initWithURL:url];
    [sLibraries addObject:library];
  }
  return library;
}

SparkLibrary *SparkLibraryGetLibraryWithUUID(NSUUID *uuid) {
  if (!sLibraries)
    SparkInitLibraries();

  for (SparkLibrary *lib in sLibraries) {
    NSCAssert(lib.uuid != NULL, @"Invalid Library (null uuid)");
    if ([lib.uuid isEqual:uuid])
      return lib;
  }
  return nil;
}

void SparkLibraryDeleteIconCache(SparkLibrary *library) {
  /* Remove icon cache */
  NSURL *icons = library.iconManager.URL;
  if (icons)
    [[NSFileManager defaultManager] removeItemAtURL:icons error:NULL];
}

void SparkLibraryRegisterLibrary(SparkLibrary *library) {
  if (sLibraries && ![sLibraries containsObject:library])
    [sLibraries addObject:library];
}

void SparkLibraryUnregisterLibrary(SparkLibrary *library) {
  if (sLibraries)
    [sLibraries removeObject:library];
}

static SparkLibrary *sActiveLibrary = nil;
SparkLibrary *SparkActiveLibrary(void) {
  static bool loading = false;
  if (!sActiveLibrary) {
    if (loading) {
      SPXThrowException(NSInternalInconsistencyException, @"%s() is not reentrant", __func__);
    }
    
    loading = true;
    BOOL resync = NO;
    /* Get default library path */
    NSURL *path = SparkDefaultLibraryPath();
    SparkLibrary *active = SparkLibraryGetLibraryAtURL(path, NO);
    if (!active) {
      /* First, try to find library in old location */
      NSURL *old = SparkLibraryPreviousLibraryPath();
      if (![old checkResourceIsReachableAndReturnError:NULL]) {
        /* Try to find an old version library */
        old = SparkLibraryVersion1LibraryPath();
        if ([old checkResourceIsReachableAndReturnError:NULL]) {
          resync = YES;
          active = [[SparkLibrary alloc] initWithURL:old];
        } else {
          resync = YES;
          active = [[SparkLibrary alloc] init];
        }
      } else {
        /* Version 3 library exists in old location */
        if ([[NSFileManager defaultManager] moveItemAtURL:old toURL:path error:NULL]) {
          active = [[SparkLibrary alloc] initWithURL:path];
        } else {
          resync = YES;
          active = [[SparkLibrary alloc] initWithURL:old];
        }
      }
    }
    
    /* Read library */
    if (![active isLoaded] && ![active load:nil]) {
      loading = false;
      active = nil;
      SPXThrowException(NSInternalInconsistencyException, @"An error prevent default library loading");
    } else if (resync) {
      active.URL = path;
      [active synchronize];
    }
    if (active)
      SparkSetActiveLibrary(active);
    loading = false;
  }
  return sActiveLibrary;
}

bool SparkSetActiveLibrary(SparkLibrary *library) {
  NSCParameterAssert(!library || [library isLoaded]);
  if (sActiveLibrary != library) {
    // will set active library
    [[NSNotificationCenter defaultCenter]
      postNotificationName:SparkWillSetActiveLibraryNotification object:sActiveLibrary];
    
    SparkLibraryRegisterLibrary(library);
    sActiveLibrary = library;
    // did set active library
    [[NSNotificationCenter defaultCenter]
      postNotificationName:SparkDidSetActiveLibraryNotification object:sActiveLibrary];
  }
  // Notify
  return YES;
}

#pragma mark -
void SparkDumpTriggers(SparkLibrary *aLibrary) {
  fprintf(stderr, "Triggers: %lu\n {", (long)[[aLibrary triggerSet] count]);
  [aLibrary.triggerSet enumerateObjectsUsingBlock:^(SparkTrigger *trigger, BOOL *stop) {
    fprintf(stderr, "\t- %u: %s\n", trigger.uid, [trigger.triggerDescription UTF8String]);
  }];
  fprintf(stderr, "}\n");
}


#pragma mark -
@implementation SparkLibrary (SparkPreferences)

- (NSMutableDictionary *)prefStorage {
  if (![self isLoaded]) {
    spx_debug("Warning, trying to access preferences but library no loaded");
  }
  return _prefs;
}

@end

@implementation SparkLibrary (SparkPreferencesPrivate)

- (BOOL)synchronizePreferences {
  if (_slFlags.syncPrefs)
    return [self synchronize];
  return YES;
}

- (id)preferenceValueForKey:(NSString *)key {
  return [self prefStorage][key];
}

- (void)setPreferenceValue:(id)value forKey:(NSString *)key {
  _slFlags.syncPrefs = 1;
  if (value) {
    [[self prefStorage] setObject:value forKey:key];
  } else {
    [[self prefStorage] removeObjectForKey:key];
  }
}

@end

#pragma mark -
#pragma mark Internal
@implementation SparkLibrary (SparkLibraryInternal)

/* convenient accessors */
- (SparkList *)listWithUID:(SparkUID)uid {
  return [_objects[kSparkListSet] objectWithUID:uid];
}

- (SparkEntry *)entryWithUID:(SparkUID)uid {
  return [_relations entryWithUID:uid];
}

- (SparkAction *)actionWithUID:(SparkUID)uid {
  return [_objects[kSparkActionSet] objectWithUID:uid];
}

- (SparkTrigger *)triggerWithUID:(SparkUID)uid {
  return [_objects[kSparkTriggerSet] objectWithUID:uid];
}

- (SparkApplication *)applicationWithUID:(SparkUID)uid {
  if (kSparkApplicationSystemUID == uid)
    return [self systemApplication];
  return [_objects[kSparkApplicationSet] objectWithUID:uid];
}

@end

@implementation SparkLibrary (SparkLegacyReader)

- (BOOL)importTriggerListFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError * __autoreleasing *)outError {
  do {
    NSData *data = [wrapper regularFileContents];
    if (!data)
      break;

    NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:data
                                                                    options:NSPropertyListImmutable
                                                                     format:NULL
                                                                      error:outError];
    if (!plist)
      return NO;

    NSArray *lists = plist[@"SparkObjects"];
    for (NSDictionary *object in lists) {
      SparkList *list = [SparkList objectWithName:object[@"SparkObjectName"]];
      /* convert trigger into entry */
      NSArray *uids = object[@"SparkObjects"];
      for (id num in uids) {
        SparkUID uid = [num unsignedIntValue];
        SparkTrigger *trigger = [self triggerWithUID:uid];
        if (trigger) {
          SparkEntry *entry = [_relations entryForTrigger:trigger application:[self systemApplication]];
          if (entry)
            [list addEntry:entry];
        }
      }
      [self.listSet addObject:list];
    }

    return YES;
  } while (0);
  if (outError && !*outError)
    *outError = [NSError errorWithDomain:kSparkErrorDomain code:-1 userInfo:nil];
  return NO;
}

@end

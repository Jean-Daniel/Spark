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
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkFunctions.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkIconManager.h>
#import <SparkKit/SparkBuiltInAction.h>

#import <ShadowKit/SKCFContext.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKLSFunctions.h>
#import <ShadowKit/SKSerialization.h>
#import <ShadowKit/SKAppKitExtensions.h>

NSString * const kSparkLibraryFileExtension = @"splib";

NSPropertyListFormat SparkLibraryFileFormat = NSPropertyListBinaryFormat_v1_0;

static NSString * const kSparkListsFile = @"SparkLists";
static NSString * const kSparkActionsFile = @"SparkActions";
static NSString * const kSparkEntriesFile = @"SparkEntries";
static NSString * const kSparkTriggersFile = @"SparkTriggers";
static NSString * const kSparkApplicationsFile = @"SparkApplications";

enum {
  kSparkActionSet = 0,
  kSparkTriggerSet = 1,
  kSparkApplicationSet = 2,
  /* MUST be last */
  kSparkListSet = 3
};

#define kSparkSetCount   4

#ifdef DEBUG
#warning Using Development Spark Library
NSString * const kSparkLibraryDefaultFileName = @"Spark Library_Debug.splib";
#else
NSString * const kSparkLibraryDefaultFileName = @"Spark Library.splib";
#endif

static
NSString *SparkLibraryIconFolder(SparkLibrary *library);

/* Notifications */
NSString * const SparkNotificationObjectKey = @"SparkNotificationObject";
NSString * const SparkNotificationUpdatedObjectKey = @"SparkNotificationUpdatedObject";

#define kSparkLibraryVersion_1_0		0x100
#define kSparkLibraryVersion_2_0		0x200

const UInt32 kSparkLibraryCurrentVersion = kSparkLibraryVersion_2_0;

@interface SparkLibrary (SparkLibraryLoader)
/* Initializer */
- (void)setInfo:(NSDictionary *)plist;

- (BOOL)loadFromWrapper:(NSFileWrapper *)wrapper error:(NSError **)error;
- (BOOL)readLibraryFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)error;
- (BOOL)importOldLibraryFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)error;

@end

@interface SparkEntryManager (SparkVersion1Library)
- (void)removeEntriesForAction:(UInt32)action;
@end

@implementation SparkLibrary

static SparkApplication *sSystem = nil;
+ (void)initialize {
  if ([SparkLibrary class] == self) {
    /* Initialize System Application */
    sSystem = [[SparkApplication alloc] initWithName:NSLocalizedStringFromTableInBundle(@"System", 
                                                                                        nil, SKCurrentBundle(), @"System Application Name")
                                                icon:[NSImage imageNamed:@"SparkSystem" inBundle:SKCurrentBundle()]];
    [sSystem setUID:kSparkApplicationSystemUID];
    
    /* Register Built-In Plugin (and make sure other plugins are loaded) */
    //[SparkActionLoader sharedLoader];
    [[SparkActionLoader sharedLoader] registerPlugInClass:[SparkBuiltInActionPlugin class]];
  }
}

+ (SparkApplication *)systemApplication {
  return sSystem;
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
  ShadowTrace();
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

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p>", [self class], self];
}

- (NSUInteger)hash {
  return sp_uuid ? CFHash(sp_uuid) : 0;
}

- (BOOL)isEqual:(id)object {
  if ([object class] != [self class])
    return NO;
  if (!sp_uuid) return ![object uuid];
  if (![object uuid]) return !sp_uuid;
  return CFEqual(sp_uuid, [object uuid]);
}

#pragma mark -
#pragma mark Objects Libraries Accessors
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

- (SparkEntryManager *)entryManager {
  return sp_relations;
}

- (SparkIconManager *)iconManager {
  return sp_icons;
}

#pragma mark -
- (CFUUIDRef)uuid {
  return sp_uuid;
}

- (NSUndoManager *)undoManager {
  return sp_undo;
}
- (void)setUndoManager:(NSUndoManager *)aManager {
  SKSetterRetain(sp_undo, aManager);
}

- (NSNotificationCenter *)notificationCenter {
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
    [NSException raise:@"InvalidFileException" format:@"You Must set a file before synchronizing"];
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
  NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithPath:[self path]];
  if (wrapper) {
    result = [self loadFromWrapper:wrapper error:error];
  } else if (error) {
    *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:fnfErr userInfo:nil];
  }

  return result;
}

- (void)unload {
  if (![self isLoaded])
    [NSException raise:NSInternalInconsistencyException format:@"<%@ %p> is not loaded.", [self class], self];
  
  SKSetFlag(sp_slFlags.loaded, NO);
  
  /* Release relation table */
  [sp_relations setLibrary:nil];
  [sp_relations release];
  sp_relations = nil;
  
  /* Release defaults libraries */
  NSUInteger idx = kSparkSetCount;
  /* WARNING: List Set keep weak ref on other sets,
    so we have to release it first */
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
- (NSFileWrapper *)fileWrapper:(NSError **)outError {
  if (outError) *outError = nil;
  
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
  
  /* SparkLists */
  file = [[self listSet] fileWrapper:outError];
  require(file != nil, bail);
  
  [file setPreferredFilename:kSparkListsFile];
  [library addFileWrapper:file];
  
  /* Library Entries */
  file = [[self entryManager] fileWrapper:outError];
  require(file != nil, bail);
  
  [file setPreferredFilename:kSparkEntriesFile];
  [library addFileWrapper:file];
  
  /* Library infos */
  NSString *uuid = sp_uuid ? (id)CFUUIDCreateString(kCFAllocatorDefault, sp_uuid) : nil;
  NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
    SKUInt(kSparkLibraryCurrentVersion), @"Version",
    uuid, @"UUID",
    nil];
  [uuid release];
  NSData *data = [NSPropertyListSerialization dataFromPropertyList:info
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
    sp_version = [[plist objectForKey:@"Version"] unsignedIntValue];
  } else {
    sp_version = kSparkLibraryCurrentVersion;
    
    if (sp_uuid) CFRelease(sp_uuid);
    sp_uuid = CFUUIDCreate(kCFAllocatorDefault);
  }
}

- (void)initReservedObjects {
  /* Init Finder Application */
  NSString *path = SKLSFindApplicationForSignature(kSparkFinderSignature);
  NSAssert(path, @"Could not locate Finder");
  if (path) {
    SparkApplication *finder = [[SparkApplication alloc] initWithPath:path];
    if (finder) {
      [finder setUID:kSparkApplicationFinderUID];
      [[self applicationSet] addObject:finder];
      [finder release];
    } else {
      ELog(@"Invalid Finder Application: %@", finder);
    }
  }
}

- (BOOL)loadFromWrapper:(NSFileWrapper *)wrapper error:(NSError **)error {
  NSParameterAssert(![self isLoaded]);
  
  BOOL result = NO;
  /* Create icon manager only for editor */
  if (SparkGetCurrentContext() == kSparkEditorContext && !sp_icons) {
    sp_icons = [[SparkIconManager alloc] initWithLibrary:self path:SparkLibraryIconFolder(self)];
  }
  
  /* Create defaults libraries */
  for (int idx = 0; idx < kSparkSetCount - 1; idx++) {
    sp_objects[idx] = [[SparkObjectSet alloc] initWithLibrary:self];
  }
  /* List Set */
  sp_objects[kSparkListSet] = [[SparkListSet alloc] initWithLibrary:self];
  
  /* Create relation table */
  sp_relations = [[SparkEntryManager alloc] initWithLibrary:self];
  
  [self initReservedObjects];
  
  if (wrapper) {
    switch (sp_version) {
      case kSparkLibraryVersion_1_0:
        result = [self importOldLibraryFromFileWrapper:wrapper error:error];
        break;
      case kSparkLibraryVersion_2_0:
        result = [self readLibraryFromFileWrapper:wrapper error:error];
        break;
    }
  } else {
    /* Load an empty/new library */
    result = YES;
  }
  
  if (result) {
    SKSetFlag(sp_slFlags.loaded, YES);
    
    SparkObject *object;
    NSMutableArray *invalids = nil;
    SparkEntryManager *manager = [self entryManager];
    
    /* Actions */
    NSEnumerator *objects = [[self actionSet] objectEnumerator];
    while (object = [objects nextObject]) {
      if (![manager containsEntryForAction:[object uid]]) {
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
    objects = [[self triggerSet] objectEnumerator];
    while (object = [objects nextObject]) {
      if (![manager containsEntryForTrigger:[object uid]]) {
        if (!invalids) invalids = [[NSMutableArray alloc] init];
        [invalids addObject:object];
      }
    }
    if (invalids) {
      [[self triggerSet] removeObjectsInArray:invalids];
      DLog(@"Remove orphans triggers: %@", invalids);
      [invalids release];
    }
  } else {
    [self unload];
  }
  
  return result;
}

- (BOOL)readLibraryFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)error {
  BOOL ok = NO;
  NSDictionary *files = [wrapper fileWrappers];
  
  SparkObjectSet *set = [self actionSet];
  ok = [set readFromFileWrapper:[files objectForKey:kSparkActionsFile] error:error];
  require(ok, bail);
  
  set = [self triggerSet];
  ok = [set readFromFileWrapper:[files objectForKey:kSparkTriggersFile] error:error];
  require(ok, bail);
  
  set = [self applicationSet];
  ok = [set readFromFileWrapper:[files objectForKey:kSparkApplicationsFile] error:error];
  require(ok, bail);

  set = [self listSet];
  ok = [set readFromFileWrapper:[files objectForKey:kSparkListsFile] error:error];
  require(ok, bail);
  
  /* Load entries */
  SparkEntryManager *manager = [self entryManager];
  ok = [manager readFromFileWrapper:[files objectForKey:kSparkEntriesFile] error:error];
  require(ok, bail);
  
  return YES;
bail:
  return NO;
}

- (BOOL)importOldLibraryFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)error {
  DLog(@"Loading Version 1.0 Library");
  /* Load HotKey items. Create trigger with internal values, and create entries with Application to Action Map */
  CFMutableSetRef actions = CFSetCreateMutable( kCFAllocatorDefault, 0, &kSKIntSetCallBacks);
  
  UInt32 finder = 0;
  NSArray *objects = nil;
  NSDictionary *plist = nil;
  NSEnumerator *enumerator = nil;
  SparkObjectSet *objectSet = nil;
  
  /* Load Applications. Ignore old '_SparkSystemApplication' items */
  objectSet = [self applicationSet];
  
  objects = [[wrapper propertyListForFilename:kSparkApplicationsFile] objectForKey:@"SparkObjects"];
  enumerator = [objects objectEnumerator];
  while (plist = [enumerator nextObject]) {
    NSString *class = [plist objectForKey:@"isa"];
    if (![class isEqualToString:@"_SparkSystemApplication"]) {
      SparkApplication *app = SKDeserializeObject(plist, nil);
      if (app && [app isKindOfClass:[SparkApplication class]]) {
        if ([app signature] == kSparkFinderSignature) {
          finder = [app uid];
          [app setUID:kSparkApplicationFinderUID];
        } else {
          [app setUID:[app uid] + kSparkLibraryReserved];
          [objectSet addObject:app];
        }
      } else {
        DLog(@"Discard invalid application: %@", app);
      }
    }
  }  
  
  objects = [[wrapper propertyListForFilename:@"SparkKeys"] objectForKey:@"SparkObjects"];
  enumerator = [objects objectEnumerator];
  objectSet = [self triggerSet];
  while (plist = [enumerator nextObject]) {
    SparkTrigger *trigger = SKDeserializeObject(plist, nil);      
    if (trigger && [trigger isKindOfClass:[SparkTrigger class]]) {
      [trigger setName:nil];
      [trigger setIcon:nil];
      [trigger setUID:[trigger uid] + kSparkLibraryReserved];
      [objectSet addObject:trigger];
      
      NSString *key;
      UInt32 status = [[plist objectForKey:@"IsActive"] unsignedIntValue];
      NSDictionary *map = [[plist objectForKey:@"ApplicationMap"] objectForKey:@"ApplicationMap"];
      NSEnumerator *entries = [map keyEnumerator];
      while (key = [entries nextObject]) {
        Boolean enabled;
        UInt32 act, trg, app;
        enabled = status ? TRUE : FALSE;
        act = [[map objectForKey:key] unsignedIntValue];
        /* If action is not 'Ignore Spark', adjust uid. */
        if (act) {
          act += kSparkLibraryReserved;
        } else {
          /* Should set status = 0 and action = action for trigger/application */
          enabled = FALSE;
          act = 0; /* Will be adjust later */
        }
        trg = [trigger uid];
        app = [key intValue];
        if (app) {
          if (finder == app)
            app = kSparkApplicationFinderUID;
          else
            app += kSparkLibraryReserved;
        }
        /* Should avoid action double usage, except for ignore action. */
        if (act || app && (act == 0 || !CFSetContainsValue(actions, (void *)act))) {
          [sp_relations addEntryWithAction:act trigger:trg application:app enabled:enabled];
          CFSetAddValue(actions, (void *)act);
        }
      }
    } else {
      DLog(@"Discard invalid trigger: %@", trigger);
    }
  }
  
  
  objects = [[wrapper propertyListForFilename:kSparkActionsFile] objectForKey:@"SparkObjects"];
  /* Load Actions. Ignore old '_SparkIgnoreAction' items */
  enumerator = [objects objectEnumerator];
  objectSet = [self actionSet];
  while (plist = [enumerator nextObject]) {
    NSString *class = [plist objectForKey:@"isa"];
    if (![class isEqualToString:@"_SparkIgnoreAction"]) {
      SparkAction *action = SKDeserializeObject(plist, nil);
      if (action && [action isKindOfClass:[SparkAction class]]) {
        [action setUID:[action uid] + kSparkLibraryReserved];
        if (CFSetContainsValue(actions, (void *)[action uid])) {
          [objectSet addObject:action];
        } else {
          DLog(@"Ignore orphan action: %@", action);
        }
      } else {
        DLog(@"Discard invalid action: %@", plist);
        UInt32 uid = [[plist objectForKey:@"UID"] unsignedIntValue];
        [sp_relations removeEntriesForAction:uid + kSparkLibraryReserved];
      }
    }
  }
  
  objects = [[wrapper propertyListForFilename:kSparkListsFile] objectForKey:@"SparkObjects"];
  /* Load Key Lists as Trigger Lists. */
  enumerator = [objects objectEnumerator];
  objectSet = [self listSet];
  while (plist = [enumerator nextObject]) {
    NSString *class = [plist objectForKey:@"isa"];
    if ([class isEqualToString:@"SparkKeyList"]) {
      SparkList *list = [[SparkList alloc] initWithName:[plist objectForKey:@"Name"]];
      [list setObjectSet:[self triggerSet]];
      
      NSNumber *uid;
      NSEnumerator *uids = [[plist objectForKey:@"ObjectList"] objectEnumerator];
      while (uid = [uids nextObject]) {
        SparkObject *object = [[self triggerSet] objectWithUID:[uid unsignedIntValue] + kSparkLibraryReserved];
        if (object) {
          [list addObject:object];
        } else {
          DLog(@"Cannot resolve list entry: %u", [uid unsignedIntValue]);
        }
      }
      [objectSet addObject:list];
      [list release];
    }
  }
  
  [sp_relations postProcess];
  
  CFRelease(actions);
  return YES;
}

@end

#pragma mark -
#pragma mark Utilities Functions
NSString *SparkLibraryFolder() {
  NSString *folder = [SKFSFindFolder(kApplicationSupportFolderType, kUserDomain) stringByAppendingPathComponent:kSparkFolderName];
  if (folder && ![[NSFileManager defaultManager] fileExistsAtPath:folder]) {
    SKFSCreateFolder((CFStringRef)folder);
  }
  return folder;
}

NSString *SparkLibraryIconFolder(SparkLibrary *library) {
  NSCParameterAssert([library uuid]);
  NSString *icons = [SparkLibraryFolder() stringByAppendingPathComponent:@"Icons"];
  CFStringRef uuidstr = CFUUIDCreateString(kCFAllocatorDefault, [library uuid]);
  if (uuidstr) {
    icons = [icons stringByAppendingPathComponent:(id)uuidstr];
    CFRelease(uuidstr);
  } else {
    [NSException raise:NSInternalInconsistencyException format:@"Error while creating string from uuid"];
  }
  return icons;
}

static
NSString *SparkLibraryPreviousLibraryPath() {
  NSString *folder = [SKFSFindFolder(kPreferencesFolderType, kUserDomain) stringByAppendingPathComponent:kSparkFolderName];
  return [folder stringByAppendingPathComponent:@"Spark3 Library.splib"];
}
static
NSString *SparkLibraryVersion1LibraryPath() {
  NSString *folder = [SKFSFindFolder(kPreferencesFolderType, kUserDomain) stringByAppendingPathComponent:kSparkFolderName];
  return [folder stringByAppendingPathComponent:@"SparkLibrary.splib"];
}

SK_INLINE 
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
      CFUUIDRef uuid = [lib uuid];
      NSString *uuidstr = (id)CFUUIDCreateString(kCFAllocatorDefault, uuid);
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
  if (!sActiveLibrary) {
    BOOL resync = NO;
    /* Get default library path */
    NSString *path = SparkDefaultLibraryPath();
    sActiveLibrary = SparkLibraryGetLibraryAtPath(path, NO);
    if (!sActiveLibrary) {
      /* First, try to find library in old location */
      NSString *old = SparkLibraryPreviousLibraryPath();
      if (![[NSFileManager defaultManager] fileExistsAtPath:old]) {
        /* Try to find an old version library */
        old = SparkLibraryVersion1LibraryPath();
        if ([[NSFileManager defaultManager] fileExistsAtPath:old]) {
          resync = YES;
          sActiveLibrary = [[SparkLibrary alloc] initWithPath:old];
        } else {
          resync = YES;
          sActiveLibrary = [[SparkLibrary alloc] init];
        }
      } else {
        /* Version 3 library exists in old location */
        if ([[NSFileManager defaultManager] movePath:old toPath:path handler:nil]) {
          sActiveLibrary = [[SparkLibrary alloc] initWithPath:path];
        } else {
          resync = YES;
          sActiveLibrary = [[SparkLibrary alloc] initWithPath:old];
        }
      }
      if (sActiveLibrary)
        SparkLibraryRegisterLibrary(sActiveLibrary);
    }
    
    /* Read library */
    if (![sActiveLibrary isLoaded] && ![sActiveLibrary load:nil]) {
      [sActiveLibrary release];
      sActiveLibrary = nil;
      [NSException raise:NSInternalInconsistencyException format:@"An error prevent default library loading"];
    } else if (resync) {
      [sActiveLibrary setPath:path];
      [sActiveLibrary synchronize];
    }
  }
  return sActiveLibrary;
}

BOOL SparkSetActiveLibrary(SparkLibrary *library) {
  if (sActiveLibrary != library) {
    SparkLibraryRegisterLibrary(library);
    [sActiveLibrary release];
    sActiveLibrary = [library retain];
  }
  return YES;
//  // Notify
//  return NO;
}

#pragma mark -
void SparkDumpTriggers(SparkLibrary *aLibrary) {
  SparkTrigger *trigger = nil;
  NSEnumerator *triggers = [[aLibrary triggerSet] objectEnumerator];
  fprintf(stderr, "Triggers: %lu\n {", [[aLibrary triggerSet] count]);
  while (trigger = [triggers nextObject]) {
    fprintf(stderr, "\t- %lu: %s\n", [trigger uid], [[trigger triggerDescription] UTF8String]);
  }
  fprintf(stderr, "}\n");
}

/*
 *  SparkLibrary.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkActionLoader.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkEntryManager.h>

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkApplication.h>
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
  kSparkListSet = 3
};

#ifdef DEBUG
#warning Using Development Spark Library
NSString * const kSparkLibraryDefaultFileName = @"Spark3 Library_Debug.splib";
#else
NSString * const kSparkLibraryDefaultFileName = @"Spark3 Library.splib";
#endif

#define kSparkLibraryVersion_1_0		0x100
#define kSparkLibraryVersion_2_0		0x200

const UInt32 kSparkLibraryCurrentVersion = kSparkLibraryVersion_2_0;

@interface SparkLibrary (SparkLibraryLoader)
- (BOOL)readLibraryFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)error;
- (BOOL)readVersion1LibraryFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)error;
@end

@interface SparkEntryManager (SparkVersion1Library)
- (BOOL)isOrphanTrigger:(UInt32)aTrigger;
- (void)removeEntriesForAction:(UInt32)action;
@end

@implementation SparkLibrary

+ (void)initialize {
  if ([SparkLibrary class] == self) {
    /* Register Built-In Plugin (and make sure other plugins are loaded) */
    [[SparkActionLoader sharedLoader] registerPlugInClass:[SparkBuiltInActionPlugin class]];
  }
}

#pragma mark -
- (id)init {
  return [self initWithPath:nil];
}

- (id)initWithPath:(NSString *)path {
  if (self = [super init]) {
    [self setPath:path];
    /* Init Library uuid */
    sp_uuid = CFUUIDCreate(kCFAllocatorDefault);
    /* Create defaults libraries */
    for (int idx = 0; idx < kSparkListSet; idx++) {
      sp_objects[idx] = [[SparkObjectSet alloc] initWithLibrary:self];
    }
    /* List Set */
    sp_objects[kSparkListSet] = [[SparkListSet alloc] initWithLibrary:self];
    
    /* Create relation table */
    sp_relations = [[SparkEntryManager alloc] initWithLibrary:self];
  }
  return self;
}

- (void)dealloc {
  [sp_file release];
  [sp_undo release];
  [sp_center release];
  for (int idx = 0; idx < 4; idx++) {
    [sp_objects[idx] release];
  }
  [sp_relations release];
  if (sp_uuid)
    CFRelease(sp_uuid);
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p>", [self class], self];
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
  if (![sp_file isEqualToString:file])
    sp_slFlags.loaded = 0;
  SKSetterCopy(sp_file, file);
}

- (BOOL)synchronize {
  if ([self path]) {
    if ([self writeToFile:[self path] atomically:YES]) {
      sp_slFlags.loaded = 1;
      return YES;
    } 
  } else {
    [NSException raise:@"InvalidFileException" format:@"You Must set a file before synchronizing"];
  }
  return NO;
}

- (BOOL)isLoaded {
  return sp_slFlags.loaded;
}

- (BOOL)readLibrary:(NSError **)error {
  BOOL result = NO;
  NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithPath:[self path]];
  if (wrapper) {
    result = [self readFromFileWrapper:wrapper error:error];
  } else if (error) {
    *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:fnfErr userInfo:nil];
  }
  SKSetFlag(sp_slFlags.loaded, result);
  return result;
}

- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)flag {
  NSParameterAssert(file != nil);
  
  NSFileWrapper* wrapper = [self fileWrapper:nil];
  if (wrapper)
    return [wrapper writeToFile:file atomically:flag updateFilenames:NO];
  return NO;  
}

- (NSFileWrapper *)fileWrapper:(NSError **)outError {
  if (outError) *outError = nil;
  
  NSFileWrapper *library = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
  
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
  
  if (outError && !*outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil];
  return nil;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError {
  NSDictionary *wrappers = [fileWrapper fileWrappers];
  NSData *data = [[wrappers objectForKey:@"Info.plist"] regularFileContents];
  require(data != nil, bail);
  
  NSDictionary *info = [NSPropertyListSerialization propertyListFromData:data 
                                                        mutabilityOption:NSPropertyListImmutable
                                                                  format:NULL
                                                        errorDescription:NULL];
  require(info != nil, bail);
  
  BOOL result = NO;
  UInt32 version = [[info objectForKey:@"Version"] unsignedIntValue];
  switch (version) {
    case kSparkLibraryVersion_1_0:
      result = [self readVersion1LibraryFromFileWrapper:fileWrapper error:outError];
      break;
    case kSparkLibraryVersion_2_0:
      result = [self readLibraryFromFileWrapper:fileWrapper error:outError];
      break;
  }
  NSString *uuid = [info objectForKey:@"UUID"];
  if (uuid) {
    CFUUIDRef uuidref = CFUUIDCreateFromString(kCFAllocatorDefault, (CFStringRef)uuid);
    if (uuidref) {
      if (sp_uuid) CFRelease(sp_uuid);
      sp_uuid = uuidref;
    }
  }
  DLog(@"Library %@ loaded", uuid);
  
  SparkApplication *finder = [[self applicationSet] objectForUID:1];
  if (!finder || [finder signature] != kSparkFinderCreatorType) {
    NSString *path = SKLSFindApplicationForSignature(kSparkFinderCreatorType);
    NSAssert(path, @"Could not locate Finder");
    if (path) {
      if (finder) {
        [finder setPath:path];
      } else if (finder = [[SparkApplication alloc] initWithPath:path]) {
        [finder setUID:1];
        [[self applicationSet] addObject:finder];
        [finder release];
      }
    }
  }
  return result;
bail:
    return NO;
}

@end

#pragma mark -
@implementation SparkLibrary (SparkLibraryLoader)

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

- (BOOL)readVersion1LibraryFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)error {
  DLog(@"Loading Version 1.0 Library");
  /* Load HotKey items. Create trigger with internal values, and create entries with Application to Action Map */
  CFMutableSetRef actions = CFSetCreateMutable( kCFAllocatorDefault, 0, &kSKIntSetCallBacks);
  CFMutableSetRef triggers = CFSetCreateMutable( kCFAllocatorDefault, 0, &kSKIntSetCallBacks);
  
  UInt32 finder = 0;
  NSArray *objects = nil;
  NSDictionary *plist = nil;
  NSEnumerator *enumerator = nil;
  SparkObjectSet *library = nil;
  
  /* Load Applications. Ignore old '_SparkSystemApplication' items */
  library = [self applicationSet];
  
  objects = [[wrapper propertyListForFilename:kSparkApplicationsFile] objectForKey:@"SparkObjects"];
  enumerator = [objects objectEnumerator];
  while (plist = [enumerator nextObject]) {
    NSString *class = [plist objectForKey:@"isa"];
    if (![class isEqualToString:@"_SparkSystemApplication"]) {
      SparkApplication *app = SKDeserializeObject(plist, nil);
      if (app && [app isKindOfClass:[SparkApplication class]]) {
        if ([app signature] == kSparkFinderCreatorType) {
          finder = [app uid];
          [app setUID:1];
        } else {
          [app setUID:[app uid] + kSparkLibraryReserved];
        }
        [library addObject:app];
      } else {
        DLog(@"Discard invalid application: %@", app);
      }
    }
  }  
  
  objects = [[wrapper propertyListForFilename:@"SparkKeys"] objectForKey:@"SparkObjects"];
  enumerator = [objects objectEnumerator];
  library = [self triggerSet];
  while (plist = [enumerator nextObject]) {
    SparkTrigger *trigger = SKDeserializeObject(plist, nil);      
    if (trigger && [trigger isKindOfClass:[SparkTrigger class]]) {
      [trigger setName:nil];
      [trigger setIcon:nil];
      [trigger setUID:[trigger uid] + kSparkLibraryReserved];
      [library addObject:trigger];
      
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
            app = 1;
          else
            app += kSparkLibraryReserved;
        }
        /* Should avoid action double usage, except for ignore action. */
        if (act || app && (act == 0 || !CFSetContainsValue(actions, (void *)act))) {
          [sp_relations addEntryWithAction:act trigger:trg application:app enabled:enabled];
          CFSetAddValue(actions, (void *)act);
          CFSetAddValue(triggers, (void *)trg);
        }
      }
    } else {
      DLog(@"Discard invalid trigger: %@", trigger);
    }
  }
  
  
  objects = [[wrapper propertyListForFilename:kSparkActionsFile] objectForKey:@"SparkObjects"];
  /* Load Actions. Ignore old '_SparkIgnoreAction' items */
  enumerator = [objects objectEnumerator];
  library = [self actionSet];
  while (plist = [enumerator nextObject]) {
    NSString *class = [plist objectForKey:@"isa"];
    if (![class isEqualToString:@"_SparkIgnoreAction"]) {
      SparkAction *action = SKDeserializeObject(plist, nil);
      if (action && [action isKindOfClass:[SparkAction class]]) {
        [action setUID:[action uid] + kSparkLibraryReserved];
        if (CFSetContainsValue(actions, (void *)[action uid])) {
          [library addObject:action];
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
  library = [self listSet];
  while (plist = [enumerator nextObject]) {
    NSString *class = [plist objectForKey:@"isa"];
    if ([class isEqualToString:@"SparkKeyList"]) {
      SparkList *list = [[SparkList alloc] initWithName:[plist objectForKey:@"Name"]];
      [list setObjectSet:[self triggerSet]];
      
      NSNumber *uid;
      NSEnumerator *uids = [[plist objectForKey:@"ObjectList"] objectEnumerator];
      while (uid = [uids nextObject]) {
        SparkObject *object = [[self triggerSet] objectForUID:[uid unsignedIntValue] + kSparkLibraryReserved];
        if (object) {
          [list addObject:object];
        } else {
          DLog(@"Cannot resolve list entry: %u", [uid unsignedIntValue]);
        }
      }
      [library addObject:list];
      [list release];
    }
  }
  
  {
    /* Cleanup */
    SparkTrigger *trigger = nil;
    NSMutableArray *tmp = [[NSMutableArray alloc] init];
    enumerator = [[self triggerSet] objectEnumerator];
    while (trigger = [enumerator nextObject]) {
      if (!CFSetContainsValue(triggers, (void *)[trigger uid])) {
        [tmp addObject:trigger];
      }
    }
    if ([tmp count]) {
      DLog(@"Remove invalid triggers: %@", tmp);
      [[self triggerSet] removeObjectsInArray:tmp];
    }
    [tmp release];
  }
  
  [sp_relations postProcess];
  
  CFRelease(triggers);
  CFRelease(actions);
  return YES;
}

@end

#pragma mark -
#pragma mark Utilities Functions
NSString *SparkLibraryDefaultFolder() {
  NSString *folder = [SKFSFindFolder(kPreferencesFolderType, kUserDomain) stringByAppendingPathComponent:kSparkFolderName];
  if (folder && ![[NSFileManager defaultManager] fileExistsAtPath:folder]) {
    [[NSFileManager defaultManager] createDirectoryAtPath:folder attributes:nil];
  }
  return folder;
}

SK_INLINE 
NSString *SparkDefaultLibraryPath(void) {
  return [SparkLibraryDefaultFolder() stringByAppendingPathComponent:kSparkLibraryDefaultFileName];
}

SparkLibrary *SparkActiveLibrary() {
  static SparkLibrary *active = nil;
  if (!active) {
    /* Get default library path */
    NSString *path = SparkDefaultLibraryPath();
    /* Create library */
    active = [[SparkLibrary alloc] initWithPath:path];
    /* If library does not exist, check for previous version library */
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
      NSString *old = [SparkLibraryDefaultFolder() stringByAppendingPathComponent:@"SparkLibrary.splib"];
      /* If old library exists, load it, and resave it into new format */
      if ([[NSFileManager defaultManager] fileExistsAtPath:old]) {
        [active setPath:old];
        [active readLibrary:nil];
        [active setPath:path];
      }
      [active synchronize];
    } else if (![active readLibrary:nil]) {
      [NSException raise:NSInternalInconsistencyException format:@"An error prevent default library loading"];
    }
  }
  return active;
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

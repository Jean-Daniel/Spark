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
- (void)postProcess;
- (BOOL)isOrphanTrigger:(UInt32)aTrigger;
- (void)removeEntriesForAction:(UInt32)action;
@end

@implementation SparkLibrary

+ (void)initialize {
  // Make sure plugin are loaded
  if ([SparkLibrary class] == self) {
    [SparkActionLoader sharedLoader];
  }
}

+ (SparkLibrary *)sharedLibrary {
  static SparkLibrary *shared = nil;
  if (!shared) {
    shared = [[self alloc] initWithPath:SparkSharedLibraryPath()];
  }
  return shared;
}

#pragma mark -
- (id)init {
  return [self initWithPath:nil];
}

- (id)initWithPath:(NSString *)path {
  if (self = [super init]) {
    [self setPath:path];
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
  for (int idx = 0; idx < 4; idx++) {
    [sp_objects[idx] release];
  }
  [sp_relations release];
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
#pragma mark FileSystem Methods
- (NSString *)path {
  return sp_file;
}

- (void)setPath:(NSString *)file {
  SKSetterCopy(sp_file, file);
}

- (BOOL)synchronize {
  if ([self path]) {
    return [self writeToFile:[self path] atomically:YES];
  } else {
    [NSException raise:@"InvalidFileException" format:@"You Must set a file before synchronizing"];
    return NO;
  }
}

- (BOOL)readLibrary:(NSError **)error {
  BOOL result = NO;
  NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithPath:[self path]];
  if (wrapper) {
    result = [self readFromFileWrapper:wrapper error:error];
  } else if (error) {
    *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:fnfErr userInfo:nil];
  }
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
  
  NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
    SKUInt(kSparkLibraryCurrentVersion), @"Version",
    nil];
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
  SparkApplication *finder = [[self applicationSet] objectForUID:1];
  if (!finder) {
    NSString *path = SKFindApplicationForSignature('MACS');
    NSAssert(path, @"Could not locate Finder");
    if (path && (finder = [[SparkApplication alloc] initWithPath:path])) {
      [finder setUID:1];
      [[self applicationSet] addObject:finder];
      [finder release];
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
  DLog(@"Loading Library !");
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
        if ([app signature] == 'MACS') {
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
        SparkLibraryEntry entry;
        entry.status = status;
        entry.action = [[map objectForKey:key] unsignedIntValue];
        /* If action is not 'Ignore Spark', adjust uid. */
        if (entry.action) {
          entry.action += kSparkLibraryReserved;
        } else {
          /* Should set status = 0 and action = action for trigger/application */
          entry.status = 0;
          entry.action = 0; /* Will be adjust later */
        }
        entry.trigger = [trigger uid];
        entry.application = [key intValue];
        if (entry.application) {
          if (finder == entry.application)
            entry.application = 1;
          else
            entry.application += kSparkLibraryReserved;
        }
        /* Should avoid action double usage, except for ignore action. */
        if (entry.action || entry.application && (entry.action == 0 || !CFSetContainsValue(actions, (void *)entry.action))) {
          [sp_relations addLibraryEntry:&entry];
          CFSetAddValue(actions, (void *)entry.action);
          CFSetAddValue(triggers, (void *)entry.trigger);
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
NSString *SparkLibraryFolder() {
  NSString *folder = [SKFSFindFolder(kPreferencesFolderType, kUserDomain) stringByAppendingPathComponent:kSparkFolderName];
  if (folder && ![[NSFileManager defaultManager] fileExistsAtPath:folder]) {
    [[NSFileManager defaultManager] createDirectoryAtPath:folder attributes:nil];
  }
  return folder;
}

SparkLibrary *SparkSharedLibrary() {
  return [SparkLibrary sharedLibrary];
}

SparkEntryManager *SparkSharedManager() {
  return [[SparkLibrary sharedLibrary] entryManager];
}

SparkObjectSet *SparkSharedListSet() {
  return [[SparkLibrary sharedLibrary] listSet];
}

SparkObjectSet *SparkSharedActionSet() {
  return [[SparkLibrary sharedLibrary] actionSet];
}

SparkObjectSet *SparkSharedTriggerSet() {
  return [[SparkLibrary sharedLibrary] triggerSet];
}

SparkObjectSet *SparkSharedApplicationSet() {
  return [[SparkLibrary sharedLibrary] applicationSet];
}


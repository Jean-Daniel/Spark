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
#import <SparkKit/SparkObject.h>
#import <SparkKit/SparkObjectsLibrary.h>

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkApplication.h>

#import <ShadowKit/SKCFContext.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKSerialization.h>

NSString * const kSparkLibraryFileExtension = @"splib";

NSPropertyListFormat SparkLibraryFileFormat = NSPropertyListBinaryFormat_v1_0;

static NSString * const kSparkActionsFile = @"SparkActions";
static NSString * const kSparkEntriesFile = @"SparkEntries";
static NSString * const kSparkTriggersFile = @"SparkTriggers";
static NSString * const kSparkApplicationsFile = @"SparkApplications";

static NSString * const kSparkActionLibrary = @"SparkActionLibrary";
static NSString * const kSparkTriggerLibrary = @"SparkTriggerLibrary";
static NSString * const kSparkApplicationLibrary = @"SparkApplicationLibrary";

#ifdef DEBUG
#warning Using Development Spark Library
NSString * const kSparkLibraryDefaultFileName = @"SparkLibrary v3_Debug.splib";
#else
NSString * const kSparkLibraryDefaultFileName = @"SparkLibrary v3.splib";
#endif

typedef struct {
  OSType magic;
  UInt32 version;
  /* Version 0 header */
  UInt32 count;
  SparkEntry entries[0];
} SparkEntryHeader;

#define SPARK_MAGIC		'SpEn'
#define SPARK_CIGAM		'nEpS'

#define kSparkLibraryVersion_1_0		0x100
#define kSparkLibraryVersion_2_0		0x200

const UInt32 kSparkLibraryCurrentVersion = kSparkLibraryVersion_2_0;

@interface SparkLibrary (SparkLibraryLoader)
- (BOOL)readLibraryFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)error;
- (BOOL)readVersion1LibraryFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)error;
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
    /* Create defaults libraries */
    sp_libraries = [[NSMutableDictionary alloc] init];
    [sp_libraries setObject:[SparkObjectsLibrary objectsLibraryWithLibrary:self]
                     forKey:kSparkActionLibrary];
    [sp_libraries setObject:[SparkObjectsLibrary objectsLibraryWithLibrary:self]
                     forKey:kSparkTriggerLibrary];
    [sp_libraries setObject:[SparkObjectsLibrary objectsLibraryWithLibrary:self] 
                     forKey:kSparkApplicationLibrary];
    
    /* Create relation table */
    sp_relations = SKCArrayCreate(sizeof(SparkEntry), 0);
    [self setPath:path];
  }
  return self;
}

- (void)dealloc {
  [sp_file release];
  [sp_libraries release];
  if (sp_relations) SKCArrayDeallocate(sp_relations);
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> %@", [self class], self, sp_libraries];
}

#pragma mark -
#pragma mark Objects Libraries Accessors
- (id)libraryForKey:(NSString *)aKey {
  NSAssert1([sp_libraries objectForKey:aKey] != nil, @"Library for key: %@ doesn't exist", aKey);
  return [sp_libraries objectForKey:aKey];
}

- (SparkObjectsLibrary *)actionLibrary {
  return [self libraryForKey:kSparkActionLibrary];
}

- (SparkObjectsLibrary *)triggerLibrary {
  return [self libraryForKey:kSparkTriggerLibrary];
}

- (SparkObjectsLibrary *)applicationLibrary {
  return [self libraryForKey:kSparkApplicationLibrary];
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

- (NSData *)sp_saveEntries {
  UInt32 count = SKCArrayCount(sp_relations);
  UInt32 size = count * sizeof(SparkEntry) + sizeof(SparkEntryHeader);
  NSMutableData *data = [[NSMutableData alloc] initWithCapacity:size];
  /* Write header */
  [data setLength:sizeof(SparkEntryHeader)];
  SparkEntryHeader *header = [data mutableBytes];
  header->magic = SPARK_MAGIC;
  header->version = 0;
  header->count = count;
  /* Write contents */
  [data appendBytes:SKCArrayGetInternalArray(sp_relations) length:count * sizeof(SparkEntry)];
  return [data autorelease];
}

- (NSFileWrapper *)fileWrapper:(NSError **)outError {
  if (outError) *outError = nil;
  
  NSFileWrapper *library = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
  
  NSFileWrapper *file;
  /* SparkActions */
  file = [[self actionLibrary] fileWrapper:outError];
  require(file != nil, bail);
  
  [file setPreferredFilename:kSparkActionsFile];
  [library addFileWrapper:file];
  
  /* SparkHotKeys */
  file = [[self triggerLibrary] fileWrapper:outError];
  require(file != nil, bail);
  
  [file setPreferredFilename:kSparkTriggersFile];
  [library addFileWrapper:file];
  
  /* SparkApplications */
  file = [[self applicationLibrary] fileWrapper:outError];
  require(file != nil, bail);
  
  [file setPreferredFilename:kSparkApplicationsFile];
  [library addFileWrapper:file];
  
  /* Library Entries */
  [library addRegularFileWithContents:[self sp_saveEntries] preferredFilename:kSparkEntriesFile];
  
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
  SparkApplication *finder = [[self applicationLibrary] objectForUID:1];
  if (!finder) {
//    NString *path = SKLS
//    finder = [SparkApplication appli
  }
  return result;
bail:
    return NO;
}

#pragma mark -
#pragma mark Library Queries
- (NSDictionary *)triggersForApplication:(UInt32)application {
  UInt32 count = SKCArrayCount(sp_relations);
  SparkObjectsLibrary *actions = [self actionLibrary];
  SparkObjectsLibrary *triggers = [self triggerLibrary];
  SparkEntry *entry = SKCArrayGetInternalArray(sp_relations);
  
  CFMutableDictionaryRef result = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, 
                                                            &kSKNSObjectDictionaryKeyCallBacks, 
                                                            &kSKNSObjectDictionaryValueCallBacks);
  while (count-- > 0) {
    if (application == entry->application) {
      SparkAction *action = [actions objectForUID:entry->action];
      SparkTrigger *trigger = [triggers objectForUID:entry->trigger];
      if (action && trigger) {
        // Add entry
        CFDictionarySetValue(result, trigger, action);
      }
    }
    entry++;
  }
  return [(id)result autorelease];
}

@end

#pragma mark -
@implementation SparkLibrary (SparkLibraryLoader)
#define SparkReadField(field)	({swap ? OSSwapInt32(field) : field; })
- (BOOL)readEntries:(NSData *)data {
  BOOL swap = NO;
  const SparkEntryHeader *header = NULL;
  
  const void *bytes = [data bytes];
  header = bytes;
  switch (header->magic) {
    case SPARK_CIGAM:
      swap = YES;
      // fall 
    case SPARK_MAGIC:
      break;
    default:
      // Invalid header
      return NO;
  }
  
  // No need to check version
  
  const SparkEntry *entries = NULL;
  UInt32 count = SparkReadField(header->count);
  
  if ([data length] < count * sizeof(SparkEntry) + sizeof(SparkEntryHeader)) {
    DLog(@"Unexpected end of file");
    return NO;
  }
  
  /* Adjust array size to avoid resizing */
  SKCArraySetCapacity(sp_relations, count);
  
  entries = header->entries;
  while (count-- > 0) {
    SparkEntry entry;
    entry.action = SparkReadField(entries->action);
    entry.trigger = SparkReadField(entries->trigger);
    entry.application = SparkReadField(entries->application);
    SKCArrayAppendItem(sp_relations, &entry);
    entries++;
  }
  
  return YES;
}

- (BOOL)readLibraryFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)error {
  DLog(@"Loading Library!");
  BOOL ok = NO;
  NSDictionary *files = [wrapper fileWrappers];
  
  SparkObjectsLibrary *library = [self actionLibrary];
  ok = [library readFromFileWrapper:[files objectForKey:kSparkActionsFile] error:error];
  require(ok, bail);
  
  library = [self triggerLibrary];
  ok = [library readFromFileWrapper:[files objectForKey:kSparkTriggersFile] error:error];
  require(ok, bail);
  
  library = [self applicationLibrary];
  ok = [library readFromFileWrapper:[files objectForKey:kSparkApplicationsFile] error:error];
  require(ok, bail);

  /* Load entries */
  NSData *data = [[files objectForKey:kSparkEntriesFile] regularFileContents];
  require(data && [self readEntries:data], bail);
  
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
  SparkObjectsLibrary *library = nil;
  
  /* Load Applications. Ignore old '_SparkSystemApplication' items */
  library = [self applicationLibrary];
  
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
  library = [self triggerLibrary];
  while (plist = [enumerator nextObject]) {
    SparkTrigger *trigger = SKDeserializeObject(plist, nil);      
    if (trigger && [trigger isKindOfClass:[SparkTrigger class]]) {
      [trigger setEnabled:[[plist objectForKey:@"IsActive"] boolValue]];
      [trigger setName:nil];
      [trigger setIcon:nil];
      [trigger setUID:[trigger uid] + kSparkLibraryReserved];
      [library addObject:trigger];
      
      NSString *key;
      NSDictionary *map = [[plist objectForKey:@"ApplicationMap"] objectForKey:@"ApplicationMap"];
      NSEnumerator *entries = [map keyEnumerator];
      while (key = [entries nextObject]) {
        SparkEntry entry;
        entry.action = [[map objectForKey:key] unsignedIntValue];
        if (entry.action) entry.action += kSparkLibraryReserved;
        entry.trigger = [trigger uid];
        entry.application = [key intValue];
        if (entry.application) {
          if (finder == entry.application)
            entry.application = 1;
          else
            entry.application += kSparkLibraryReserved;
        }
        if (entry.action || entry.application) {
          SKCArrayAppendItem(sp_relations, &entry);
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
  library = [self actionLibrary];
  while (plist = [enumerator nextObject]) {
    NSString *class = [plist objectForKey:@"isa"];
    if (![class isEqualToString:@"_SparkIgnoreAction"]) {
      SparkAction *action = SKDeserializeObject(plist, nil);
      if (action && [action isKindOfClass:[SparkAction class]]) {
        [action setUID:[action uid] + kSparkLibraryReserved];
        if (CFSetContainsValue(actions, (void *)[action uid])) {
          [library addObject:action];
        } else {
          DLog(@"Ignore orphan item: %@", action);
        }
      } else {
        DLog(@"Discard invalid action: %@", action);
      }
    }
  }
  
  {
    /* Cleanup */
    SparkTrigger *trigger = nil;
    NSMutableArray *tmp = [[NSMutableArray alloc] init];
    enumerator = [[self triggerLibrary] objectEnumerator];
    while (trigger = [enumerator nextObject]) {
      if (!CFSetContainsValue(triggers, (void *)[trigger uid])) {
        [tmp addObject:trigger];
      }
    }
    if ([tmp count]) {
      DLog(@"Remove invalid triggers: %@", tmp);
      [[self triggerLibrary] removeObjectsInArray:tmp];
    }
    [tmp release];
  }
  
  CFRelease(triggers);
  CFRelease(actions);
  return YES;
}

@end

#pragma mark -
#pragma mark Utilities Functions
NSString *SparkLibraryFolder() {
  NSString *folder = [SKFindFolder(kPreferencesFolderType, kUserDomain) stringByAppendingPathComponent:kSparkFolderName];
  if (folder && ![[NSFileManager defaultManager] fileExistsAtPath:folder]) {
    [[NSFileManager defaultManager] createDirectoryAtPath:folder attributes:nil];
  }
  return folder;
}

SparkLibrary *SparkSharedLibrary() {
  return [SparkLibrary sharedLibrary];
}

SparkObjectsLibrary *SparkSharedActionLibrary() {
  return [[SparkLibrary sharedLibrary] actionLibrary];
}

SparkObjectsLibrary *SparkSharedTriggerLibrary() {
  return [[SparkLibrary sharedLibrary] triggerLibrary];
}

SparkObjectsLibrary *SparkSharedApplicationLibrary() {
  return [[SparkLibrary sharedLibrary] applicationLibrary];
}


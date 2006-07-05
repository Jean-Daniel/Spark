//
//  SparkLibrary.m
//  SparkKit
//
//  Created by Grayfox on 18/11/2004.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkLibraryObject.h>

#import <ShadowKit/SKFSFunctions.h>

NSString * const kSparkLibraryFileExtension = @"splib";

NSPropertyListFormat SparkLibraryFileFormat = NSPropertyListBinaryFormat_v1_0;

//static NSString * const kSparkKeyFile = @"SparkKeys";
//static NSString * const kSparkListFile = @"SparkLists";
//
//static NSString * const kSparkKeyLibrary = @"SparkKeyLibrary";
//static NSString * const kSparkListLibrary = @"SparkListLibrary";

static NSString * const kSparkActionFile = @"SparkActions";
static NSString * const kSparkTriggerFile = @"SparkTriggers";
static NSString * const kSparkApplicationFile = @"SparkApplications";

static NSString * const kSparkActionLibrary = @"SparkActionLibrary";
static NSString * const kSparkTriggerLibrary = @"SparkTriggerLibrary";
static NSString * const kSparkApplicationLibrary = @"SparkApplicationLibrary";

#ifdef DEBUG
#warning Using Development Spark Library
NSString * const kSparkLibraryDefaultFileName = @"SparkLibrary_Debug.splib";
#else
NSString * const kSparkLibraryDefaultFileName = @"SparkLibrary.splib";
#endif

SK_INLINE 
NSString *SparkDefaultLibraryPath() {
  return [SparkLibraryFolder() stringByAppendingPathComponent:kSparkLibraryDefaultFileName];
}

#define kSparkLibraryVersion_1_0		0x100
#define kSparkLibraryVersion_2_0		0x200

const UInt32 kSparkLibraryCurrentVersion = kSparkLibraryVersion_2_0;

@implementation SparkLibrary

+ (SparkLibrary *)sharedLibrary {
  static id shared = nil;
  if (!shared) {
    shared = [[self alloc] initWithPath:SparkDefaultLibraryPath()];
  }
  return shared;
}

#pragma mark -
- (id)init {
  return [self initWithPath:nil];
}

- (id)initWithPath:(NSString *)path {
  if (self = [super init]) {
    sp_libraries = [[NSMutableDictionary alloc] init];
    [self setPath:path];
//    if (![self load]) {
//      [self release];
//      self = nil;
//    }
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
#pragma mark Loading Methods
//- (BOOL)_load {
//  [_libraries setObject:[SparkActionLibrary objectsLibraryWithLibrary:self] forKey:kSparkActionLibrary];
//  [_libraries setObject:[SparkApplicationLibrary objectsLibraryWithLibrary:self] forKey:kSparkApplicationLibrary];
//  [_libraries setObject:[SparkKeyLibrary objectsLibraryWithLibrary:self] forKey:kSparkKeyLibrary];
//  [_libraries setObject:[SparkListLibrary objectsLibraryWithLibrary:self] forKey:kSparkListLibrary];
//  return YES;
//}

/* Load old library file format */
//- (BOOL)_loadFolder:(NSString *)folder {
//  [_libraries setObject:[SparkActionLibrary objectsLibraryWithLibrary:self] forKey:kSparkActionLibrary];
//  [_libraries setObject:[SparkApplicationLibrary objectsLibraryWithLibrary:self] forKey:kSparkApplicationLibrary];
//  
//  BOOL loaded = YES;
//  id library = [SparkKeyLibrary objectsLibraryWithLibrary:self];
//  loaded &= [library loadData:[NSData dataWithContentsOfFile:[folder stringByAppendingPathComponent:@"Keys.plist"]]];
//  [_libraries setObject:library forKey:kSparkKeyLibrary];
//  
//  library = [SparkListLibrary objectsLibraryWithLibrary:self];
//  loaded &= [library loadData:[NSData dataWithContentsOfFile:[folder stringByAppendingPathComponent:@"Lists.plist"]]];    
//  [_libraries setObject:library forKey:kSparkListLibrary];
//  if (loaded) { /* If loading successfull */
//    [self setFile:[folder stringByAppendingPathComponent:kSparkLibraryDefaultFileName]];
//    id manager = [NSFileManager defaultManager];
//    if ([self synchronize]) { /* If synchronized, remove old files. */
//      [manager removeFileAtPath:[folder stringByAppendingPathComponent:@"Keys.plist"] handler:nil];
//      [manager removeFileAtPath:[folder stringByAppendingPathComponent:@"Lists.plist"] handler:nil];
//    }
//  }
//  return loaded;
//}
//
//- (BOOL)_loadFileWrapper:(NSFileWrapper *)aWrapper {
//  /* Always load actions first */
//  BOOL loaded = YES;
//  @try {
//    id files = [aWrapper fileWrappers];
//    id library = [SparkActionLibrary objectsLibraryWithLibrary:self];
//    loaded &= [library loadData:[[files objectForKey:kSparkActionFile] regularFileContents]];    
//    if (loaded) {
//      [_libraries setObject:library forKey:kSparkActionLibrary];
//      library = [SparkApplicationLibrary objectsLibraryWithLibrary:self];
//      loaded &= [library loadData:[[files objectForKey:kSparkApplicationFile] regularFileContents]];    
//    }
//    if (loaded) {
//      [_libraries setObject:library forKey:kSparkApplicationLibrary];
//      library = [SparkKeyLibrary objectsLibraryWithLibrary:self];
//      loaded &= [library loadData:[[files objectForKey:kSparkKeyFile] regularFileContents]];    
//    }
//    if (loaded) {
//      [_libraries setObject:library forKey:kSparkKeyLibrary];
//      library = [SparkListLibrary objectsLibraryWithLibrary:self];
//      loaded &= [library loadData:[[files objectForKey:kSparkListFile] regularFileContents]];
//    }
//    if (loaded) {
//      [_libraries setObject:library forKey:kSparkListLibrary];
//    }
//  } 
//  @catch (id exception) {
//    SKLogException(exception);
//    loaded = NO;
//  }
//  return loaded;
//}
//
//- (BOOL)load {
//  id path = [self file];
//  if (!path) {
//    DLog(@"WARNING: No path defined. Creating empty Library!");
//    return [self _load];
//  }
//  
//  if ([[path pathExtension] isEqualToString:kSparkLibraryFileExtension]) {
//    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
//      DLog(@"Load Wrapper Library");
//      id wrapper = [[NSFileWrapper alloc] initWithPath:path];
//      if (wrapper) {
//        return [self _loadFileWrapper:[wrapper autorelease]];
//      } else {
//        DLog(@"ERROR: Invalid wrapper");
//        return NO;
//      }
//    } else {
//      DLog(@"WARNING: Library file %@ doesn't exist. Creating empty Library", path);
//      return [self _load];
//    }
//  } else {
//    BOOL isDir;
//    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir &&
//        [[[NSFileManager defaultManager] directoryContentsAtPath:path] containsObject:@"Keys.plist"]) {
//      DLog(@"Convert old Library");
//      return [self _loadFolder:path];
//    } else {
//      DLog(@"ERROR: %@ isn't a Library file or folder", path);
//      return NO;
//    }
//  }
//}
//
//- (BOOL)reload {
//  [_libraries removeAllObjects];
//  return [self load];
//}

#pragma mark -
#pragma mark Imports
- (void)importsObjects:(NSArray *)objects inLibrary:(SparkObjectsLibrary *)aLibrary {
  id item;
  id items = [objects objectEnumerator];
  while (item = [items nextObject]) {
    if ([item uid] != 0) {
      [item setUID:0];
      [aLibrary addObject:item];
    }
  }
}

//- (void)importsObjects:(NSArray *)objects
//           fromLibrary:(SparkLibrary *)oldLib
//      toObjectsLibrary:(SparkObjectsLibrary *)newLib
//     updateUidSelector:(SEL)aSel {
//  
//  if ([objects count]) {
//    if (oldLib == self) return;
//    
//    id keys = [[oldLib keyLibrary] objects];
//    
//    /* Init Array With two object to use replaceObjectAtIndex: */
//    NSMutableArray *uids = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], nil];
//    id items = [objects objectEnumerator];
//    id item;
//    while (item = [items nextObject]) {
//      if ([[item uid] unsignedIntValue]) { /* Check if it isn't a System Object */
//        [uids replaceObjectAtIndex:0 withObject:[item uid]]; /* Save old UID */
//        [item setUid:nil]; /* Reset Object UID */
//        [newLib addObject:item]; /* Import Object => Sets a new UID */
//        [uids replaceObjectAtIndex:1 withObject:[item uid]]; /* Save new UID */
//        [keys makeObjectsPerformSelector:aSel withObject:uids]; /* Update old Library Keys */
//      }
//    }
//    [uids release];
//  }  
//}

//- (void)importsLists:(SparkListLibrary *)library {
//  SparkListLibrary *lib = [self listLibrary];
//  id apps = [library listsWithContentType:[SparkApplication class]];
//  id lists = [NSMutableArray arrayWithArray:[library objects]];
//  if ([apps count]) {
//    [lists removeObjectsInArray:apps];
//  }
//  [self importsObjects:lists inLibrary:lib];
//  [self importsObjects:apps fromLibrary:[library library] toObjectsLibrary:lib updateUidSelector:@selector(updateListUid:)];
//}

//- (void)importsApplications:(SparkApplicationLibrary *)library {
//  id lib  = [self applicationLibrary];
//  id applications = [[NSMutableArray alloc] initWithArray:[library objects]]; /* Copy Old library contents */
//  id keys = [[[library library] keyLibrary] objects];
//  id items = [library objectEnumerator];
//  id item;
//  while (item = [items nextObject]) { /* Enumerate Old Library */
//    id app = [lib applicationWithIdentifier:[item identifier]];
//    if (nil != app) { /* If app already in new Library... */
//      NSNumber *old = [[item uid] retain];
//      NSNumber *new = [app uid];
//      [applications removeObjectIdenticalTo:item]; /* ...don't have to import it */
//      /* Send notification to Old Library lists (and other listener) to make them refere the New Library object */
//      /* If we didn't do this, they will continue to refere unimported applications */
//      [[NSNotificationCenter defaultCenter] postNotificationName:kSparkLibraryDidUpdateApplicationNotification
//                                                          object:[library library]
//                                                        userInfo:[NSDictionary dictionaryWithObject:app
//                                                                                             forKey:kSparkNotificationObject]];
//      if (![old isEqualToNumber:new]) { /* If uid in new base ≠ uid in old base */
//        id tmp = [library objectWithId:new];
//        if (tmp) { /* Make sure than the new UID is unused */
//          [tmp setUid:SKUInt([library nextUid])]; /* If another App already use it => sets a new UID */
//          [keys makeObjectsPerformSelector:@selector(updateApplicationUid:) withObject:[NSArray arrayWithObjects:new, [tmp uid], nil]];
//        }
//  		[item setUid:new]; /* Synchronize UID in old base with UID in new base */
//  		[keys makeObjectsPerformSelector:@selector(updateApplicationUid:) withObject:[NSArray arrayWithObjects:old, new, nil]];
//      }
//      [old release];
//    }
//  }
//  /* Imports only applications that aren't in new base */
//  [self importsObjects:applications fromLibrary:[library library] toObjectsLibrary:lib updateUidSelector:@selector(updateApplicationUid:)]; 
//}

//- (void)importsActions:(SparkActionLibrary *)library {
//  [self importsObjects:[library objects] fromLibrary:[library library] toObjectsLibrary:[self actionLibrary] updateUidSelector:@selector(updateActionUid:)];   
//}
//- (void)importsHotKeys:(SparkKeyLibrary *)library {
//  [self importsObjects:[library objects] inLibrary:[self keyLibrary]]; 
//}

//- (void)importsObjectsFromLibrary:(SparkLibrary *)aLibrary {
//  if (self != aLibrary) {
//    [self importsApplications:[aLibrary applicationLibrary]];
//    [self importsActions:[aLibrary actionLibrary]];
//    [self importsLists:[aLibrary listLibrary]];
//    [self importsHotKeys:[aLibrary keyLibrary]];
//    [aLibrary->_libraries removeAllObjects];
//  }
//}

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

- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)flag {
  NSParameterAssert(file != nil);
  
  NSFileWrapper* wrapper = [self fileWrapper:nil];
  if (wrapper)
    return [wrapper writeToFile:file atomically:flag updateFilenames:NO];
  return NO;  
}

- (NSFileWrapper *)fileWrapper:(NSError **)outError {
  NSFileWrapper *library = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
  
  NSFileWrapper *file;
  /* SparkActions */
  file = [[self actionLibrary] fileWrapper];
  require(file != nil, bail);
  
  [file setPreferredFilename:kSparkActionFile];
  [library addFileWrapper:file];
  
  /* SparkHotKeys */
  file = [[self triggerLibrary] fileWrapper];
  require(file != nil, bail);
  
  [file setPreferredFilename:kSparkTriggerFile];
  [library addFileWrapper:file];
  
  /* SparkApplications */
  file = [[self applicationLibrary] fileWrapper];
  require(file != nil, bail);
  
  [file setPreferredFilename:kSparkApplicationLibrary];
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
  
  if (outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil];
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
  UInt32 version = [[info objectForKey:@"Version"] unsignedIntValue];
  switch (version) {
    case kSparkLibraryVersion_1_0:
      DLog(@"Loading Version 1.0 Library");
      break;
    case kSparkLibraryVersion_2_0:
      DLog(@"Loading Version 2.0 Library");
      break;
  }
bail:
    return NO;
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


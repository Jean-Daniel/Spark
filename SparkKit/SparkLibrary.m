//
//  SparkLibrary.m
//  SparkKit
//
//  Created by Grayfox on 18/11/2004.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "SparkLibrary.h"

#import "ShadowMacros.h"
#import "SKFunctions.h"

#import "SparkConstantes.h"
#import "SparkObjectsLibrary.h"

#import "SparkKeyLibrary.h"
#import "SparkListLibrary.h"
#import "SparkActionLibrary.h"
#import "SparkApplicationLibrary.h"

NSString * const kSparkLibraryFileExtension = @"splib";
NSPropertyListFormat SparkLibraryFileFormat = NSPropertyListBinaryFormat_v1_0;

static NSString * const kSparkKeyFile = @"SparkKeys";
static NSString * const kSparkListFile = @"SparkLists";
static NSString * const kSparkActionFile = @"SparkActions";
static NSString * const kSparkApplicationFile = @"SparkApplications";

static NSString * const kSparkKeyLibrary = @"SparkKeyLibrary";
static NSString * const kSparkListLibrary = @"SparkListLibrary";
static NSString * const kSparkActionLibrary = @"SparkActionLibrary";
static NSString * const kSparkApplicationLibrary = @"SparkApplicationLibrary";

#ifdef DEBUG
#warning Using Development Spark Library
NSString * const kSparkLibraryDefaultFileName = @"SparkLibrary_Debug.splib";
#else
NSString * const kSparkLibraryDefaultFileName = @"SparkLibrary.splib";
#endif

static NSString *SparkDefaultLibraryPath();

#define kSparkLibraryVersion_1_0		0x100

const unsigned int kSparkLibraryCurrentVersion = kSparkLibraryVersion_1_0;

@implementation SparkLibrary

+ (SparkLibrary *)defaultLibrary {
  static id shared = nil;
  if (!shared) {
    shared = [[self alloc] initWithPath:SparkDefaultLibraryPath()];
  }
  return shared;
}

+ (void)setDefaultLibrary:(SparkLibrary *)aLibrary {
  SparkLibrary *lib = [self defaultLibrary];
  if ([aLibrary->_libraries count] != [lib->_libraries count]) {
    [NSException raise:@"Invalid Library Exception" format:@"Cannot set default library."];
  }
  [lib->_libraries removeAllObjects];
  [lib->_libraries addEntriesFromDictionary:aLibrary->_libraries];
  [[lib->_libraries allValues] makeObjectsPerformSelector:@selector(setLibrary:) withObject:lib];
  [lib synchronize];
}

#pragma mark -
- (id)init {
  return [self initWithPath:nil];
}

- (id)initWithPath:(NSString *)path {
  if (self = [super init]) {
    _libraries = [[NSMutableDictionary alloc] init];
    [self setFile:path];
    if (![self load]) {
      [self release];
      self = nil;
    }
  }
  return self;
}

- (void)dealloc {
  [_filename release];
  [_libraries release];
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> %@", NSStringFromClass([self class]), self, _libraries];
}

#pragma mark -
#pragma mark Loading Methods

- (BOOL)_load {
  [_libraries setObject:[SparkActionLibrary objectsLibraryWithLibrary:self] forKey:kSparkActionLibrary];
  [_libraries setObject:[SparkApplicationLibrary objectsLibraryWithLibrary:self] forKey:kSparkApplicationLibrary];
  [_libraries setObject:[SparkKeyLibrary objectsLibraryWithLibrary:self] forKey:kSparkKeyLibrary];
  [_libraries setObject:[SparkListLibrary objectsLibraryWithLibrary:self] forKey:kSparkListLibrary];
  return YES;
}

/* Load old library file format */
- (BOOL)_loadFolder:(NSString *)folder {
  [_libraries setObject:[SparkActionLibrary objectsLibraryWithLibrary:self] forKey:kSparkActionLibrary];
  [_libraries setObject:[SparkApplicationLibrary objectsLibraryWithLibrary:self] forKey:kSparkApplicationLibrary];
  
  BOOL loaded = YES;
  id library = [SparkKeyLibrary objectsLibraryWithLibrary:self];
  loaded &= [library loadData:[NSData dataWithContentsOfFile:[folder stringByAppendingPathComponent:@"Keys.plist"]]];
  [_libraries setObject:library forKey:kSparkKeyLibrary];
  
  library = [SparkListLibrary objectsLibraryWithLibrary:self];
  loaded &= [library loadData:[NSData dataWithContentsOfFile:[folder stringByAppendingPathComponent:@"Lists.plist"]]];    
  [_libraries setObject:library forKey:kSparkListLibrary];
  if (loaded) { /* If loading successfull */
    [self setFile:[folder stringByAppendingPathComponent:kSparkLibraryDefaultFileName]];
    id manager = [NSFileManager defaultManager];
    if ([self synchronize]) { /* If synchronized, remove old files. */
      [manager removeFileAtPath:[folder stringByAppendingPathComponent:@"Keys.plist"] handler:nil];
      [manager removeFileAtPath:[folder stringByAppendingPathComponent:@"Lists.plist"] handler:nil];
    }
  }
  return loaded;
}

- (BOOL)_loadFileWrapper:(NSFileWrapper *)aWrapper {
  /* Always load actions first */
  BOOL loaded = YES;
  @try {
    id files = [aWrapper fileWrappers];
    id library = [SparkActionLibrary objectsLibraryWithLibrary:self];
    loaded &= [library loadData:[[files objectForKey:kSparkActionFile] regularFileContents]];    
    if (loaded) {
      [_libraries setObject:library forKey:kSparkActionLibrary];
      library = [SparkApplicationLibrary objectsLibraryWithLibrary:self];
      loaded &= [library loadData:[[files objectForKey:kSparkApplicationFile] regularFileContents]];    
    }
    if (loaded) {
      [_libraries setObject:library forKey:kSparkApplicationLibrary];
      library = [SparkKeyLibrary objectsLibraryWithLibrary:self];
      loaded &= [library loadData:[[files objectForKey:kSparkKeyFile] regularFileContents]];    
    }
    if (loaded) {
      [_libraries setObject:library forKey:kSparkKeyLibrary];
      library = [SparkListLibrary objectsLibraryWithLibrary:self];
      loaded &= [library loadData:[[files objectForKey:kSparkListFile] regularFileContents]];
    }
    if (loaded) {
      [_libraries setObject:library forKey:kSparkListLibrary];
    }
  } 
  @catch (id exception) {
    SKLogException(exception);
    loaded = NO;
  }
  return loaded;
}

- (BOOL)load {
  id path = [self file];
  if (!path) {
    DLog(@"WARNING: No path defined. Creating empty Library!");
    return [self _load];
  }
  
  if ([[path pathExtension] isEqualToString:kSparkLibraryFileExtension]) {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
      DLog(@"Load Wrapper Library");
      id wrapper = [[NSFileWrapper alloc] initWithPath:path];
      if (wrapper) {
        return [self _loadFileWrapper:[wrapper autorelease]];
      } else {
        DLog(@"ERROR: Invalid wrapper");
        return NO;
      }
    } else {
      DLog(@"WARNING: Library file %@ doesn't exist. Creating empty Library", path);
      return [self _load];
    }
  } else {
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir &&
        [[[NSFileManager defaultManager] directoryContentsAtPath:path] containsObject:@"Keys.plist"]) {
      DLog(@"Convert old Library");
      return [self _loadFolder:path];
    } else {
      DLog(@"ERROR: %@ isn't a Library file or folder", path);
      return NO;
    }
  }
}

- (BOOL)reload {
  [_libraries removeAllObjects];
  return [self load];
}

#pragma mark -
#pragma mark Imports
- (void)importsObjects:(NSArray *)objects inLibrary:(SparkObjectsLibrary *)aLibrary {
  id items = [objects objectEnumerator];
  id item;
  while (item = [items nextObject]) {
    if ([[item uid] unsignedIntValue] != 0) {
      [item setUid:nil];
      [aLibrary addObject:item];
    }
  }
}

- (void)importsObjects:(NSArray *)objects
           fromLibrary:(SparkLibrary *)oldLib
      toObjectsLibrary:(SparkObjectsLibrary *)newLib
     updateUidSelector:(SEL)aSel {
  
  if ([objects count]) {
    if (oldLib == self) return;
    
    id keys = [[oldLib keyLibrary] objects];
    
    /* Init Array With two object to use replaceObjectAtIndex: */
    NSMutableArray *uids = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], nil];
    id items = [objects objectEnumerator];
    id item;
    while (item = [items nextObject]) {
      if ([[item uid] unsignedIntValue]) { /* Check if it isn't a System Object */
        [uids replaceObjectAtIndex:0 withObject:[item uid]]; /* Save old UID */
        [item setUid:nil]; /* Reset Object UID */
        [newLib addObject:item]; /* Import Object => Sets a new UID */
        [uids replaceObjectAtIndex:1 withObject:[item uid]]; /* Save new UID */
        [keys makeObjectsPerformSelector:aSel withObject:uids]; /* Update old Library Keys */
      }
    }
    [uids release];
  }  
}

- (void)importsLists:(SparkListLibrary *)library {
  SparkListLibrary *lib = [self listLibrary];
  id apps = [library listsWithContentType:[SparkApplication class]];
  id lists = [NSMutableArray arrayWithArray:[library objects]];
  if ([apps count]) {
    [lists removeObjectsInArray:apps];
  }
  [self importsObjects:lists inLibrary:lib];
  [self importsObjects:apps fromLibrary:[library library] toObjectsLibrary:lib updateUidSelector:@selector(updateListUid:)];
}

- (void)importsApplications:(SparkApplicationLibrary *)library {
  id lib  = [self applicationLibrary];
  id applications = [[NSMutableArray alloc] initWithArray:[library objects]]; /* Copy Old library contents */
  id keys = [[[library library] keyLibrary] objects];
  id items = [library objectEnumerator];
  id item;
  while (item = [items nextObject]) { /* Enumerate Old Library */
    id app = [lib applicationWithIdentifier:[item identifier]];
    if (nil != app) { /* If app already in new Library... */
      NSNumber *old = [[item uid] retain];
      NSNumber *new = [app uid];
      [applications removeObjectIdenticalTo:item]; /* ...don't have to import it */
      /* Send notification to Old Library lists (and other listener) to make them refere the New Library object */
      /* If we didn't do this, they will continue to refere unimported applications */
      [[NSNotificationCenter defaultCenter] postNotificationName:kSparkLibraryDidUpdateApplicationNotification
                                                          object:[library library]
                                                        userInfo:[NSDictionary dictionaryWithObject:app
                                                                                             forKey:kSparkNotificationObject]];
      if (![old isEqualToNumber:new]) { /* If uid in new base ≠ uid in old base */
        id tmp = [library objectWithId:new];
        if (tmp) { /* Make sure than the new UID is unused */
          [tmp setUid:SKUInt([library nextUid])]; /* If another App already use it => sets a new UID */
          [keys makeObjectsPerformSelector:@selector(updateApplicationUid:) withObject:[NSArray arrayWithObjects:new, [tmp uid], nil]];
        }
  		[item setUid:new]; /* Synchronize UID in old base with UID in new base */
  		[keys makeObjectsPerformSelector:@selector(updateApplicationUid:) withObject:[NSArray arrayWithObjects:old, new, nil]];
      }
      [old release];
    }
  }
  /* Imports only applications that aren't in new base */
  [self importsObjects:applications fromLibrary:[library library] toObjectsLibrary:lib updateUidSelector:@selector(updateApplicationUid:)]; 
}

- (void)importsActions:(SparkActionLibrary *)library {
  [self importsObjects:[library objects] fromLibrary:[library library] toObjectsLibrary:[self actionLibrary] updateUidSelector:@selector(updateActionUid:)];   
}
- (void)importsHotKeys:(SparkKeyLibrary *)library {
  [self importsObjects:[library objects] inLibrary:[self keyLibrary]]; 
}

- (void)importsObjectsFromLibrary:(SparkLibrary *)aLibrary {
  if (self != aLibrary) {
    [self importsApplications:[aLibrary applicationLibrary]];
    [self importsActions:[aLibrary actionLibrary]];
    [self importsLists:[aLibrary listLibrary]];
    [self importsHotKeys:[aLibrary keyLibrary]];
    [aLibrary->_libraries removeAllObjects];
  }
}

#pragma mark -
#pragma mark Objects Libraries Accessors
- (id)libraryForKey:(NSString *)aKey {
  NSAssert1([_libraries objectForKey:aKey] != nil, @"Library for key: %@ doesn't exist", aKey);
  return [_libraries objectForKey:aKey];
}


- (SparkKeyLibrary *)keyLibrary {
  return [self libraryForKey:kSparkKeyLibrary];
}

- (SparkListLibrary *)listLibrary {
  return [self libraryForKey:kSparkListLibrary];
}

- (SparkActionLibrary *)actionLibrary {
  return [self libraryForKey:kSparkActionLibrary];
}

- (SparkApplicationLibrary *)applicationLibrary {
  return [self libraryForKey:kSparkApplicationLibrary];
}

#pragma mark -
#pragma mark FileSystem Methods
- (NSString *)file {
  return _filename;
}

- (void)setFile:(NSString *)file {
  if (_filename != file) {
    [_filename release];
    _filename = [file copy];
  }
}

- (NSFileWrapper *)fileWrapper {
  id library = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
  while (YES) {
    id data;
    /* SparkHotKeys */
    data = [[self libraryForKey:kSparkKeyLibrary] serialize];
    if (nil == data) {
      break;
    } 
    [library addRegularFileWithContents:data preferredFilename:kSparkKeyFile];
    /* SparkLists */
    data = [[self libraryForKey:kSparkListLibrary] serialize];
    if (nil == data) {
      break;
    }  
    [library addRegularFileWithContents:data preferredFilename:kSparkListFile];
    /* SparkActions */
    data = [[self libraryForKey:kSparkActionLibrary] serialize];
    if (nil == data) {
      break;
    } 
    [library addRegularFileWithContents:data preferredFilename:kSparkActionFile];
    /* SparkApplications */
    data = [[self libraryForKey:kSparkApplicationLibrary] serialize];
    if (nil == data) {
      break;
    }  
    [library addRegularFileWithContents:data preferredFilename:kSparkApplicationFile];
    
    id info = [NSDictionary dictionaryWithObjectsAndKeys:
      SKUInt(kSparkLibraryCurrentVersion), @"Version",
      nil];
    id infoData = [NSPropertyListSerialization dataFromPropertyList:info
                                                             format:NSPropertyListXMLFormat_v1_0
                                                   errorDescription:nil];
    if (info) {
      [library addRegularFileWithContents:infoData preferredFilename:@"Info.plist"];
    } else {
      break;
    }
    return [library autorelease];
  };
  DLog(@"ERROR: Unable to create filewrapper for Library : %@", self);
  [library release];
  return nil;
}

- (void)flush {
  [_libraries removeAllObjects];
  [self _load];
}

- (BOOL)synchronize {
  if (_filename) {
    return [self writeToFile:_filename atomically:YES];
  } else {
    [NSException raise:@"InvalidFileException" format:@"You Must set a file before synchronizing"];
    return NO;
  }
}

- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)flag {
  NSParameterAssert(file != nil);
  
  NSFileWrapper* wrapper = [self fileWrapper];
  if (wrapper)
    return [wrapper writeToFile:file atomically:flag updateFilenames:NO];
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

static NSString *SparkDefaultLibraryPath() {
  NSString *folder = SparkLibraryFolder();
  id contents = [[NSFileManager defaultManager] directoryContentsAtPath:folder];
  if ([contents containsObject:kSparkLibraryDefaultFileName] || ![contents containsObject:@"Keys.plist"]) {
    return [folder stringByAppendingPathComponent:kSparkLibraryDefaultFileName];
  } else {
    return folder;
  }
}

__inline__ SparkLibrary *SparkDefaultLibrary() {
   return [SparkLibrary defaultLibrary];
 }

__inline__ SparkKeyLibrary *SparkDefaultKeyLibrary() {
  return [[SparkLibrary defaultLibrary] keyLibrary];
}

__inline__ SparkListLibrary *SparkDefaultListLibrary() {
  return [[SparkLibrary defaultLibrary] listLibrary];
}

__inline__ SparkActionLibrary *SparkDefaultActionLibrary() {
  return [[SparkLibrary defaultLibrary] actionLibrary];
}

__inline__ SparkApplicationLibrary *SparkDefaultApplicationLibrary() {
  return [[SparkLibrary defaultLibrary] applicationLibrary];
}

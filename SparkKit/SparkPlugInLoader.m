//
//  SparkPlugInLoader.m
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "SKFunctions.h"
#import "ShadowMacros.h"
#import "SKExtensions.h"
#import "SKFSFunctions.h"

#import "SparkConstantes.h"

#import "SparkPlugInLoader.h"
#import "SparkPlugIn.h"
#import "Extension.h"

static void PlugInsFolderDidChange(FNMessage message, OptionBits flags, void * manager, FNSubscriptionRef subscription);

static NSString *buildInPath = nil;

NSString * const kSparkDidAddPlugInNotification = @"SparkDidAddPlugInNotification";
NSString * const kSparkDidRemovePlugInNotification = @"SparkDidRemovePlugInNotification";

@implementation SparkPlugInLoader

+ (id)sharedLoader {
  static id list = nil;
  @synchronized (self) {
    if (!list) {
      list = [[self alloc] init];
    }
  }
  return list;
}

+ (NSString *)buildInPath {
  return (buildInPath) ? buildInPath : [[NSBundle mainBundle] builtInPlugInsPath];
}
+ (void)setBuildInPath:(NSString *)newPath {
  if (buildInPath != newPath) {
    [buildInPath release];
    buildInPath = [newPath copy];
  }
}

#pragma mark -
- (id)init {
  if (self = [super init]) {
    [self discoverPlugIns];
    [self subscribeFileNotification];
  }
  return self;
}

- (void)dealloc {
  [sk_plugIns release];
  [super dealloc];
}

#pragma mark -
+ (NSString *)extension {
  return @"plugIn";
}

+ (NSArray *)plugInPaths {
  NSString *plugInsPath = [kSparkFolderName stringByAppendingPathComponent:@"/PlugIns/"];
  NSString *appPath = [[self class] buildInPath];
  NSString *userPath = [SKFindFolder(kApplicationSupportFolderType, kUserDomain) stringByAppendingPathComponent:plugInsPath];
  NSString *locPath = [SKFindFolder(kApplicationSupportFolderType, kLocalDomain) stringByAppendingPathComponent:plugInsPath];
  NSString *netPath = [SKFindFolder(kApplicationSupportFolderType, kNetworkDomain) stringByAppendingPathComponent:plugInsPath];
  return [NSArray arrayWithObjects:userPath, locPath, netPath, appPath, nil]; // order: User, Library, Network and Built-in
}

- (NSString *)extension {
  return [[self class] extension];
}

#pragma mark -
- (NSArray *)plugIns {
  return [sk_plugIns allValues];
}

- (id)plugInForClass:(Class)class {
  return [sk_plugIns objectForKey:NSStringFromClass(class)];
}

#pragma mark -
#pragma mark Plugin Loader
- (void)discoverPlugIns {
  if (sk_plugIns) return;
  NSArray *paths = [[self class] plugInPaths];
  NSEnumerator *pathEnum = [paths objectEnumerator];
  NSString *path;
  
  sk_plugIns = [[NSMutableDictionary alloc] init];
  
  while ( path = [pathEnum nextObject] ) {
    [sk_plugIns addEntriesFromDictionary:[self plugInsAtPath:path]];
  }
}

- (NSDictionary *)plugInsAtPath:(NSString *)path {
  NSString *name;
  id plugs = [NSMutableDictionary dictionary];
  NSEnumerator *e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
  id plugIn;
  while ( name = [e nextObject] ) {
    if ( [[name pathExtension] isEqualToString:[self extension]] ) {
      NSBundle *bundle = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:name]];
      // Pour eviter de charger une class déja presente, on verifie si elle existe
      @try {
        if (![sk_plugIns objectForKey:[bundle objectForInfoDictionaryKey:@"NSPrincipalClass"]]) {
          plugIn = [self loadPlugInBundle:bundle];
          if (plugIn) {
            DLog(@"Load plugIn: %@", [bundle bundlePath]);
            [plugs setObject:plugIn forKey:NSStringFromClass([bundle principalClass])];
          }
        }
      }
      @catch (id exception) {
        SKLogException(exception);
      }
    }
  }
  return plugs;
}

- (id)loadPlugInBundle:(NSBundle *)bundle {
  id plug = nil;
  Class principalClass = [bundle principalClass];
  if (principalClass) {
    plug = [NSMutableDictionary dictionary];
    [plug setObject:principalClass forKey:@"principalClass"];
    [plug setObject:[bundle bundlePath] forKey:@"path"];
  }
  return plug;
}

#pragma mark -
#pragma mark Plugin Folder Observer
- (void)subscribeFileNotification {
  NSArray *paths = [[self class] plugInPaths];
  NSEnumerator *pathEnum = [paths objectEnumerator];
  id path;
  while ( path = [pathEnum nextObject] ) {
    [self subscribeForPath:path];
  }
}

- (void)subscribeForPath:(NSString *)path {
  FNSubscriptionRef subscription, *ref;
  FSRef folder;
  if ([path getFSRef:&folder]) {
    OSStatus err = FNSubscribe (&folder,
                                NewFNSubscriptionUPP(PlugInsFolderDidChange),
                                self,
                                kNilOptions,
                                &subscription);
    if (noErr == err) {
      ref = refs;
      while (*ref != nil) ref++;
      *ref = subscription;
    }
  }
}

- (void)unsubscribeAll {
  FNSubscriptionRef *ref;
  ref = refs;
  while (*ref != nil)  {
    FNUnsubscribe(*ref);
    ref++;
  }
}

- (NSArray *)missingPlugIns {
  id values = [sk_plugIns objectEnumerator];
  id missing = [NSMutableArray array];
  id item;
  while (item = [values nextObject]) {
    if (![[NSFileManager defaultManager] fileExistsAtPath:[item valueForKey:@"path"]]) {
      id class = NSStringFromClass([item valueForKey:@"principalClass"]);
      if (class)
        [missing addObject:class];
#if defined (DEBUG)
      NSLog(@"Bundle removed from path: %@", [item path]);
    }
    else {
      NSLog(@"Bundle exist at path: %@", [item path]);
#endif
    }
  }
  return missing;
}

- (void)addPlugIns:(NSDictionary *)plugIns {
  [sk_plugIns addEntriesFromDictionary:plugIns];
  id plugs = [plugIns objectEnumerator];
  id plug;
  while (plug = [plugs nextObject]) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kSparkDidAddPlugInNotification object:[[plug retain] autorelease]];
  }
}

- (void)removePlugInForClass:(id)key {
  id plug = [sk_plugIns objectForKey:key];
  if (plug) {
    [[plug retain] autorelease];
    [sk_plugIns removeObjectForKey:key];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSparkDidRemovePlugInNotification object:plug];
  }
}

- (void)removePlugInsForClasses:(NSArray *)keys {
  id old = [keys objectEnumerator];
  id key;
  while (key = [old nextObject]) {
    [self removePlugInForClass:key];
  }
}

- (void)plugInFolderChanged:(NSString *)folder {
  [self removePlugInsForClasses:[self missingPlugIns]];
  [self addPlugIns:[self plugInsAtPath:folder]];
}

void PlugInsFolderDidChange(FNMessage message, OptionBits flags, void * manager, FNSubscriptionRef subscription) {
  FSRef folder;
  OSStatus err = FNGetDirectoryForSubscription (subscription, &folder);
  if (noErr == err) {
    id path = [NSString stringFromFSRef:&folder];
    [(id)manager plugInFolderChanged:path];
  }
}

@end

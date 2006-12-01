//
//  SparkExporter.m
//  Spark
//
//  Created by Fox on Fri Feb 27 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//
#import <SparkKit/SparkKit.h>

#import "SparkExporter.h"

const OSType kSparkKeyFileType = 'SpKe';
NSString * const kSparkKeyFileExtension = @"spkey";

const OSType kSparkListFileType = 'SpLi';
NSString * const kSparkListFileExtension = @"splist";

@interface SparkListFormatExporter : SparkExporter {
}

@end

@interface SparkHTMLFormatExporter : SparkExporter {
  id head, tableHead, row, tableFoot, foot;
  NSFileHandle *output;
}
- (void)parseTemplate;
- (void)writeTableHeadWithName:(NSString *)title;
- (void)writeRowWithKeys:(NSArray *)keys;
@end

@implementation SparkExporter

- (id)init {
  if ([self isMemberOfClass:[SparkExporter class]]) { 
    [self release];
    self = nil;
  }
  else {
    self = [super init];
  }
  return self;
}

- (id)initWithFormat:(int)format {
  [self release];
  self = nil;
  switch (format) {
    case kSparkListFormat:
      self = [[SparkListFormatExporter alloc] init];
      break;
    case kHTMLFormat:
      self = [[SparkHTMLFormatExporter alloc] init];
      break;    
  }
  return self;
}

- (BOOL)exportList:(SparkObjectList *)list toFile:(NSString *)file{
  return NO;
}

- (void)setIcon:(NSString *)iconName forFile:(id)file {
  id iconPath = [[NSBundle mainBundle] pathForResource:iconName ofType:@"icns"];
  if (iconPath) {
    IconFamilyHandle family;
    id iconUrl = [[NSURL alloc] initFileURLWithPath:iconPath];
    if (SKIconReadIconFamilyFromURL((CFURLRef)iconUrl, &family)) {
      SKIconSetCustomIconAtPath(family, (CFStringRef)file, kCFURLPOSIXPathStyle, NO);
      DisposeHandle((Handle)family);
    }
    [iconUrl release];
  }
}

@end

#pragma mark -

#define kLibraryVersion_1_0		0x100
#define kLibraryVersion_1_1		0x110
#define kLibraryVersion_2_0		0x200

static CFXMLTreeRef TreeWithData(CFStringRef data);
static CFXMLTreeRef findRefWithData(CFXMLTreeRef tree, CFStringRef data);

const unsigned int kLibraryCurrentVersion = kLibraryVersion_2_0;

@implementation SparkListFormatExporter

- (NSArray *)plistForObjects:(NSArray *)objects {
  NSMutableArray *plist = [NSMutableArray array];
  id items = [objects objectEnumerator];
  id item;
  while (item = [items nextObject]) {
    @try {
      [plist addObject:SparkSerializeObject(item)];
    }
    @catch (id exception) {
      SKLogException(exception);
    }
  }
  return plist;
}

NSString * const kSparkExportListKey = @"List";
NSString * const kSparkExportListObjects = @"Objects";
NSString * const kSparkExportListVersion = @"Version";
NSString * const kSparkExportListContentType = @"ContentType";

NSString * const kSparkExportLists = @"SparkLists";
NSString * const kSparkExportHotKeys = @"SparkHotKeys";
NSString * const kSparkExportActions = @"SparkActions";
NSString * const kSparkExportApplications = @"SparkApplications";

- (id)plistContentsForKeyList:(SparkKeyList *)list {
  id plist = [[NSMutableDictionary alloc] init];
  id keys = [[list objects] objectEnumerator];
  SparkHotKey *key;
  NSMutableSet *lists = [[NSMutableSet alloc] init];
  NSMutableSet *actions = [[NSMutableSet alloc] init];
  NSMutableSet *applications = [[NSMutableSet alloc] init];
  while (key = [keys nextObject]) {
    id map = [key map];
    [lists addObjectsFromArray:[[map lists] allObjects]];
    [actions addObjectsFromArray:[[map actions] allObjects]];
    [applications addObjectsFromArray:[[map applications] allObjects]];
  }
  [plist setObject:[self plistForObjects:[list objects]] forKey:kSparkExportHotKeys];
  [plist setObject:[self plistForObjects:[lists allObjects]] forKey:kSparkExportLists];
  [plist setObject:[self plistForObjects:[actions allObjects]] forKey:kSparkExportActions];
  [plist setObject:[self plistForObjects:[applications allObjects]] forKey:kSparkExportApplications];
  [lists release];
  [actions release];
  [applications release];
  return [plist autorelease];
}

- (id)plistContentsForActionList:(SparkActionList *)list {
  id plist = [[NSMutableDictionary alloc] init];
  [plist setObject:[self plistForObjects:[list objects]] forKey:kSparkExportActions];
  return [plist autorelease];
}

- (id)plistContentsForApplicationList:(SparkApplicationList *)list {
  id plist = [[NSMutableDictionary alloc] init];
  [plist setObject:[self plistForObjects:[list objects]] forKey:kSparkExportApplications];
  return [plist autorelease];
}

- (BOOL)exportList:(SparkObjectList *)list toFile:(NSString *)file {
  NSString *icon;
  id plist = [[NSMutableDictionary alloc] init];
  [plist setObject:SKUInt(0x100) forKey:kSparkExportListVersion];
  [plist setObject:NSStringFromClass([list contentType]) forKey:kSparkExportListContentType];
  if ([list isEditable])
    [plist setObject:SparkSerializeObject(list) forKey:kSparkExportListKey];
  
  if ([[list contentType] isSubclassOfClass:[SparkHotKey class]]) {
    icon = @"HotKeySparkList";
    [plist setObject:[self plistContentsForKeyList:(id)list] forKey:kSparkExportListObjects];
  } else if ([[list contentType] isSubclassOfClass:[SparkAction class]]) {
    icon = @"ActionSparkList";
    [plist setObject:[self plistContentsForActionList:(id)list] forKey:kSparkExportListObjects];
  } else if ([[list contentType] isSubclassOfClass:[SparkApplication class]]) {
    icon = @"ApplicationSparkList";
    [plist setObject:[self plistContentsForApplicationList:(id)list] forKey:kSparkExportListObjects];
  } else {
    [plist release];
    return NO;
  }
  
  id error = nil;
  NSData* data = [NSPropertyListSerialization dataFromPropertyList:plist
                                                            format:SparkLibraryFileFormat //NSPropertyListBinaryFormat_v1_0
                                                  errorDescription:&error];
  [plist release];
  if (!data) {
    NSLog(error);
    [error release];
    return NO;
  }
  BOOL write = [data writeToFile:file atomically:YES];
  
  if (write) {
    id attr = [NSDictionary dictionaryWithObjectsAndKeys:
      SKUInt(kSparkListFileType), NSFileHFSTypeCode,
      SKUInt(kSparkHFSCreatorType), NSFileHFSCreatorCode , nil];
    [[NSFileManager defaultManager] changeFileAttributes:attr atPath:file];
    [self setIcon:icon forFile:file];
  } 
  return write;
}

@end

#pragma mark ==> HTML Utils ¥

#define BEGIN_TABLE_TAG			@"<!-- BeginListTable -->"
#define BEGIN_ROW_TAG			@"<!-- BeginActionRow -->"
#define END_ROW_TAG				@"<!-- EndActionRow -->"
#define END_TABLE_TAG			@"<!-- EndListTable -->"

CFXMLTreeRef findRefWithData(CFXMLTreeRef tree, CFStringRef data) {
  CFXMLTreeRef result = nil;
  CFXMLNodeRef xmlNode = nil;
  
  CFTreeRef curChild = CFTreeGetFirstChild(tree);
  for (; curChild && !result; curChild = CFTreeGetNextSibling(curChild)) {
    xmlNode = CFXMLTreeGetNode(curChild);
    int type = CFXMLNodeGetTypeCode(xmlNode);
    if (kCFXMLNodeTypeText == type) {
      if (CFStringCompare(data, CFXMLNodeGetString(xmlNode), 0) == kCFCompareEqualTo) {
        result = curChild;
      }
    }
    else {
      result = findRefWithData(curChild, data);
    }
  }
  return result;
}

CFXMLTreeRef TreeWithData(CFStringRef data) {
  CFXMLNodeRef node = CFXMLNodeCreate (kCFAllocatorDefault,
                                       kCFXMLNodeTypeText,
                                       data,
                                       nil,
                                       kCFXMLNodeCurrentVersion);
  return CFXMLTreeCreateWithNode(kCFAllocatorDefault, node);
}

@implementation SparkHTMLFormatExporter

- (void)dealloc {
  [head release];
  [tableHead release];
  [row release];
  [tableFoot release];
  [foot release];
  [super dealloc];
}

- (BOOL)exportList:(SparkObjectList *)list toFile:(NSString *)file{
  id manager = [NSFileManager defaultManager];
  BOOL isDir = NO;
  if ([manager fileExistsAtPath:file isDirectory:&isDir]) {
    if (isDir) return NO;
    [manager removeFileAtPath:file handler:nil];
  }
  if (![manager createFileAtPath:file contents:nil attributes:nil]) {
    return NO;
  }
  [self parseTemplate];
  
  output = [NSFileHandle fileHandleForWritingAtPath:file];
  if (!output) {
    return NO;
  }
  [output writeData:[head dataUsingEncoding:NSUTF8StringEncoding]];

  id desc = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
  id descs = [NSArray arrayWithObject:desc];
  [desc release];
  id sortedKeys = nil;
  if ([[list objects] count] > 0) {
    SparkPlugIn *plugin;
    sortedKeys = [[[list objects] sortedArrayUsingDescriptors:descs] mutableCopy];
    id plugins = [[[[SparkActionLoader sharedLoader] plugins] sortedArrayUsingDescriptors:descs] objectEnumerator];
    while (plugin = [plugins nextObject]) {
      NSMutableArray *keys = [[NSMutableArray alloc] init];
      unsigned idx;
      for (idx = 0; idx<[sortedKeys count]; idx++) {
        id key = [sortedKeys objectAtIndex:idx];
        if (![key hasManyActions] && [[key defaultAction] isKindOfClass:[plugin actionClass]]) {
          [keys addObject:key];
        }
      }
      if ([keys count]) {
        [sortedKeys removeObjectsInArray:keys];
        [self writeTableHeadWithName:[plugin name]];
        [self writeRowWithKeys:keys];
        [output writeData:[tableFoot dataUsingEncoding:NSUTF8StringEncoding]];
      }
      [keys release];
    }
    if ([sortedKeys count]) {
      [self writeTableHeadWithName:@"Custom"];
      [self writeRowWithKeys:sortedKeys];
      [output writeData:[tableFoot dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [sortedKeys release];
  }

  [output writeData:[foot dataUsingEncoding:NSUTF8StringEncoding]];
  [output closeFile];
  output = nil;
  return YES;
}

- (void)parseTemplate {
  NSString *tplFile = [[NSBundle mainBundle] pathForResource:@"shcts" ofType:@"html"];
  id template = [NSString stringWithContentsOfFile:tplFile];
  
  int start = 0, end = [template rangeOfString:BEGIN_TABLE_TAG].location;
  head = [[template substringToIndex:end] retain];
  
  start = end + [BEGIN_TABLE_TAG length];
  end = [template rangeOfString:BEGIN_ROW_TAG].location;
  tableHead = [[template substringWithRange:NSMakeRange(start, end-start)] retain];
  
  start = end + [BEGIN_ROW_TAG length];
  end = [template rangeOfString:END_ROW_TAG].location;
  row = [[template substringWithRange:NSMakeRange(start, end-start)] retain]; 
  
  start = end + [END_ROW_TAG length];
  end = [template rangeOfString:END_TABLE_TAG].location;
  tableFoot = [[template substringWithRange:NSMakeRange(start, end-start)] retain];
  
  start = end + [END_TABLE_TAG length];
  foot = [[template substringFromIndex:start] retain];
}

- (void)writeTableHeadWithName:(NSString *)title {
  NSMutableString *str = [tableHead mutableCopy];
  [str replaceOccurrencesOfString:@"@ListTitle" withString:title options:NSLiteralSearch range:NSMakeRange(0, [str length])];
  [output writeData:[str dataUsingEncoding:NSUTF8StringEncoding]];
  [str release];
}

- (void)writeRowWithKeys:(NSArray *)keys {
  CFDataRef xmlData = (CFDataRef)[row dataUsingEncoding:NSUTF8StringEncoding];
  CFXMLTreeRef templateTree = nil;

  if (xmlData) {
    templateTree = CFXMLTreeCreateFromData(kCFAllocatorDefault,
                                           xmlData, 
                                           nil, 
                                           kCFXMLParserNoOptions,
                                           kCFXMLNodeCurrentVersion);
  }
  if (templateTree) {
    CFXMLTreeRef actionTree = findRefWithData(templateTree, CFSTR("@Action"));
    CFXMLTreeRef shortcutTree = findRefWithData(templateTree, CFSTR("@Shortcut"));
    
    id items = [keys objectEnumerator];
    id item;
    CFXMLTreeRef action, shortcut;
    while (item = [items nextObject]) {
      action = TreeWithData((CFStringRef)[item name]);
      CFTreeInsertSibling (actionTree, action);
      CFTreeRemove(actionTree);
      actionTree = action;
      
      shortcut = TreeWithData((CFStringRef)[item shortCut]);
      CFTreeInsertSibling (shortcutTree, shortcut);
      CFTreeRemove(shortcutTree);
      shortcutTree = shortcut;
      
      NSData *data = (id)CFXMLTreeCreateXMLData(kCFAllocatorDefault, templateTree);
      [output writeData:data];
      [data release];
    }
    CFRelease(templateTree);
  }
}
@end
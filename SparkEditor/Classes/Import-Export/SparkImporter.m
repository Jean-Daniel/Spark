//
//  SparkImporter.m
//  Spark Editor
//
//  Created by Grayfox on 8/11/2004.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "SparkImporter.h"

#import <SparkKit/SparkKit.h>
#import "Extensions.h"
#import "SparkExporter.h"
#import "CustomTableDataSource.h"

#pragma mark -
@interface ImportedObject : NSObject {
  id object;
  BOOL import;
}

+ (id)importedObjectWithObject:(id)anObject;
- (id)initWithObject:(id)anObject;

- (id)object;
- (void)setObject:(id)newObject;

- (BOOL)import;
- (void)setImport:(BOOL)newImport;

@end

@interface CategorieTransformer : NSValueTransformer {
  id images;
}
@end

extern BOOL SearchByName(NSString *searchString, id object, void *ctxt);
static BOOL CustomSearch(NSString *searchString, id object, void *ctxt);

@implementation SparkImporter

+ (void)initialize {
  BOOL tooLate = NO;
  if (!tooLate) {
    id transformer = [[[CategorieTransformer alloc] init] autorelease];
    [NSValueTransformer setValueTransformer:transformer forName:@"CategorieTransformer"]; 
    tooLate = YES;
  }
}

- (id)init {
  if (self = [super initWithWindowNibName:@"Importer"]) {
    importType = 0;
  }
  return self;
}

- (void)dealloc {
  ShadowTrace();
  [_library release];
  [super dealloc];
}

- (void)awakeFromNib {
  [tableController setFilterFunction:CustomSearch context:self];
  id items = [[searchMenu itemArray] objectEnumerator];
  id item;
  while (item = [items nextObject]) {
    if ([item tag] != 0) {
      [item setTarget:self];
      [item setAction:@selector(changeFilter:)];
    }
  }
  [[searchField cell] setSearchMenuTemplate:searchMenu];
}

- (int)searchCategorie {
  return _categorie;
}

- (void)setSearchCategorie:(int)aCategorie {
  if (_categorie != aCategorie) {
    _categorie = aCategorie;
  }
}

- (IBAction)changeFilter:(id)sender {
  if ([sender tag] > 0) {
    [self setSearchCategorie:[sender tag]];
    [[searchField cell] setPlaceholderString:[sender title]];
    [tableController rearrangeObjects];
  }
}

- (void)setSerializedList:(id)plist {
  SparkLibrary *library = [[SparkLibrary alloc] init];
  id items;
  id objects = [plist objectForKey:kSparkExportListObjects];
  
  /* Load Actions */
  items = [objects objectForKey:kSparkExportActions];
  if (items && [items count]) {
    [[library actionLibrary] loadObjects:items];
  }
  /* Load Applications */
  items = [objects objectForKey:kSparkExportApplications];
  if (items && [items count]) {
    [[library applicationLibrary] loadObjects:items];
  }
  /* Load HotKeys */
  items = [objects objectForKey:kSparkExportHotKeys];
  if (items && [items count]) {
    [[library keyLibrary] loadObjects:items];
  }
  /* Load Lists */
  items = [objects objectForKey:kSparkExportLists];
  if (items && [items count]) {
    [[library listLibrary] loadObjects:items];
  }
  /* Load Exported List */
  id list = [plist objectForKey:kSparkExportListKey];
  if (list) {
    [[library listLibrary] loadObject:list];
  }
  [self setLibrary:library];
  [library release];
}

- (void)setLibrary:(SparkLibrary *)library {
  [self window];
  if (_library != library) {
    [_library release];
    _library = [library retain];
    [tableController removeAllObjects];
    id items = [[library keyLibrary] objectEnumerator];
    id item;
    while (item = [items nextObject]) {
      [tableController addObject:[ImportedObject importedObjectWithObject:item]];
    }
    
    items = [[library listLibrary] objectEnumerator];
    while (item = [items nextObject]) {
      [tableController addObject:[ImportedObject importedObjectWithObject:item]];
    }
    
    /* Filter Custom Actions +  System Objects */
    items = [[library actionLibrary] objectEnumerator];
    while (item = [items nextObject]) {
      if ([[item uid] unsignedIntValue] != 0 && [item isCustom]) {
        [tableController addObject:[ImportedObject importedObjectWithObject:item]];
      }
    }
    
    items = [[library applicationLibrary] objectEnumerator];
    while (item = [items nextObject]) {
      if ([[item uid] unsignedIntValue] != 0) {
        [tableController addObject:[ImportedObject importedObjectWithObject:item]];
      }
    }

    [tableController rearrangeObjects];
    [tableController setSelectionIndex:0];
  }
}

- (void)setImportForAll:(BOOL)import {
  id items = [[tableController arrangedObjects] objectEnumerator];
  id item;
  while (item = [items nextObject]) {
    [item setImport:import];
  }
}

- (IBAction)checkAll:(id)sender {
  [self setImportForAll:YES];
}

- (IBAction)uncheckAll:(id)sender {
  [self setImportForAll:NO];
}

- (IBAction)import:(id)sender {
  if (importType != 0) {
    id items = [tableController objectEnumerator];
    id item;
    
    while (item = [items nextObject]) {
      if (![item import]) {
        item = [item object];
        if ([item isKindOfClass:[SparkHotKey class]]) {
          [item setDefaultAction:nil]; /* Delete Action if not custom */
        }
        id lib = [item objectsLibrary];
        [lib removeObject:item];
      }
    }
  }
  [SparkDefaultLibrary() importsObjectsFromLibrary:_library];
  [_library release];
  _library = nil;
  [self close];
}

- (IBAction)cancel:(id)sender {
  [self close];
}

- (void)close {
  [controller setContent:nil];
  if ([[self window] isSheet]) {
    [NSApp endSheet:[self window]];
  }
  [super close];
}

@end
 
@implementation CategorieTransformer

+ (Class)transformedValueClass {
  return [NSString self];  
}

+ (BOOL)allowsReverseTransformation {
  return NO;  
}

- (NSImage *)imageForObjectKind:(Class)kind {
  id img = [images objectForKey:kind];
  if (!img) {
    if (kind == [SparkHotKey class]) img = [NSImage imageNamed:@"KeyIcon" inBundle:[NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier]];
    else if (kind == [SparkObjectList class]) img = [NSImage imageNamed:@"KeyList" inBundle:[NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier]];
    else if (kind == [SparkAction class]) img = [NSImage imageNamed:@"ActionsItem"];
    else if (kind == [SparkApplication class]) img = [NSImage imageNamed: @"ApplicationListIcon"];
    if (img)
      img = SKResizedIcon(img, SKScaleProportionally([img size], NSMakeRect(0, 0, 16, 14)));
    img = (img) ? img : [NSNull null];
    [images setObject:img forKey:kind];
  }
  return img;
}

- (id)transformedValue:(id)beforeObject {
  if (beforeObject == nil) return nil;
  beforeObject = [beforeObject object];
  if ([beforeObject isKindOfClass:[SparkHotKey class]]) {
    return [self imageForObjectKind:[SparkHotKey class]];
  } else if ([beforeObject isKindOfClass:[SparkObjectList class]]) {
    return [self imageForObjectKind:[SparkObjectList class]];
  } else if ([beforeObject isKindOfClass:[SparkAction class]]) {
    return [self imageForObjectKind:[SparkAction class]];
  } else if ([beforeObject isKindOfClass:[SparkApplication class]]) {
    return [self imageForObjectKind:[SparkApplication class]];
  }
  return nil;
}

@end

#pragma mark -
@implementation ImportedObject

+ (id)importedObjectWithObject:(id)anObject {
  return [[[self alloc] initWithObject:anObject] autorelease];
}

- (id)initWithObject:(id)anObject {
  if (self = [super init]) {
    [self setImport:YES];
    [self setObject:anObject];
  }
  return self;
}

- (void)dealloc {
  [object release];
  [super dealloc];
}

- (id)object {
  return object;
}
- (void)setObject:(id)anObject {
  if (object != anObject) {
    [object release];
    object = [anObject retain];
  }
}

- (BOOL)import {
  return import;
}

- (void)setImport:(BOOL)newImport {
  if (import != newImport) {
    import = newImport;
  }
}

#pragma mark -
- (NSArray *)exposedBindings {
  return [[super exposedBindings] arrayByAddingObjectsFromArray:[object exposedBindings]];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
  id sign = [super methodSignatureForSelector:aSelector];
  if (sign) {
    return sign;
  }
  return [object methodSignatureForSelector:aSelector];
}
+ (NSMethodSignature *)instanceMethodSignatureForSelector:(SEL)aSelector {
  id sign = [super methodSignatureForSelector:aSelector];
  if (sign) {
    return sign;
  }
  return [[SparkLibraryObject class] instanceMethodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
  if ([object respondsToSelector:[anInvocation selector]]) {
    [anInvocation invokeWithTarget:object];
  }
  else {
    [super forwardInvocation:anInvocation];
  }
}

- (BOOL)respondsToSelector:(SEL)aSelector {
  if ([super respondsToSelector:aSelector]) {
    return YES;
  }
  else {
    return [object respondsToSelector:aSelector];
  }
}
+ (BOOL)instancesRespondToSelector:(SEL)aSelector {
  if ([super instancesRespondToSelector:aSelector]) {
    return YES;
  }
  else {
    return [[SparkLibraryObject class] instancesRespondToSelector:aSelector];
  }
}

- (BOOL)isKindOfClass:(Class)aClass {
  if ([super isKindOfClass:aClass]) {
    return YES;
  }
  else {
    return [object isKindOfClass:aClass];
  }
}
+ (BOOL)isSubclassOfClass:(Class)aClass {
  if ([super isSubclassOfClass:aClass]) {
    return YES;
  }
  else {
    return [[SparkLibraryObject class] isSubclassOfClass:aClass];
  }
}

- (id)valueForUndefinedKey:(NSString *)key {
  return [object valueForKey:key];
}

@end

static BOOL CustomSearch(NSString *searchString, id object, void *ctxt) {
  object = [object object];
  switch ([(id)ctxt searchCategorie]) {
    case 1:
      if (![object isKindOfClass:[SparkObjectList class]])
        return NO;
      break;
    case 2:
      if (![object isKindOfClass:[SparkAction class]])
        return NO;
      break;
    case 3:
      if (![object isKindOfClass:[SparkHotKey class]])
        return NO;
      break;
    case 4:
      if (![object isKindOfClass:[SparkApplication class]])
        return NO;
      break;
  }
  return SearchByName(searchString, object, nil);
}

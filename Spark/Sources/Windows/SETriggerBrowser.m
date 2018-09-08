/*
 *  SETriggerBrowser.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SETriggerBrowser.h"
#import "SELibraryDocument.h"

#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkEntryManager.h>

#import <WonderBox/WonderBox.h>

#import <HotKeyToolKit/HKKeyMap.h>

@interface SEBooleanToImageTransformer : NSValueTransformer {
}
@end

@implementation SETriggerBrowser {
@private
  SparkLibrary *se_library;
}

+ (void)initialize {
  if ([SETriggerBrowser class] == self) {
    SEBooleanToImageTransformer *transformer;
    
    // create an autoreleased instance of our value transformer
    transformer = [[SEBooleanToImageTransformer alloc] init];
    
    // register it with the name that we refer to it with
    [NSValueTransformer setValueTransformer:transformer
                                    forName:@"SEBooleanToImageTransformer"];
  }
}

- (id)init {
  if (self = [super initWithWindowNibName:@"SETriggerBrowser"]) {
  }
  return self;
}

- (void)dealloc {
  [self setLibrary:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (SparkLibrary *)library {
  return se_library;
}

- (void)windowDidLoad {
  [[self window] center];
  [[self window] setFrameAutosaveName:@"SparkBrowserWindow"];
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  if (se_library != aLibrary) {
    se_library = aLibrary;
  }
}

- (void)setDocument:(SELibraryDocument *)aDocument {
  NSParameterAssert(!aDocument || [aDocument isKindOfClass:[SELibraryDocument class]]);
  if ([self document]) {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SEDocumentDidSetLibraryNotification
                                                  object:[self document]];
  }
  [super setDocument:aDocument];
  [self setLibrary:[aDocument library]];
  if ([self document]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(libraryDidChange:)
                                                 name:SEDocumentDidSetLibraryNotification
                                               object:[self document]];
  }
}

- (NSArray *)entries:(SparkTrigger *)trigger {
  NSMutableArray *result = [NSMutableArray array];
  NSArray *entries = [[se_library entryManager] entriesForTrigger:trigger];
  NSInteger idx = [entries count];
  while (idx-- > 0) {
    [result addObject:entries[idx]];
  }
  return result;
}

- (void)awakeFromNib {
  /* Load triggers */
  [[se_library triggerSet] enumerateObjectsUsingBlock:^(SparkTrigger *trigger, BOOL *stop) {
    NSDictionary *entry = @{
                            @"trigger": trigger,
                            @"entries": [self entries:trigger]};
    [self->ibTriggers addObject:entry];
  }];
}

- (void)libraryDidChange:(NSNotification *)aNotification {
  [self setLibrary:[[aNotification object] library]];
}

@end

@implementation SEBooleanToImageTransformer 

+ (Class)transformedValueClass {
  return [NSImage class];
}

+ (BOOL)allowsReverseTransformation {
  return YES;
}

- (id)transformedValue:(id)value {
  NSImage *img = nil;
  
  if (!value) return nil;
  
  /* Attempt to get a reasonable value from the value object. */
  if ([value respondsToSelector: @selector(boolValue)]) {
    if ([value boolValue]) {
      img = [NSImage imageNamed:@"SECheck"];
    }
  } else {
    SPXThrowException(NSInternalInconsistencyException,
                     @"Value (%@) does not respond to -boolValue.", [value class]);
  }
  
  return img;
}

- (id)reverseTransformedValue:(id)value {
  if (value)
    return @YES;
  
  return @NO;
}

@end

@implementation SparkHotKey (SEModifierAccess)

static NSString *sCommand = nil, *sOption = nil, *sControl = nil, *sShift = nil;

static inline void _init(void) {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    UniChar ch = 0x21E7;
    sShift = SPXCFStringBridgingRelease(CFStringCreateWithCharacters(kCFAllocatorDefault, &ch, 1));
    ch = 0x2325;
    sOption = SPXCFStringBridgingRelease(CFStringCreateWithCharacters(kCFAllocatorDefault, &ch, 1));
    ch = 0x2303;
    sControl = SPXCFStringBridgingRelease(CFStringCreateWithCharacters(kCFAllocatorDefault, &ch, 1));
    ch = 0x2318;
    sCommand = SPXCFStringBridgingRelease(CFStringCreateWithCharacters(kCFAllocatorDefault, &ch, 1));
  });
}

- (NSString *)characters {
  return [HKKeyMap stringRepresentationForCharacter:[self character] modifiers:0];
}

- (NSString *)control {
  _init();
  return ([self nativeModifier] & kCGEventFlagMaskControl) != 0 ? sControl : nil;
}
- (NSString *)option {
  _init();
  return ([self nativeModifier] & kCGEventFlagMaskAlternate) != 0 ? sOption : nil;
}
- (NSString *)shift {
  _init();
  return ([self nativeModifier] & kCGEventFlagMaskShift) != 0 ? sShift : nil;
}
- (NSString *)command {
  _init();
  return ([self nativeModifier] & kCGEventFlagMaskCommand) != 0 ? sCommand : nil;
}

@end

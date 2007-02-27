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

#import <ShadowKit/SKTableView.h>
#import <ShadowKit/SKTableDataSource.h>

#import <HotKeyToolKit/HKKeyMap.h>

@interface SEBooleanToImageTransformer : NSValueTransformer {
}
@end

@implementation SETriggerBrowser

+ (void)initialize {
  if ([SETriggerBrowser class] == self) {
    SEBooleanToImageTransformer *transformer;
    
    // create an autoreleased instance of our value transformer
    transformer = [[SEBooleanToImageTransformer alloc] init];
    
    // register it with the name that we refer to it with
    [NSValueTransformer setValueTransformer:transformer
                                    forName:@"SEBooleanToImageTransformer"];
    [transformer release];
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
  [super dealloc];
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
    if (se_library) {
      [se_library release];
    }
    se_library = [aLibrary retain];
    if (se_library) {
    }
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

- (void)awakeFromNib {
  /* Load triggers */
  NSArray *triggers = [[se_library triggerSet] objects];
  [ibTriggers addObjects:triggers];
}

- (void)libraryDidChange:(NSNotification *)aNotification {
  [self setLibrary:[[aNotification object] library]];
}

@end

@implementation SEBooleanToImageTransformer 

+ (Class)transformedValueClass; {
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
    [NSException raise:NSInternalInconsistencyException
                format:@"Value (%@) does not respond to -boolValue.",
      [value class]];
  }
  
  return img;
}

- (id)reverseTransformedValue:(id)value {
  if (value)
    return SKBool(YES);
  
  return SKBool(NO);
}

@end

@implementation SparkHotKey (SEModifierAccess)

- (NSString *)characters {
  return HKMapGetStringRepresentationForCharacterAndModifier([self character], 0);
}

- (BOOL)control {
  return ([self nativeModifier] & kCGEventFlagMaskControl) != 0;
}
- (BOOL)option {
  return ([self nativeModifier] & kCGEventFlagMaskAlternate) != 0;
}
- (BOOL)shift {
  return ([self nativeModifier] & kCGEventFlagMaskShift) != 0;
}
- (BOOL)command {
  return ([self nativeModifier] & kCGEventFlagMaskCommand) != 0;
}

@end

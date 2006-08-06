/*
 *  SEActionEditor.m
 *  Spark Editor
 *
 *  Created by Grayfox on 09/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "SEActionEditor.h"

#import "SEHotKeyTrap.h"
#import "SETriggerEntry.h"

#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkActionLoader.h>

#import <ShadowKit/SKImageAndTextCell.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

@interface SEImageAndTextLabel : NSTextField {
}
- (NSImage *)image;
- (void)setImage:(NSImage *)anImage;

@end

@implementation SEImageAndTextLabel

+ (void)initialize {
  if ([self class] == [SEImageAndTextLabel class]) {
    [self setCellClass:[SKImageAndTextCell class]];
  }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  NSTextFieldCell *old = [self cell];
  SKImageAndTextCell *cell = [[SKImageAndTextCell alloc] init];
  
  [cell setTag:[old tag]];
  [cell setFont:[old font]];
  [cell setTarget:[old target]];
  [cell setAction:[old action]];
  
  [cell setTitle:[old title]];
  [cell setPlaceholderString:[old placeholderString]];
  
  [cell setTextColor:[old textColor]];
  [cell setBackgroundColor:[old backgroundColor]];
  [cell setDrawsBackground:[old drawsBackground]];
  
  [cell setBezeled:[old isBezeled]];
  [cell setBordered:[old isBordered]];
  [cell setBezelStyle:[old bezelStyle]];

  [cell setBaseWritingDirection:[old baseWritingDirection]];
  [cell setLineBreakMode:[old lineBreakMode]];
  [cell setControlSize:[old controlSize]];
  [cell setScrollable:[old isScrollable]];
  [cell setAlignment:[old alignment]];
  [cell setWraps:[old wraps]];
  
  [cell setSendsActionOnEndEditing:[old sendsActionOnEndEditing]];
  
  [cell setEnabled:[old isEnabled]];
  [cell setEditable:[old isEditable]];
  [cell setSelectable:[old isSelectable]];

  [self setCell:cell];
  return self;
}

- (NSImage *)image {
  return [[self cell] image];
}

- (void)setImage:(NSImage *)anImage {
  [[self cell] setImage:anImage];
}

@end

@implementation SEActionEditor

- (id)init {
  if (self = [super initWithViewNibName:@"SEActionEditor"]) {
    
  }
  return self;
}

- (void)dealloc {
  [super dealloc];
}

- (void)awakeFromNib {
  /* NSSmallSquareBezelStyle */
  /* NSShadowlessSquareBezelStyle */
  [typeField setBezelStyle:NSShadowlessSquareBezelStyle];
  //  NSArray *plugins = [[[SparkActionLoader sharedLoader] plugins] sortedArrayUsingDescriptors:gSortByNameDescriptors];
//  SparkPlugIn *plugin;
//  NSEnumerator *items = [plugins objectEnumerator];
//  while (plugin = [items nextObject]) {
//    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[plugin name]
//                                                  action:nil
//                                           keyEquivalent:@""];
//    [item setImage:[plugin icon]];
//    [item setRepresentedObject:plugin];
//    [[typeMenu menu] addItem:item];
//    [item release];
//  }
}

- (void)setActionType:(SparkPlugIn *)type {
  [typeField setTitle:[type name]];
  [typeField setImage:[type icon]];
  [typeField sizeToFit];
}
- (void)setSparkAction:(SparkAction *)anAction {
  
}
- (void)setApplication:(SparkApplication *)anApplication {
  [appField setApplication:anApplication];
  [appField setTitle:[NSString stringWithFormat:@"%@ HotKey", [anApplication name]]];
}

#pragma mark Trap Delegate
- (BOOL)trapWindow:(HKTrapWindow *)window needPerformKeyEquivalent:(NSEvent *)theEvent {
  /* No modifier and cancel pressed */
  return ([theEvent modifierFlags] & SEValidModifiersFlags) == 0
  && [[theEvent characters] isEqualToString:@"\e"];
}

- (BOOL)trapWindow:(HKTrapWindow *)window needProceedKeyEvent:(NSEvent *)theEvent {
  if (kSparkEnableAllSingleKey == SparkKeyStrokeFilterMode) {
    return NO;
  } else {
    UInt16 code = [theEvent keyCode];
    UInt32 mask = [theEvent modifierFlags] & SEValidModifiersFlags;
    return mask ? NO : (code == kVirtualEnterKey)
      || (code == kVirtualReturnKey)
      || (code == kVirtualEscapeKey)
      || (code == kVirtualTabKey);
  }
}

@end

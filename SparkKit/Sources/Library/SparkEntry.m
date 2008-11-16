/*
 *  SparkEntry.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkLibrary.h>

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkActionLoader.h>

#import WBHEADER(WBAppKitExtensions.h)

#import "SparkEntryPrivate.h"
#import "SparkLibraryPrivate.h"
#import "SparkEntryManagerPrivate.h"

static
NSImage *SparkEntryDefaultIcon(void) {
  static NSImage *__simage = nil;
  if (!__simage) 
    __simage = [[NSImage imageNamed:@"SparkEntry" inBundle:[NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier]] retain];
  return __simage;
}

NSString * const SparkEntryDidAppendChildNotification = @"SparkEntryDidAppendChild";
NSString * const SparkEntryWillRemoveChildNotification = @"SparkEntryWillRemoveChild";

@implementation SparkEntry

- (id)copyWithZone:(NSZone *)aZone {
  SparkEntry *copy = (SparkEntry *)NSCopyObject(self, 0, aZone);
  [copy->sp_action retain];
  [copy->sp_trigger retain];
  [copy->sp_application retain];
	/* a copy should not remain in the tree */
	copy->sp_child = nil;
	copy->sp_parent = nil;
	/* and is not managed */
	copy->sp_manager = nil;
	copy->sp_seFlags.editing = 0;
  return copy;
}

+ (id)entryWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
  return [[[self alloc] initWithAction:anAction trigger:aTrigger application:anApplication] autorelease];
}

- (id)initWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
  if (self = [super init]) {
    [self setAction:anAction];
    [self setTrigger:aTrigger];
    [self setApplication:anApplication];
  }
  return self;
}

- (void)dealloc {
  [sp_child release];
  [sp_action release];
  [sp_trigger release];
  [sp_application release];
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { Trigger: %@, Action: %@, Application: %@}", 
					[self class], self,
					sp_trigger, sp_action, [sp_application name]];
}

- (NSUInteger)hash {
  return sp_uid;
}

- (BOOL)isEqual:(id)object {
  if ([object class] != [self class]) return NO;
  SparkEntry *entry = (SparkEntry *)object;
  return sp_uid == entry->sp_uid;
}

#pragma mark -
- (UInt32)uid {
  return sp_uid;
}

#pragma mark Spark Objects
- (SparkAction *)action {
  return sp_action;
}

- (SparkTrigger *)trigger {
  return sp_trigger;
}

- (SparkApplication *)application {
  return sp_application;
}

#pragma mark Type
- (SparkEntryType)type {
  if ([self applicationUID] == kSparkApplicationSystemUID) {
    return kSparkEntryTypeDefault;
  } else if (sp_parent) {
    if ([sp_action isEqual:[sp_parent action]])
      return kSparkEntryTypeWeakOverWrite;
    else
      return kSparkEntryTypeOverWrite;
  } else {
    /* no parent and not system application */
    return kSparkEntryTypeSpecific;
  }
}

#pragma mark Status
- (BOOL)isRoot {
	return [self isSystem] || ![self parent];
}
- (SparkEntry *)root {
	return sp_parent ? : self;
}

- (BOOL)isSystem {
  return [sp_application uid] == kSparkApplicationSystemUID;
}

- (BOOL)isActive {
  return [self isEnabled] && [self isPlugged];
}

- (BOOL)isEnabled {
  return sp_seFlags.enabled;
}
- (void)setEnabled:(BOOL)flag {
	if (flag && sp_manager) {
		NSAssert([sp_manager activeEntryForTrigger:[self trigger] application:[self application]] == nil, @"entry conflict");
	}
  bool enabled = WBFlagTestAndSet(sp_seFlags.enabled, flag);
  if (enabled != sp_seFlags.enabled && sp_manager) {
		SparkLibrary *library = [sp_manager library];
		/* Undo management */
		[[[library undoManager] prepareWithInvocationTarget:self] setEnabled:!flag];
		/* notification */
		SparkLibraryPostNotification(library, SparkEntryManagerDidChangeEntryStatusNotification, sp_manager, self);
  }
}

- (BOOL)isPlugged {
  return !sp_seFlags.unplugged;
}

- (BOOL)isPersistent {
  return [sp_action isPersistent];
}

#pragma mark Properties
- (NSImage *)icon {
  return [sp_action icon] ? : SparkEntryDefaultIcon();
}
- (void)setIcon:(NSImage *)anIcon {
  [sp_action setIcon:anIcon];
}

- (NSString *)name {
  return [sp_action name];
}
- (void)setName:(NSString *)aName {
  [sp_action setName:aName];
}

- (NSString *)categorie {
  return [sp_action categorie];
}
- (NSString *)actionDescription {
  return [sp_action actionDescription];
}
- (NSString *)triggerDescription {
  return [sp_trigger triggerDescription];
}

- (id)representation {
  return self;
}
- (void)setRepresentation:(NSString *)name {
  if (name && [name length]) {
		/* register the undo here (instead of into action) to trigger observer notification when undoing */
		[[[sp_action library] undoManager] registerUndoWithTarget:self
																										 selector:@selector(setRepresentation:)
																											 object:[sp_action name]];
		[sp_action setName:name];
  } else {
    NSBeep();
  }
}

- (BOOL)hasVariant {
	NSParameterAssert([self isSystem]);
	return sp_child != nil;
}
- (NSArray *)variants {
	if (sp_parent) 
		return [sp_parent variants];
	
	/* root entry without child => return one item array */
	if (!sp_child)
		return [NSArray arrayWithObject:self];
	
	SparkEntry *item = self;
	NSMutableArray *variants = [NSMutableArray array];
	do {
		[variants addObject:item];
	} while (item = item->sp_child);
	
	return variants;
}

- (SparkEntry *)variantWithApplication:(SparkApplication *)anApplication {
	SparkUID uid = [anApplication uid];
	if ([self isSystem]) {
		SparkEntry *variant = self;
		do {
			if ([variant applicationUID] == uid)
				return variant;			
		} while (variant = variant->sp_child);
	} else if ([self isRoot]) {
		/* orphan specific entry */
		if ([self applicationUID] == uid)
			return self;
	} else {
		return [sp_parent variantWithApplication:anApplication];
	}
	return NULL;
}

#pragma mark Private
- (void)setUID:(UInt32)anUID {
  sp_uid = anUID;
}

- (SparkEntryManager *)manager {
  return sp_manager;
}
- (void)setManager:(SparkEntryManager *)aManager {
  sp_manager = aManager;
}

/* cached status */
- (void)setPlugged:(BOOL)flag {
  WBFlagSet(sp_seFlags.unplugged, !flag);
}

/* convenient access */
- (SparkUID)actionUID {
  return [sp_action uid];
}
- (SparkUID)triggerUID {
  return [sp_trigger uid];
}
- (SparkUID)applicationUID {
  return [sp_application uid];
}

/* update object */
- (SparkEntry *)parent {
	return sp_parent;
}
- (void)setParent:(SparkEntry *)aParent {
	NSParameterAssert(aParent != self);
	NSParameterAssert(![self isSystem]);
	NSParameterAssert(!aParent || [aParent isSystem]);
	sp_parent = aParent;
}

- (void)setAction:(SparkAction *)action {
  WBSetterRetain(sp_action, action);
  SparkPlugIn *plugin = action ? [[SparkActionLoader sharedLoader] plugInForAction:action] : nil;
  if (plugin) [self setPlugged:[plugin isEnabled]];
}
- (void)setTrigger:(SparkTrigger *)trigger {
  WBSetterRetain(sp_trigger, trigger);
}
- (void)setApplication:(SparkApplication *)anApplication {
  WBSetterRetain(sp_application, anApplication);
}

- (SparkEntry *)firstChild {
  NSParameterAssert([self isSystem]);
  return sp_child;
}
- (SparkEntry *)sibling {
  NSParameterAssert(![self isSystem]);
  return sp_child;
}


#pragma mark Internals
- (NSArray *)children {
	NSParameterAssert([self isSystem]);
	
	if (!sp_child) return nil;
	NSMutableArray *children = [NSMutableArray array];
	SparkEntry *child = sp_child;
	do {
		[children addObject:child];
	} while (child = [child sibling]);
	
	return children;
}

- (void)addChild:(SparkEntry *)anEntry {
  NSParameterAssert([self isSystem]);
	NSParameterAssert(![anEntry isSystem]);
	
  anEntry->sp_child = sp_child;
  sp_child = [anEntry retain];
	[anEntry setParent:self];
	/* notification */
	SparkLibraryPostNotification([sp_manager library], SparkEntryDidAppendChildNotification, self, anEntry);
}
- (void)addChildrenFromArray:(NSArray *)children {
	NSUInteger count = [children count];
	for (NSUInteger idx = 0; idx < count; idx++) {
		[self addChild:[children objectAtIndex:idx]];
	}
}

- (void)removeChild:(SparkEntry *)aChild {
  NSParameterAssert([self isSystem]);
  NSParameterAssert([aChild parent] == self);
	
	/* undo + notification */
	//[[sp_manager undoManager] registerUndoWithTarget:self selector:@selector(addChild:) object:aChild];
  SparkLibraryPostNotification([sp_manager library], SparkEntryWillRemoveChildNotification, self, aChild);
	
  SparkEntry *item = self;
	do {
		if (item->sp_child == aChild) {
			item->sp_child = aChild->sp_child;
			[aChild setParent:nil];
			[aChild release];
			break;
		}
	} while (item = item->sp_child);
}
- (void)removeAllChildren {
	NSParameterAssert([self isSystem]);
	while (sp_child)
		[self removeChild:sp_child];
}

@end
#pragma mark -
@implementation SparkEntry (SparkMutableEntry)

/* start to record change for the entry manager */
- (void)beginEditing {
	NSParameterAssert(!sp_seFlags.editing);
	sp_seFlags.editing = 1;
	[sp_manager beginEditing:self];
}
/* commit change to the entry manager */
- (void)endEditing {
	NSParameterAssert(sp_seFlags.editing);
	[sp_manager endEditing:self];
	sp_seFlags.editing = 0;
}

- (void)replaceAction:(SparkAction *)action {
	if (!sp_manager) {
		[self setAction:action];
	} else {
		NSParameterAssert(sp_seFlags.editing);
		[sp_manager replaceAction:action inEntry:self];
	}
}

- (void)replaceTrigger:(SparkTrigger *)trigger {
	if (!sp_manager) {
		[self setTrigger:trigger];
	} else {
		NSParameterAssert(sp_seFlags.editing);
		[sp_manager replaceTrigger:trigger inEntry:self];		
	}
}

- (void)replaceApplication:(SparkApplication *)anApplication {
	if (!sp_manager) {
		[self setApplication:anApplication];
	} else {
		NSParameterAssert(sp_seFlags.editing);
		[sp_manager replaceApplication:anApplication inEntry:self];
	}
}

- (SparkEntry *)createWeakVariantWithApplication:(SparkApplication *)anApplication {
	return [self createVariantWithAction:[self action] trigger:[self trigger] application:anApplication];
}

- (SparkEntry *)createVariantWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
	NSParameterAssert(sp_manager);
	NSParameterAssert([self isSystem]);
	NSParameterAssert(![self variantWithApplication:anApplication]);
	SparkEntry *entry = [[SparkEntry alloc] initWithAction:anAction trigger:aTrigger application:anApplication];
	[[self manager] addEntry:entry parent:self];
	return [entry autorelease];
}

@end

@implementation SparkEntry (SparkNetworkMessage)

- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder {
  if ([encoder isByref]) {
    WBLogWarning(@"SparkEntry does not support by ref messaging");
    return nil;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super init]) {
    SparkLibrary *library = nil;
    if ([coder isKindOfClass:[NSPortCoder class]] ) {
			/* Network entry has to usage */
			/* 
			 1. adding a new entry. in this case child, parent and manager are nil.
			 2. updating an entry. In this case, we ignore child, parent and manager
			 and we use only action, trigger and application.
			 */
			library = SparkActiveLibrary();
			unsigned int value;
			[coder decodeValueOfObjCType:@encode(unsigned int) at:&value];
			sp_uid = value;
			/* content */
			[coder decodeValueOfObjCType:@encode(unsigned int) at:&value];
			[self setAction:[library actionWithUID:value]];
			
			[coder decodeValueOfObjCType:@encode(unsigned int) at:&value];
			[self setTrigger:[library triggerWithUID:value]];
			
			[coder decodeValueOfObjCType:@encode(unsigned int) at:&value];
			[self setApplication:[library applicationWithUID:value]];
			
			/* flags */
			[coder decodeValueOfObjCType:@encode(unsigned int) at:&value];
			[self setEnabled:value];
    } else if ([coder isKindOfClass:[SparkLibraryUnarchiver class]]) {
      library = [(SparkLibraryUnarchiver *)coder library];
			
			/* decode entry */
			sp_uid = [coder decodeInt32ForKey:@"uid"];
			
      sp_parent = [coder decodeObjectForKey:@"parent"];
      sp_child = [[coder decodeObjectForKey:@"child"] retain];
			
			SparkUID uid;
			uid = [coder decodeInt32ForKey:@"action"];
			[self setAction:[library actionWithUID:uid]];
			
			uid = [coder decodeInt32ForKey:@"trigger"];
			[self setTrigger:[library triggerWithUID:uid]];
			
			uid = [coder decodeInt32ForKey:@"application"];
			[self setApplication:[library applicationWithUID:uid]];
			
			[self setEnabled:[coder decodeBoolForKey:@"enabled"]];
    } 
    if (!library) {
      [self release];
      WBThrowException(NSInvalidArchiveOperationException, @"Unsupported coder: %@", coder);
    }

  }
  return self;
}

- (void)sp_encodeWithCoder:(NSCoder *)coder {

}

- (void)encodeWithCoder:(NSCoder *)coder {
  if ([coder isKindOfClass:[NSPortCoder class]]) {
		/* see initWithCoder comments */
		unsigned int value = sp_uid;
		[coder encodeValueOfObjCType:@encode(unsigned int) at:&value];
		
		/* content */
		value = [sp_action uid];
		[coder encodeValueOfObjCType:@encode(unsigned int) at:&value];
		value = [sp_trigger uid];
		[coder encodeValueOfObjCType:@encode(unsigned int) at:&value];
		value = [sp_application uid];
		[coder encodeValueOfObjCType:@encode(unsigned int) at:&value];
		
		/* flags */
		value = [self isEnabled];
		[coder encodeValueOfObjCType:@encode(unsigned int) at:&value];
  } else if ([coder isKindOfClass:[SparkLibraryArchiver class]]) {
    [coder encodeObject:sp_child forKey:@"child"];
    [coder encodeConditionalObject:sp_parent forKey:@"parent"];
		
		[coder encodeInt32:sp_uid forKey:@"uid"];
		[coder encodeInt32:[sp_action uid] forKey:@"action"];
		[coder encodeInt32:[sp_trigger uid] forKey:@"trigger"];
		[coder encodeInt32:[sp_application uid] forKey:@"application"];
		/* flags */
		[coder encodeBool:[self isEnabled] forKey:@"enabled"];
  } else {
    WBThrowException(NSInvalidArchiveOperationException, @"Unsupported coder: %@", coder);
  }
}

@end

@implementation SparkEntry (SparkRegistration)

- (BOOL)isRegistred {
  return sp_seFlags.registred;
}

- (void)setRegistred:(BOOL)flag {
  bool registred = WBFlagTestAndSet(sp_seFlags.registred, flag);
  /* If previous ≠ new status */
  if (registred != sp_seFlags.registred) {
    if (sp_seFlags.registred) {
      // register entry
      if (![sp_trigger isRegistred])
        [sp_trigger setRegistred:YES];
    } else {
      // unregister entry
      if (![sp_manager containsRegistredEntryForTrigger:sp_trigger])
        [sp_trigger setRegistred:NO];
    }
  }
}

@end


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
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkActionLoader.h>

#import <WonderBox/WonderBox.h>

#import "SparkEntryPrivate.h"
#import "SparkLibraryPrivate.h"
#import "SparkEntryManagerPrivate.h"

static
NSImage *SparkEntryDefaultIcon(void) {
  static NSImage *__simage = nil;
  if (!__simage) 
    __simage = [NSImage imageNamed:@"SparkEntry" inBundle:[NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier]];
  return __simage;
}

NSString * const SparkEntryDidAppendChildNotification = @"SparkEntryDidAppendChild";
NSString * const SparkEntryWillRemoveChildNotification = @"SparkEntryWillRemoveChild";

@implementation SparkEntry {
@private
  /* chained list of children */
  SparkEntry *sp_child;

  /* status */
  struct _sp_seFlags {
    unsigned int enabled:1;
    unsigned int editing:1;
    unsigned int registred:1;
    unsigned int unplugged:1;
    unsigned int reserved:28;
  } _seFlags;
}

- (instancetype)copyWithZone:(NSZone *)aZone {
  SparkEntry *copy = [[[self class] allocWithZone:aZone] initWithAction:_action trigger:_trigger application:_application];
	/* a copy should not remain in the tree */
	copy->sp_child = nil;
	copy->_parent = nil;
	/* and is not managed */
	copy->_manager = nil;

  copy->_seFlags = _seFlags;
	copy->_seFlags.editing = 0;
  return copy;
}

+ (instancetype)entryWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
  return [[self alloc] initWithAction:anAction trigger:aTrigger application:anApplication];
}

- (instancetype)initWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
  if (self = [super init]) {
    [self setAction:anAction];
    [self setTrigger:aTrigger];
    [self setApplication:anApplication];
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { Trigger: %@, Action: %@, Application: %@}", 
					[self class], self,
					_trigger, _action, _application.name];
}

- (NSUInteger)hash {
  return _uid;
}

- (BOOL)isEqual:(id)object {
  if ([object class] != [self class])
    return NO;
  SparkEntry *entry = (SparkEntry *)object;
  return _uid == entry->_uid;
}

#pragma mark -
#pragma mark Type
- (SparkEntryType)type {
  SparkEntry *parent = _parent;
  if ([self applicationUID] == kSparkApplicationSystemUID) {
    return kSparkEntryTypeDefault;
  } else if (parent) {
    if ([_action isEqual:parent.action])
      return kSparkEntryTypeWeakOverWrite;
    else
      return kSparkEntryTypeOverWrite;
  } else {
    /* no parent and not system application */
    return kSparkEntryTypeSpecific;
  }
}

// MARK: -
// MARK: Status
- (BOOL)isRoot {
	return [self isSystem] || ![self parent];
}
- (SparkEntry *)root {
	return _parent ? : self;
}

- (BOOL)isSystem {
  return [_application uid] == kSparkApplicationSystemUID;
}

- (BOOL)isActive {
  return self.enabled && self.plugged;
}

- (BOOL)isEnabled {
  return _seFlags.enabled;
}
- (void)setEnabled:(BOOL)flag {
	if (flag && _manager) {
		NSAssert([_manager activeEntryForTrigger:self.trigger application:self.application] == nil, @"entry conflict");
	}
  bool enabled = SPXFlagTestAndSet(_seFlags.enabled, flag);
  if (enabled != _seFlags.enabled && _manager) {
		SparkLibrary *library = [_manager library];
		/* Undo management */
		[[library.undoManager prepareWithInvocationTarget:self] setEnabled:!flag];
		/* notification */
		SparkLibraryPostNotification(library, SparkEntryManagerDidChangeEntryStatusNotification, _manager, self);
  }
}

- (BOOL)isPlugged {
  return !_seFlags.unplugged;
}

- (BOOL)isPersistent {
  return [_action isPersistent];
}

// MARK: -
// MARK: Properties
- (NSImage *)icon {
  return _action.icon ? : SparkEntryDefaultIcon();
}
- (void)setIcon:(NSImage *)anIcon {
  _action.icon = anIcon;
}

- (NSString *)name {
  return _action.name;
}
- (void)setName:(NSString *)aName {
  _action.name = aName;
}

- (NSString *)category {
  return _action.category;
}
- (NSString *)actionDescription {
  return _action.actionDescription;
}
- (NSString *)triggerDescription {
  return _trigger.triggerDescription;
}

- (id)representation {
  return self;
}
- (void)setRepresentation:(NSString *)name {
  if (name && [name length]) {
		/* register the undo here (instead of into action) to trigger observer notification when undoing */
		[_action.library.undoManager registerUndoWithTarget:self
                                               selector:@selector(setRepresentation:)
                                                 object:_action.name];
    _action.name = name;
  } else {
    NSBeep();
  }
}

- (BOOL)hasVariant {
	NSParameterAssert([self isSystem]);
	return sp_child != nil;
}

- (NSArray *)variants {
  SparkEntry *parent = _parent;
	if (parent)
		return [parent variants];
	
	/* root entry without child => return one item array */
	if (!sp_child)
		return @[self];
	
	SparkEntry *item = self;
	NSMutableArray *variants = [NSMutableArray array];
	do {
		[variants addObject:item];
	} while ((item = item->sp_child));
	
	return variants;
}

- (SparkEntry *)variantWithApplication:(SparkApplication *)anApplication {
	SparkUID uid = [anApplication uid];
	if ([self isSystem]) {
		SparkEntry *variant = self;
		do {
			if ([variant applicationUID] == uid)
				return variant;			
		} while ((variant = variant->sp_child));
	} else if ([self isRoot]) {
		/* orphan specific entry */
		if ([self applicationUID] == uid)
			return self;
	} else {
		return [self.parent variantWithApplication:anApplication];
	}
	return NULL;
}

// MARK: -
// MARK: Private
/* cached status */
- (void)setPlugged:(BOOL)flag {
  SPXFlagSet(_seFlags.unplugged, !flag);
}

/* convenient access */
- (SparkUID)actionUID {
  return _action.uid;
}
- (SparkUID)triggerUID {
  return _trigger.uid;
}
- (SparkUID)applicationUID {
  return _application.uid;
}

/* update object */
- (void)setParent:(SparkEntry *)aParent {
	NSParameterAssert(aParent != self);
	NSParameterAssert(![self isSystem]);
	NSParameterAssert(!aParent || [aParent isSystem]);
	_parent = aParent;
}

- (void)setAction:(SparkAction *)action {
  SPXSetterRetainAndDo(_action, action, {
    SparkPlugIn *plugin = action ? [[SparkActionLoader sharedLoader] plugInForAction:action] : nil;
    if (plugin) [self setPlugged:[plugin isEnabled]];
  });
}

- (SparkEntry *)firstChild {
  NSParameterAssert([self isSystem]);
  return sp_child;
}

- (SparkEntry *)sibling {
  NSParameterAssert(![self isSystem]);
  return sp_child;
}

// MARK: -
// MARK: Internals
- (NSArray *)children {
	NSParameterAssert([self isSystem]);
	
	if (!sp_child)
    return nil;
	NSMutableArray *children = [NSMutableArray array];
	SparkEntry *child = sp_child;
	do {
		[children addObject:child];
	} while ((child = [child sibling]));
	
	return children;
}

- (void)addChild:(SparkEntry *)anEntry {
  NSParameterAssert([self isSystem]);
	NSParameterAssert(![anEntry isSystem]);
	
  anEntry->sp_child = sp_child;
  sp_child = anEntry;
	[anEntry setParent:self];
	/* notification */
	SparkLibraryPostNotification(_manager.library, SparkEntryDidAppendChildNotification, self, anEntry);
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
	//[[_manager undoManager] registerUndoWithTarget:self selector:@selector(addChild:) object:aChild];
  SparkLibraryPostNotification(_manager.library, SparkEntryWillRemoveChildNotification, self, aChild);
	
  SparkEntry *item = self;
	do {
		if (item->sp_child == aChild) {
			item->sp_child = aChild->sp_child;
			[aChild setParent:nil];
			break;
		}
	} while ((item = item->sp_child));
}

- (void)removeAllChildren {
	NSParameterAssert([self isSystem]);
	while (sp_child)
		[self removeChild:sp_child];
}

// MARK: -
// MARK: NSSecureCoding
+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)replacementObjectForPortCoder:(NSPortCoder *)encoder {
  if ([encoder isByref]) {
    spx_log("SparkEntry does not support by ref messaging");
    return nil;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  if (self = [super init]) {
    SparkLibrary *library = nil;
    if (coder.requiresSecureCoding) {
      /* Network entry has to usage */
      /*
       1. adding a new entry. in this case child, parent and manager are nil.
       2. updating an entry. In this case, we ignore child, parent and manager
       and we use only action, trigger and application.
       */
      library = SparkActiveLibrary();
      _uid = [coder decodeInt32ForKey:@"uid"];
      /* content */
      SparkUID uid = [coder decodeInt32ForKey:@"action"];
      [self setAction:[library actionWithUID:uid]];

      uid = [coder decodeInt32ForKey:@"trigger"];
      [self setTrigger:[library triggerWithUID:uid]];

      uid = [coder decodeInt32ForKey:@"application"];
      [self setApplication:[library applicationWithUID:uid]];

      /* flags */
      self.enabled = [coder decodeBoolForKey:@"enabled"];
    } else if ([coder isKindOfClass:[NSPortCoder class]] ) {
      /* Network entry has to usage */
      /*
       1. adding a new entry. in this case child, parent and manager are nil.
       2. updating an entry. In this case, we ignore child, parent and manager
       and we use only action, trigger and application.
       */
      library = SparkActiveLibrary();
      unsigned int value;
      [coder decodeValueOfObjCType:@encode(unsigned int) at:&value];
      _uid = value;
      /* content */
      [coder decodeValueOfObjCType:@encode(unsigned int) at:&value];
      [self setAction:[library actionWithUID:value]];

      [coder decodeValueOfObjCType:@encode(unsigned int) at:&value];
      [self setTrigger:[library triggerWithUID:value]];

      [coder decodeValueOfObjCType:@encode(unsigned int) at:&value];
      [self setApplication:[library applicationWithUID:value]];

      /* flags */
      [coder decodeValueOfObjCType:@encode(unsigned int) at:&value];
      self.enabled = value != 0;
    } else if ([coder isKindOfClass:[SparkLibraryUnarchiver class]]) {
      library = [(SparkLibraryUnarchiver *)coder library];

      /* decode entry */
      _uid = [coder decodeInt32ForKey:@"uid"];

      _parent = [coder decodeObjectForKey:@"parent"];
      sp_child = [coder decodeObjectForKey:@"child"];

      SparkUID uid;
      uid = [coder decodeInt32ForKey:@"action"];
      self.action = [library actionWithUID:uid];

      uid = [coder decodeInt32ForKey:@"trigger"];
      self.trigger = [library triggerWithUID:uid];

      uid = [coder decodeInt32ForKey:@"application"];
      self.application = [library applicationWithUID:uid];

      self.enabled = [coder decodeBoolForKey:@"enabled"];
    }
    if (!library) {
      SPXThrowException(NSInvalidArchiveOperationException, @"Unsupported coder: %@", coder);
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  if (coder.requiresSecureCoding) {
    /* see initWithCoder comments */
    [coder encodeInt32:_uid forKey:@"uid"];

    /* content */
    [coder encodeInt32:_action.uid forKey:@"action"];
    [coder encodeInt32:_trigger.uid forKey:@"trigger"];
    [coder encodeInt32:_application.uid forKey:@"application"];

    /* flags */
    [coder encodeBool:self.enabled forKey:@"enabled"];
  } else if ([coder isKindOfClass:[NSPortCoder class]]) {
    /* see initWithCoder comments */
    unsigned int value = _uid;
    [coder encodeValueOfObjCType:@encode(unsigned int) at:&value];

    /* content */
    value = _action.uid;
    [coder encodeValueOfObjCType:@encode(unsigned int) at:&value];
    value = _trigger.uid;
    [coder encodeValueOfObjCType:@encode(unsigned int) at:&value];
    value = _application.uid;
    [coder encodeValueOfObjCType:@encode(unsigned int) at:&value];

    /* flags */
    value = [self isEnabled];
    [coder encodeValueOfObjCType:@encode(unsigned int) at:&value];
  } else if ([coder isKindOfClass:[SparkLibraryArchiver class]]) {
    [coder encodeObject:sp_child forKey:@"child"];
    [coder encodeConditionalObject:_parent forKey:@"parent"];

    [coder encodeInt32:_uid forKey:@"uid"];
    [coder encodeInt32:_action.uid forKey:@"action"];
    [coder encodeInt32:_trigger.uid forKey:@"trigger"];
    [coder encodeInt32:_application.uid forKey:@"application"];
    /* flags */
    [coder encodeBool:self.enabled forKey:@"enabled"];
  } else {
    SPXThrowException(NSInvalidArchiveOperationException, @"Unsupported coder: %@", coder);
  }
}

@end
#pragma mark -
@implementation SparkEntry (SparkMutableEntry)

/* start to record change for the entry manager */
- (void)beginEditing {
	NSParameterAssert(!_seFlags.editing);
	_seFlags.editing = 1;
	[_manager beginEditing:self];
}
/* commit change to the entry manager */
- (void)endEditing {
	NSParameterAssert(_seFlags.editing);
	[_manager endEditing:self];
	_seFlags.editing = 0;
}

- (void)replaceAction:(SparkAction *)action {
	if (!_manager) {
		[self setAction:action];
	} else {
		NSParameterAssert(_seFlags.editing);
		[_manager replaceAction:action inEntry:self];
	}
}

- (void)replaceTrigger:(SparkTrigger *)trigger {
	if (!_manager) {
		[self setTrigger:trigger];
	} else {
		NSParameterAssert(_seFlags.editing);
		[_manager replaceTrigger:trigger inEntry:self];
	}
}

- (void)replaceApplication:(SparkApplication *)anApplication {
	if (!_manager) {
		[self setApplication:anApplication];
	} else {
		NSParameterAssert(_seFlags.editing);
		[_manager replaceApplication:anApplication inEntry:self];
	}
}

- (SparkEntry *)createWeakVariantWithApplication:(SparkApplication *)anApplication {
	return [self createVariantWithAction:self.action trigger:self.trigger application:anApplication];
}

- (SparkEntry *)createVariantWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
	NSParameterAssert(_manager);
	NSParameterAssert(self.isSystem);
	NSParameterAssert(![self variantWithApplication:anApplication]);
	SparkEntry *entry = [[SparkEntry alloc] initWithAction:anAction trigger:aTrigger application:anApplication];
	[self.manager addEntry:entry parent:self];
	return entry;
}

@end

// MARK: -
@implementation SparkEntry (SparkRegistration)

- (BOOL)isRegistred {
  return _seFlags.registred;
}

- (void)setRegistred:(BOOL)flag {
  bool registred = SPXFlagTestAndSet(_seFlags.registred, flag);
  /* If previous ≠ new status */
  if (registred != _seFlags.registred) {
    if (_seFlags.registred) {
      // register entry
      if (![_trigger isRegistred])
        [_trigger setRegistred:YES];
    } else {
      // unregister entry
      if (![_manager containsRegistredEntryForTrigger:_trigger])
        [_trigger setRegistred:NO];
    }
  }
}

@end


//
//  HotKey.m
//  Short-Cut
//
//  Created by Fox on Sat Nov 29 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#if defined (DEBUG)
#warning Debug defined in SparkKit!
#endif

volatile int SparkGDBWorkaround = 0;


#import <ShadowKit/SKImageUtils.h>
#import <ShadowKit/SKAppKitExtensions.h>
#import <HotKeyToolKit/HotKeyToolKit.h>

#import <SparkKit/SparkHotKey.h>

#import <SparkKit/Extension.h>
#import <SparkKit/SparkAlert.h>

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/Spark_Private.h>
#import <SparkKit/SparkObjectList.h>
#import <SparkKit/SparkKeyLibrary.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkListLibrary.h>
#import <SparkKit/SparkActionLibrary.h>
#import <SparkKit/SparkApplicationList.h>
#import <SparkKit/SparkApplicationLibrary.h>

#define ICON_SIZE		16

static NSString * const kHotKeyKeycodeKey = @"KeyCode";
static NSString * const kHotKeyCommentKey = @"Comment";
static NSString * const kHotKeyIsActiveKey = @"IsActive";
static NSString * const kHotKeyApplicationMap = @"ApplicationMap";

SparkFilterMode SparkKeyStrokeFilterMode = kSparkEnableSingleFunctionKey;

/*
 Fonction qui permet de définir la validité d'un raccouci. Depuis 10.3, les raccourcis sans "modifier" sont acceptés.
 Jugés trop génant, seul les touches Fx peuvent être utilisées sans "modifier"
*/
static const int kCommonModifierMask = NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask;

static BOOL KeyStrokeFilter(UInt16 code, UInt32 modifier) {
  if ((modifier & kCommonModifierMask) != 0) {
    return YES;
  }
  
  switch (SparkKeyStrokeFilterMode) {
    case kSparkDisableAllSingleKey:
      return NO;
    case kSparkEnableAllSingleKey:
      return YES;
    case kSparkEnableAllSingleButNavigation:
      switch (code) {
        case kVirtualTabKey:
        case kVirtualEnterKey:
        case kVirtualReturnKey:
        case kVirtualEscapeKey:
        case kVirtualLeftArrowKey:
        case kVirtualRightArrowKey:
        case kVirtualUpArrowKey:
        case kVirtualDownArrowKey:
          return NO;
      }
      return YES;
    case kSparkEnableSingleFunctionKey:
      switch (code) {
        case kVirtualF1Key:
        case kVirtualF2Key:
        case kVirtualF3Key:
        case kVirtualF4Key:
        case kVirtualF5Key:
        case kVirtualF6Key:
        case kVirtualF7Key:
        case kVirtualF8Key:
        case kVirtualF9Key:
        case kVirtualF10Key:
        case kVirtualF11Key:
        case kVirtualF12Key:
        case kVirtualF13Key:
        case kVirtualF14Key:
        case kVirtualF15Key:
        case kVirtualF16Key:
        case kVirtualHelpKey:
        case kVirtualClearLineKey:
          return YES;
      }
      break;
  }
  return NO;
}

#pragma mark -
@interface NSMutableDictionary (SetMultiplesValues)
- (void)setObject:(id)anObject forKeys:(NSArray *)keys;
@end

#pragma mark -
@implementation SparkHotKey

+ (void)initialize {
  if ([SparkHotKey class] == self) {
    [HKHotKeyManager setShortcutFilter:KeyStrokeFilter];
    [[SparkHotKeyManager class] poseAsClass:[HKHotKeyManager class]];
  }
}

- (void)registerAsNotificationObserver {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kSparkLibraryDidRemoveListNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kSparkLibraryDidRemoveActionNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kSparkLibraryDidRemoveApplicationNotification object:nil];
  if ([self library]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRemoveList:)
                                                 name:kSparkLibraryDidRemoveListNotification
                                               object:[self library]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRemoveAction:)
                                                 name:kSparkLibraryDidRemoveActionNotification
                                               object:[self library]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRemoveApplication:)
                                                 name:kSparkLibraryDidRemoveApplicationNotification
                                               object:[self library]];
  }
}

#pragma mark -
#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
  SparkHotKey* copy = [super copyWithZone:zone];
  copy->_target = _target;
  copy->_action = _action;
  copy->_active = _active;
  copy->_hotkey = [_hotkey retain];
  copy->_actions = [_actions copy];
  copy->_comment = [_comment copy];
  return copy;
}

unsigned SparkEncodeHotKey(HKHotKey *key) {
  return [key rawkey];
}

void SparkDecodeHotKey(HKHotKey *key, unsigned hotkey) {
  [key setRawkey:hotkey];
}

#pragma mark SparkSerialization
- (NSMutableDictionary *)propertyList {
  NSMutableDictionary *dico = [super propertyList];
  
  unsigned hotkey = SparkEncodeHotKey((HKHotKey *)self);
  [dico setObject:SKUInt(hotkey) forKey:kHotKeyKeycodeKey];
  
  [dico setObject:SKBool([self isActive]) forKey:kHotKeyIsActiveKey];
  if (nil != _comment)
    [dico setObject:_comment forKey:kHotKeyCommentKey];
  
  if ([_actions count]) {
    [dico setObject:SparkSerializeObject(_actions) forKey:kHotKeyApplicationMap];
  }
  return dico;
}

- (id)initFromPropertyList:(NSDictionary *)plist {
  if (self = [super initFromPropertyList:plist]) {
    _hotkey = [[HKHotKey alloc] init];
    [_hotkey setTarget:self];
    [_hotkey setAction:@selector(executeHotKey:)];
    
    [self setActive:[[plist objectForKey:kHotKeyIsActiveKey] boolValue]];
    
    unsigned int hotkey = [[plist objectForKey:kHotKeyKeycodeKey] unsignedIntValue];
    
    SparkDecodeHotKey((HKHotKey *)self, hotkey);

    _actions = [SparkDeserializeObject([plist objectForKey:kHotKeyApplicationMap]) retain];
    if (!_actions)
      _actions = [[SparkApplicationToActionMap alloc] init];
    [_actions setLibrary:[self library]];
    
    if ([SparkLibraryObject loadUI]) {
      [self setComment:[plist objectForKey:kHotKeyCommentKey]];
    }
  }
  return self;
}

#pragma mark -
#pragma mark Static Initializers
+ (id)hotKey {
  return [[[self alloc] init] autorelease];
}

+ (id)hotKeyWithName:(NSString *)name {
  return [[[self alloc] initWithName:name] autorelease]; 
}

+ (id)hotKeyFromPropertyList:(id)plist {
  return [[[self alloc] initFromPropertyList:plist] autorelease];
}

#pragma mark -
#pragma mark Init & Dealloc Methods
- (id)init {
  if (self = [super init]) {
    _hotkey = [[HKHotKey alloc] init];
    [_hotkey setTarget:self];
    [_hotkey setAction:@selector(executeHotKey:)];
    _active = NO;
    _actions = [[SparkApplicationToActionMap alloc] init];
  }
  return self; 
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_hotkey release];
  [_comment release];
  [_actions release];
  [super dealloc];
}

#pragma mark -
#pragma mark Public Methods
- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {name:%@ hotkey:%@ actions:%@}",
    [self className], self,
    [self name], _hotkey, _actions];
}

- (IBAction)executeHotKey:(id)sender {
  if ([_target respondsToSelector:_action]) {
    [_target performSelector:_action withObject:self];
  }
}

#pragma mark -
- (void)setLibrary:(SparkLibrary *)aLibrary {
  [super setLibrary:aLibrary];
  [_actions setLibrary:aLibrary];
  [self registerAsNotificationObserver];
}

- (void)didRemoveList:(NSNotification *)aNotification {
  [_actions removeApplicationList:SparkNotificationObject(aNotification)];
}

- (void)didRemoveAction:(NSNotification *)aNotification {
  [_actions removeAction:SparkNotificationObject(aNotification)];
}

- (void)didRemoveApplication:(NSNotification *)aNotification {
  [_actions removeApplication:SparkNotificationObject(aNotification)];
}

#pragma mark -
#pragma mark Accessors
- (NSImage *)icon {
  id icon = nil;
  if (icon = [super icon]) {
    return icon;
  }
  return [NSImage imageNamed:([self hasManyActions] ? @"CustomKeyIcon" : @"KeyIcon") inBundle:SKCurrentBundle()];
}

- (void)setIcon:(NSImage *)icon {
  [super setIcon:SKResizedIcon(icon, NSMakeSize(ICON_SIZE, ICON_SIZE))];
}

- (BOOL)isActive {
  return _active;
}
- (void)setActive:(BOOL)flag {
  if (_active != flag) {
    _active = flag;
  }
}

- (NSString *)comment {
  return _comment;
}
- (void)setComment:(NSString *)comment {
  if (_comment != comment) { 
    [_comment release];
    _comment = [comment copy];
  }
}

- (id)target {
  return _target;
}
- (void)setTarget:(id)newTarget {
  if (_target != newTarget) {
    _target = newTarget;
  }
}

- (SEL)action {
  return _action;
}
- (void)setAction:(SEL)newAction {
  if (_action != newAction) {
    _action = newAction;
  }
}

- (BOOL)isInvalid {
  if (![self isValid]) {
    return NO;
  }
  return [self defaultAction] == nil || 
  [[self defaultAction] isInvalid] ||
  (![self hasManyActions] && [[[self defaultAction] uid] unsignedIntValue] == 0);
}

- (SparkObjectsLibrary *)objectsLibrary {
  return [[self library] keyLibrary];
}

@end

#pragma mark -

@implementation SparkHotKey (MutlipleActionsSupport)

- (SparkAction *)currentAction {
  id action = nil;
  if ([self hasManyActions]) {
    action = [_actions actionForFrontProcess];
  } 
  if (!action) {
    action = [self defaultAction];
  }
  if (!action) {
    action = SparkIgnoreAction();
  }
  return action;
}

- (SparkAlert *)execute {
  return [[self currentAction] hotKeyShouldExecuteAction:self];
}

- (BOOL)hasManyActions {
  return [_actions count] > 1;
}
- (SparkApplicationToActionMap *)map {
  return _actions;
}

- (void)removeAllActions {
  if ([self hasManyActions]) {
    [_actions removeAllActions];
  } else {
    [self setDefaultAction:nil]; // => Remove default Action from library if (isCustom == NO)
  }
}

- (SparkAction *)defaultAction {
  return [_actions actionForApplication:SparkSystemApplication()];
}

- (void)setDefaultAction:(SparkAction *)defaultAction {
  id action = [self defaultAction];
  if (action != defaultAction) {
    [self setAction:defaultAction forApplication:SparkSystemApplication()];
    if (action && ![action isCustom]) {
      [[[self library] actionLibrary] removeObject:action];
    }
  }
}

- (void)setAction:(SparkAction *)anAction forApplication:(SparkApplication *)application {
  (anAction) ? [_actions setAction:anAction forApplication:application] : [_actions removeApplication:application];
}

- (void)setAction:(SparkAction *)anAction forApplicationList:(SparkApplicationList *)list {
  (anAction) ? [_actions setAction:anAction forApplicationList:list] : [_actions removeApplicationList:list];
}

#pragma mark Objects uids
- (NSSet *)listsUids {
  return [_actions listsUids];
}

- (NSSet *)actionsUids {
  return [_actions actionsUids];
}

- (NSSet *)applicationsUids {
  return [_actions applicationsUids];
}

#pragma mark Update Objects uids

- (void)updateActionUid:(NSArray *)uids {
  [_actions updateActionUid:[uids objectAtIndex:0] newUid:[uids objectAtIndex:1]];
}

- (void)updateListUid:(NSArray *)uids {
  if ([self hasManyActions]) {
    [_actions updateListUid:[uids objectAtIndex:0] newUid:[uids objectAtIndex:1]];
  }
}

- (void)updateApplicationUid:(NSArray *)uids {
  if ([self hasManyActions]) {
    [_actions updateApplicationUid:[uids objectAtIndex:0] newUid:[uids objectAtIndex:1]];
  }
}

@end

#pragma mark -
@implementation SparkHotKey (Forwarding)
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
  id sign = [super methodSignatureForSelector:aSelector];
  if (sign) {
    return sign;
  }
  return [_hotkey methodSignatureForSelector:aSelector];
}
+ (NSMethodSignature *)instanceMethodSignatureForSelector:(SEL)aSelector {
  id sign = [super methodSignatureForSelector:aSelector];
  if (sign) {
    return sign;
  }
  return [HKHotKey instanceMethodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
  if ([_hotkey respondsToSelector:[anInvocation selector]]) {
    [anInvocation invokeWithTarget:_hotkey];
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
    return [_hotkey respondsToSelector:aSelector];
  }
}
+ (BOOL)instancesRespondToSelector:(SEL)aSelector {
  if ([super instancesRespondToSelector:aSelector]) {
    return YES;
  }
  else {
    return [[HKHotKey class] instancesRespondToSelector:aSelector];
  }
}

- (BOOL)isKindOfClass:(Class)aClass {
  if ([super isKindOfClass:aClass]) {
    return YES;
  }
  else {
    return [_hotkey isKindOfClass:aClass];
  }
}
+ (BOOL)isSubclassOfClass:(Class)aClass {
  if ([super isSubclassOfClass:aClass]) {
    return YES;
  }
  else {
    return [[HKHotKey class] isSubclassOfClass:aClass];
  }
}
- (id)valueForUndefinedKey:(NSString *)key {
  return [_hotkey valueForKey:key];
}

@end

#pragma mark -
#pragma mark Key Repeat Support Implementation
__inline__ NSTimeInterval SparkGetDefaultKeyRepeatInterval() {
  return HKGetSystemKeyRepeatInterval();
}

@interface HKHotKeyManager (Private)
- (void)_hotKeyPressed:(HKHotKey *)key;
@end

@implementation SparkHotKeyManager

- (void)_hotKeyPressed:(HKHotKey *)key {
  id sparkKey = [key target];
  id action = [sparkKey currentAction];
  [key setKeyRepeat:(action) ? [action repeatInterval] : 0];
  [super _hotKeyPressed:key];
}

@end

static NSString * const kSparkApplicationToActionMap = @"ApplicationMap";
static NSString * const kSparkListToActionMap = @"ApplicationListMap";
#pragma mark -
@implementation SparkApplicationToActionMap 

#pragma mark -
#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
  SparkApplicationToActionMap *copy = [[[self class] allocWithZone:zone] init];
  [copy->_listMap addEntriesFromDictionary:_listMap];
  [copy->_simpleMap addEntriesFromDictionary:_simpleMap];
  return copy;
}

#pragma mark SparkSerialization
- (NSMutableDictionary *)propertyList {
  id plist = [NSMutableDictionary dictionary];
  id tmp = [[NSMutableDictionary alloc] init];
  id keys = [[_simpleMap allKeys] objectEnumerator];
  id key;
  while (key = [keys nextObject]) {
    [tmp setObject:[_simpleMap objectForKey:key] forKey:[key stringValue]];
  }
  [plist setObject:tmp forKey:kSparkApplicationToActionMap];
  [tmp release];
  
  tmp = [[NSMutableDictionary alloc] init];
  keys = [[_listMap allKeys] objectEnumerator];
  while (key = [keys nextObject]) {
    [tmp setObject:[_listMap objectForKey:key] forKey:[key stringValue]];
  }
  [plist setObject:tmp forKey:kSparkListToActionMap];
  [tmp release];
  return plist;
}

- (id)initFromPropertyList:(NSDictionary *)plist {
  if (self = [self init]) {
    _simpleMap = [[NSMutableDictionary alloc] init];
    _listMap = [[NSMutableDictionary alloc] init];
    
    id tmp = [plist objectForKey:kSparkApplicationToActionMap];
    id keys = [[tmp allKeys] objectEnumerator];
    id key;
    while (key = [keys nextObject]) {
      [_simpleMap setObject:[tmp objectForKey:key] forKey:SKUInt([key intValue])];
    }
    
    tmp = [plist objectForKey:kSparkListToActionMap];
    keys = [[tmp allKeys] objectEnumerator];
    while (key = [keys nextObject]) {
      [_listMap setObject:[tmp objectForKey:key] forKey:SKUInt([key intValue])];
    }
  }
  return self;
}

#pragma mark -
#pragma mark Init & Dealloc Methods
- (id)init {
  if (self = [super init]) {
    _listMap = [[NSMutableDictionary alloc] init];
    _simpleMap = [[NSMutableDictionary alloc] init];
    [self setAction:SparkIgnoreAction() forApplication:SparkSystemApplication()];
  }
  return self;
}

- (void)dealloc {
  [_listMap release];
  [_simpleMap release];
  [super dealloc];
}

#pragma mark -
#pragma mark Public Methods
- (unsigned)count {
  return [_simpleMap count] + [_listMap count];
}

#pragma mark Objects Accessors
- (NSSet *)lists {
  return [NSSet setWithArray:[[[self library] listLibrary] objectsWithIds:[_listMap allKeys]]];
}

- (NSSet *)actions {
  NSMutableSet *actions = [NSMutableSet set];
  id library = [[self library] actionLibrary];
  [actions addObjectsFromArray:[library objectsWithIds:[_simpleMap allValues]]];
  [actions addObjectsFromArray:[library objectsWithIds:[_listMap allValues]]];
  return actions;
}

- (NSSet *)applications { 
  return [NSSet setWithArray:[[[self library] applicationLibrary] objectsWithIds:[_simpleMap allKeys]]];
}

#pragma mark Uids Accessors
- (NSSet *)listsUids {
  return [NSSet setWithArray:[_listMap allKeys]];
}

- (NSSet *)actionsUids {
  NSMutableSet *actions = [NSMutableSet set];
  [actions addObjectsFromArray:[_simpleMap allValues]];
  [actions addObjectsFromArray:[_listMap allValues]];
  return actions;
}

- (NSSet *)applicationsUids {
  return [NSSet setWithArray:[_simpleMap allKeys]];
}

#pragma mark Find Action
- (SparkAction *)actionForFrontProcess {
  ProcessSerialNumber psn;
  if (noErr != GetFrontProcess(&psn)) {
    DLog(@"Unable to get Front Process");
    return nil;
  }
  id appli = [[[self library] applicationLibrary] applicationForProcess:&psn];
  return (appli) ? [self actionForApplication:appli] : nil;
}

/* First check if an single application correspond, and if not, check into lists */
- (SparkAction *)actionForApplication:(SparkApplication *)application {
  id actionUid = [_simpleMap objectForKey:[application uid]];
  if (!actionUid) {
    id lists = [[_listMap allKeys] objectEnumerator];
    id listUid;
    while (listUid = [lists nextObject]) {
      id list = [[[self library] listLibrary] objectWithId:listUid];
      if ([list containsObject:application]) {
        actionUid = [_listMap objectForKey:listUid];
        break;
      }
    }
  }
  return (actionUid) ? [[[self library] actionLibrary] objectWithId:actionUid] : nil;
}

- (SparkAction *)actionForEntry:(id)entry {
  id actionUid = nil;
  if ([entry isKindOfClass:[SparkObjectList class]]) {
    actionUid = [_listMap objectForKey:[entry uid]];
  } else if ([entry isKindOfClass:[SparkApplication class]]) {
    actionUid = [_simpleMap objectForKey:[entry uid]];
  }
  return (actionUid) ? [[[self library] actionLibrary] objectWithId:actionUid] : nil;
}

#pragma mark Map Manipulation
- (void)setAction:(SparkAction *)anAction forApplication:(SparkApplication *)application {
  NSParameterAssert(application != nil);
  if (!anAction) {
    anAction = SparkIgnoreAction();
  }
  [_simpleMap setObject:[anAction uid] forKey:[application uid]];
}

- (void)setAction:(SparkAction *)anAction forApplicationList:(SparkApplicationList *)list {
  NSParameterAssert(list != nil);
  if (!anAction) {
    anAction = SparkIgnoreAction();
  }
  [_listMap setObject:[anAction uid] forKey:[list uid]];
}

- (void)removeAllActions {
  [_simpleMap removeAllObjects];
  [_listMap removeAllObjects];
}

- (void)removeAction:(SparkAction *)action {
  id keys = [_simpleMap allKeysForObject:[action uid]];
  [_simpleMap removeObjectsForKeys:keys];
  keys = [_listMap allKeysForObject:[action uid]];
  [_listMap removeObjectsForKeys:keys];
}

- (void)removeApplication:(SparkApplication *)application {
  [_simpleMap removeObjectForKey:[application uid]];
}

- (void)removeApplicationList:(SparkApplicationList *)list {
  [_listMap removeObjectForKey:[list uid]];
}

- (SparkLibrary *)library {
  return _library;
}

- (void)setLibrary:(SparkLibrary *)aLibrary {
  _library = aLibrary;
}

#pragma mark -
#pragma mark UID Update

- (void)updateActionUid:(id)uid newUid:(id)newUid {
  id keys = [_simpleMap allKeysForObject:uid];
  if ([keys count])
    [_simpleMap setObject:newUid forKeys:keys];
  keys = [_listMap allKeysForObject:uid];
  if ([keys count])
    [_listMap setObject:newUid forKeys:keys];
}

- (void)updateListUid:(id)uid newUid:(id)newUid {
  id action = [_listMap objectForKey:uid];
  if (action) {
    [action retain];
    [_listMap removeObjectForKey:uid];
    [_listMap setObject:action forKey:newUid];
    [action release];
  }
}

- (void)updateApplicationUid:(id)uid newUid:(id)newUid {
  id action = [_simpleMap objectForKey:uid];
  if (action) {
    [action retain];
    [_simpleMap removeObjectForKey:uid];
    [_simpleMap setObject:action forKey:newUid];
    [action release];
  }
}

@end

@implementation NSMutableDictionary (SetMultiplesValues)

- (void)setObject:(id)anObject forKeys:(NSArray *)keys {
  id items, key;
  switch ([keys count]) {
    case 0:
      break;
    case 1:
      [self setObject:anObject forKey:[keys objectAtIndex:0]];
      break;
    default:
      items = [keys objectEnumerator];
      while (key = [items nextObject]) {
        [self setObject:anObject forKey:key];
      }
  }
}

@end
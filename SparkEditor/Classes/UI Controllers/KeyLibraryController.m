//
//  KeyLibraryController.m
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//
#import <SparkKit/SparkKit.h>
#import "KeyLibraryController.h"

#import "Preferences.h"
#import "ServerController.h"

#import "KeyEditorController.h"
#import "ListEditorController.h"

#import "KeyLibraryList.h"
#import "KeyPlugInList.h"
#import "KeyWarningList.h"

#import "PluginMenu.h"
#import "CustomTableView.h"

NSString * const kSparkHotKeyPBoardType = @"SparkHotKeyPBoardType";

static NSComparisonResult CompareList(id object1, id object2, void *context);

@implementation KeyLibraryController

- (id)init {
  if (self = [super initWithLibraryNibNamed:@"KeyLibrary"]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(warningListDidChange:)
                                                 name:kWarningListDidChangeNotification
                                               object:_warningList];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sparkDidAddPlugin:)
                                                 name:kSparkDidAddPlugInNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_warningList release];
  [_pluginsLists release];
  [super dealloc];
}

#pragma mark -
#pragma mark Configuration

- (id)objectsLibrary {
  return SparkDefaultKeyLibrary();
}

- (Class)objectEditorClass {
  return [KeyEditorController class];
}

- (NSString *)dragAndDropDataType {
  return kSparkHotKeyPBoardType;
}

- (Class)listClass {
  return [SparkKeyList class];
}

- (NSString *)confirmDeleteObjectKey {
  return kSparkPrefConfirmDeleteKey;
}

#pragma mark -

- (void)awakeFromNib {
  [super awakeFromNib];
  if (!_warningList)
    _warningList = [[KeyWarningList alloc] init];
  [menu setSubmenu:NewActionMenu() forItem:[menu itemWithTag:1]];
  [lists setCompareFunction:CompareList];
  [self loadLibrary];
  [lists setSelectionIndex:0];
}

- (NSArray *)pluginsLists {
  if (nil == _pluginsLists) {
    _pluginsLists = [[NSMutableArray alloc] init];
    id plugins = [[[SparkActionLoader sharedLoader] plugIns] objectEnumerator];
    id plugin;
    while (plugin = [plugins nextObject]) {
      id list = [[KeyPlugInList alloc] initWithPlugIn:plugin];
      [_pluginsLists addObject:list];
      [list release];
    }
    [_pluginsLists addObject:[MultipleActionsKeyList list]]; 
  }
  return _pluginsLists;
}

#pragma mark Loading Methods
- (void)loadLibrary {  
  [lists addObject:[KeyLibraryList list]]; /* Adding "Library" List */
  
  if ([_warningList count])
    [lists addObject:_warningList];
  
  [lists addObjects:[self pluginsLists]];
  [lists addObjects:[[self listsLibrary] listsWithContentType:[SparkHotKey class]]]; /* Adding Users lists */
  
  [lists rearrangeObjects]; /* Sort Lists */
}

- (void)reloadLibrary {
  unsigned idx = [lists selectionIndex];
  [lists removeAllObjects];
  [self loadLibrary];
  if ([[lists arrangedObjects] count] > idx) [lists setSelectionIndex:idx];
  [self refresh];
}

- (void)displayWarningListIfNeeded {
  if ([_warningList count]) {
    if (![[lists arrangedObjects] containsObject:_warningList]) {
      [lists addObject:_warningList];
      [lists rearrangeObjects];
    }
  } else {
    if ([[lists arrangedObjects] containsObject:_warningList]) {
      [lists removeObject:_warningList];
    }
  }  
}

- (void)refresh {
  [super refresh];
  [_warningList reload];
  [self displayWarningListIfNeeded];
}

- (void)warningListDidChange:(NSNotification *)aNotification {
  [self displayWarningListIfNeeded];
}

#pragma mark IBActions

- (IBAction)activeList:(id)sender {
  id items = [[[self selectedList] objects] objectEnumerator];
  id key;
  while (key = [items nextObject]) {
    if (![key isActive]) {
      BOOL active = [SparkDefaultKeyLibrary() activeKeyWithKeycode:[key keycode] modifier:[key modifier]] == nil;
      [key setActive:active];
    }
  }
}

- (IBAction)deactiveList:(id)sender {
  id items = [[[self selectedList] objects] objectEnumerator];
  id key;
  while (key = [items nextObject]) {
    [key setActive:NO];
  }
}

- (IBAction)listsTableDoubleAction:(id)sender {
  if ([self isEditable]) {
    if ([[[self window] currentEvent] type] != NSKeyDown) {
      if ([sender clickedRow] < 0) { /* Double clic on invalid line (header ...) */
        return;
      }
    }
    id list = [[sender dataSource] selectedObject];
    if (list && [[self pluginsLists] containsObject:list]) {
      [self newObject:sender];
    } else {
      [super listsTableDoubleAction:sender];
    }
  } else {
    [super listsTableDoubleAction:sender];
}
}

- (IBAction)newObject:(id)sender {
  id list = [self selectedList];
  if ([list respondsToSelector:@selector(plugIn)]) {
    [self newObjectOfKind:[list plugIn]];
  } else if ([list isMemberOfClass:[MultipleActionsKeyList class]]) {
    id editor = [self objectEditor];
    [editor toggleAdvancedModeView:nil];
    [self newObjectOfKind:nil];
  } else {
    [self newObjectOfKind:nil];  
  }
}

- (void)newObjectOfKind:(SparkPlugIn *)kind {
  id editor = [self objectEditor];
  [editor selectActionPlugin:kind];
  [super newObject:nil];
}

- (void)runActivationAlertForKey:(id)newKey keyAlreadyUsing:(id)oldKey {
  NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:
    NSLocalizedString(@"HOTKEY_NOT_ACTIVATED_NOTIFICATION",
                      @"Cannot activate because other Key Already Active * Title *"), [newKey name], [oldKey name]]
                                   defaultButton:NSLocalizedString(@"OK",
                                                                   @"Alert default button")
                                 alternateButton:nil
                                     otherButton:nil
                       informativeTextWithFormat:NSLocalizedString(@"HOTKEY_NOT_ACTIVATED_NOTIFICATION_MSG",
                                                                   @"Other Key With same Shortcut Already Active * Msg *"), [oldKey name]];
  NSBeep();
  [alert runModal];
}

- (void)updateObject:(id)object {
  if ([object isActive]) {
    id key = [SparkDefaultKeyLibrary() activeKeyWithKeycode:[object keycode] modifier:[object modifier]];
    if (nil != key && object != key) {
      [self runActivationAlertForKey:object keyAlreadyUsing:key];
      [object setActive:NO];
    }
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:kSparkHotKeyDidChangeNotification object:object];
  [super updateObject:object];
  [self displayWarningListIfNeeded];
  [self selectObject:object];
}

- (void)createObject:(id)object {
  [super createObject:object];
  id key = [SparkDefaultKeyLibrary() activeKeyWithKeycode:[object keycode] modifier:[object modifier]];
  if (nil != key && object != key) {
    [self runActivationAlertForKey:object keyAlreadyUsing:key];
    [object setActive:NO];
  } else {
    [object setActive:YES];
  }
  [self selectObject:object];
}

- (void)selectObject:(id)object {
  SparkObjectList *list = [self selectedList];
  if (![list containsObject:object]) {
    id items = [[self pluginsLists] objectEnumerator];
    id item;
    while (item = [items nextObject]) {
      if ([item containsObject:object]) {
        [lists setSelectedObject:item];
        break;
      }
    }
    [objects setSelectedObject:object];
  }
  [[self window] makeFirstResponder:[self objectsTable]];
}

- (void)removeObject:(id)object {
  [object setDefaultAction:nil];
  [super removeObject:object];
}

- (void)removeObjects:(NSArray *)objectsArray {
  id items = [objectsArray objectEnumerator];
  id item;
  while (item = [items nextObject]) {
    [item setDefaultAction:nil];  
  }
  [super removeObjects:objectsArray];
  [self displayWarningListIfNeeded];
}

/*****************************************************/
#pragma mark -
#pragma mark Dynamic Plugin Loading.
- (void)sparkDidAddPlugin:(NSNotification *)notification {
  SparkPlugIn *plugin = [notification object];
  Class newClass = [plugin principalClass];
  id items = [[self pluginsLists] objectEnumerator];
  id list;
  while (list = [items nextObject]) {
    if ([list respondsToSelector:@selector(plugIn)] && [[list plugIn] principalClass] == newClass)
      return;
  }
  list = [KeyPlugInList listWithPlugIn:plugin];
  if (list) {
    [_pluginsLists addObject:list];
    [self reloadLibrary];
  }
}

//- (void)plugInRemoved:(NSNotification *)notification {
//  id plug = [notification object];
//  id lists = [plugInLists objectEnumerator];
//  id list;
//  while (list = [lists nextObject]) {
//    if ([list isMemberOfClass:[PlugInKeyList class]]) {
//      if ([plug principalClass] == [[list plugIn] principalClass]) {
//        [_keys removeObjects:[list objects]];
//        [plugInLists removeObject:list];
//        [library removeObject:list];
//        break;
//      }
//    }
//  }
//}

@end

#pragma mark -
@implementation CheckActiveSparkHotKey

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
  return ([theKey isEqualToString:@"active"]) ? NO : [super automaticallyNotifiesObserversForKey:theKey];
}

-(BOOL)validateActive:(id *)ioValue error:(NSError **)outError {
  BOOL flag = [*ioValue boolValue];
  if (flag) {
    //Test if an other key is already active with same shortcut or not.
    id key = [SparkDefaultKeyLibrary() activeKeyWithKeycode:[self keycode] modifier:[self modifier]];
    if (nil != key) {
      NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:
        NSLocalizedString(@"HOTKEY_NOT_ACTIVATED_ALERT",
                          @"Other Hot Key With same Shortcut Already Active * Title *"), [self name]]
                                       defaultButton:NSLocalizedString(@"OK",
                                                                       @"Alert default button")
                                     alternateButton:nil
                                         otherButton:nil
                           informativeTextWithFormat: NSLocalizedString(@"HOTKEY_NOT_ACTIVATED_ALERT_MSG",
                                                                        @"Other Key With same Shortcut Already Active * Msg *"), [key name]];
      NSBeep();
      [alert runModal];
      *ioValue = SKBool(NO);
    }
  }
  return YES;
}

- (void)setActive:(BOOL)flag {
  if ([super isActive] != flag) {
    [self willChangeValueForKey:@"active"];
    [super setActive:flag];
    [self didChangeValueForKey:@"active"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSparkHotKeyStateDidChangeNotification object:self];
  }
}

- (NSImage *)icon {
  if ([self isInvalid]) {
    return [NSImage imageNamed:@"Warning"];
  } else {
    return [super icon];
  }
}

- (NSString *)categorie {
  if ([self hasManyActions])
    return NSLocalizedStringFromTable(@"CUSTOM_KEY_CATEGORIE",
                                      @"Libraries", @"Multiple Actions Key Categorie");
  else 
    return [[self defaultAction] categorie];
}

- (NSString *)shortDescription {
  if ([self hasManyActions])
    return NSLocalizedStringFromTable(@"CUSTOM_KEY_DESC",
                                      @"Libraries", @"Multiple Actions Key Description");
  else 
    return [[self defaultAction] shortDescription];
}

@end

#pragma mark -
#pragma mark Compare Function
static NSComparisonResult CompareList(id object1, id object2, void *context) {
  if ([object1 class] == [object2 class]) {
    return [[object1 name] caseInsensitiveCompare:[object2 name]];
  }
  
  //La Bibliothque passe en premier 
  if ([object1 isMemberOfClass:[KeyLibraryList class]]) {
    return NSOrderedAscending;
  } else if ([object2 isMemberOfClass:[KeyLibraryList class]]) {
    return NSOrderedDescending;
  }
  if ([object1 isMemberOfClass:[KeyWarningList class]]) {
    return NSOrderedAscending;
  } else if ([object2 isMemberOfClass:[KeyWarningList class]]) {
    return NSOrderedDescending;
  }
  if ([object1 isMemberOfClass:[MultipleActionsKeyList class]]) {
    return NSOrderedAscending;
  } else if ([object2 isMemberOfClass:[MultipleActionsKeyList class]]) {
    return NSOrderedDescending;
  }
  if ([object1 isMemberOfClass:[KeyPlugInList class]]) {
    return NSOrderedAscending;
  } else if ([object2 isMemberOfClass:[KeyPlugInList class]]) {
    return NSOrderedDescending;
  }
  return NSOrderedSame;
}
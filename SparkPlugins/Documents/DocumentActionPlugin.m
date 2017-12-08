/*
 *  DocumentActionPlugin.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "DocumentActionPlugin.h"

#import "DocumentAction.h"
#import "DAApplicationMenu.h"

#import <WonderBox/WonderBox.h>

@implementation DocumentActionPlugin

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
  if ([key isEqualToString:@"url"] || [key isEqualToString:@"tabIndex"] || [key isEqualToString:@"displayWithMenu"]) {
    return [NSSet setWithObject:@"action"];
  }
  return [super keyPathsForValuesAffectingValueForKey:key];;
}

/*===============================================*/

- (void)loadSparkAction:(DocumentAction *)sparkAction toEdit:(BOOL)edit {
  [ibName setStringValue:[sparkAction name] ? : @""];
  if (edit) {
    [self willChangeValueForKey:@"action"];
    
    if (DocumentActionNeedDocument([sparkAction action])) {
      [self setDocument:sparkAction.document.URL];
    }
    if (DocumentActionNeedApplication([sparkAction action])) {
      [self setApplication:sparkAction.application.URL];
    }
    [self didChangeValueForKey:@"action"];
  } else {
    [self setAction:kDocumentActionOpen];
  }
}

static inline
NSAlert *SimpleAlert(NSString *title, NSString *message) {
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = title;
  alert.informativeText = message;
  return alert;
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  int action = [self action];
  if (DocumentActionNeedDocument(action) && !_document) {
    return SimpleAlert(NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_DOCUMENT_ALERT", nil,
                                                          kDocumentActionBundle,
                                                          @"Error when user try to create/update Action without choose document * Title *"),
                       NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_DOCUMENT_ALERT_MSG", nil,
                                                          kDocumentActionBundle,
                                                          @"Error when user try to create/update Action without choose document * Msg *"));
  } else if (DocumentActionNeedApplication(action) && ![self application]) {
    return SimpleAlert(NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_APPLICATION_ALERT", nil,
                                                          kDocumentActionBundle,
                                                          @"Error when user try to create/update Action without choose application * Title *"),
                       NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_APPLICATION_ALERT_MSG", nil,
                                                          kDocumentActionBundle,
                                                          @"Error when user try to create/update Action without choose application * Msg *"));
  } else if (action == kDocumentActionOpenURL && ![self url]) {
    return SimpleAlert(NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_URL_ALERT", nil,
                                                          kDocumentActionBundle,
                                                          @"Error when user try to create/update Action without choose application * Title *"),
                       NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_URL_ALERT_MSG", nil,
                                                          kDocumentActionBundle,
                                                          @"Error when user try to create/update Action without choose application * Msg *"));
  }
  return nil;
}

- (void)configureAction {
  DocumentAction *action = [self sparkAction];
  
  if ([ibName stringValue] && [[ibName stringValue] length])
    [action setName:[ibName stringValue]];
  else
    [action setName:[[ibName cell] placeholderString]];
  
  [action setDocumentURL:nil];
  [action setApplicationURL:nil];
  
  /* Set Icon */
  if (DocumentActionNeedDocument([action action])) {
    [action setIcon:_documentIcon];
    [action setDocumentURL:[self document]];
  } else if([action action] == kDocumentActionOpenSelectionWith) {
    [action setIcon:[[ibMenu selectedItem] image]];
  } else {
    [action setIcon:DocumentActionIcon(action)];
  }
  
  /* Set App Path */
  if (DocumentActionNeedApplication([action action])) {
    [action setApplicationURL:[self application]];
  }
  
  [action setActionDescription:DocumentActionDescription(action)];
}

#pragma mark -
- (IBAction)chooseDocument:(NSView *)sender {
  NSOpenPanel *oPanel = [NSOpenPanel openPanel];
  [oPanel setAllowsMultipleSelection:NO];
  [oPanel setCanChooseDirectories:YES];
  [oPanel setCanCreateDirectories:NO];
  [oPanel beginSheetModalForWindow:sender.window completionHandler:^(NSInteger result) {
    if (result == NSModalResponseCancel || [[oPanel URLs] count] == 0) {
      return;
    }
    [self setDocument:[[oPanel URLs] firstObject]];
  }];
}

- (void)setDocument:(NSURL *)file {
  if (_document != file) {
    _document = [file copy];
    [ibMenu loadAppForDocument:_document];
    if (_document) {
      NSDictionary *rsrc = [_document resourceValuesForKeys:@[NSURLEffectiveIconKey, NSURLLocalizedNameKey] error:NULL];
      [self setDocumentIcon:rsrc[NSURLEffectiveIconKey]];
      [self setDocumentName:rsrc[NSURLLocalizedNameKey]];
    } else {
      [self setDocumentName:nil];
      [self setDocumentIcon:nil];
    }
  }
}

- (NSString *)application {
  NSDictionary *item = [[ibMenu selectedItem] representedObject];
  if ([item isKindOfClass:[NSDictionary class]]) {
    return [[item objectForKey:@"path"] path];
  }
  return nil;
}
- (void)setApplication:(NSURL *)url {
  NSUInteger idx = [ibMenu numberOfItems];
  while (idx-- > 0) {
    id obj = [[ibMenu itemAtIndex:idx] representedObject];
    if (obj && [obj isKindOfClass:[NSDictionary class]]) {
      NSURL *path = [obj objectForKey:@"path"];
      if (path && [path isEqual:url]) {
        [ibMenu selectItemAtIndex:idx];
        return;
      }
    }
  }
  NSMenuItem *item = [ibMenu itemForURL:url];
  if (item) {
    [[ibMenu menu] insertItem:item atIndex:0];
    [ibMenu selectItemAtIndex:0];
  }
}

- (NSString *)url {
  return [(DocumentAction *)[self sparkAction] URL];
}
- (void)setUrl:(NSString *)anUrl {
  [(DocumentAction *)[self sparkAction] setURL:anUrl];
}

- (DocumentActionType)action {
  return [(DocumentAction *)[self sparkAction] action];
}
- (void)setAction:(DocumentActionType)anAction {
  [(DocumentAction *)[self sparkAction] setAction:anAction];
  
  switch ([self action]) {
    case kDocumentActionOpen:
    case kDocumentActionReveal:
    case kDocumentActionOpenWith:
      [[ibName cell] setPlaceholderString:[[self documentName] stringByDeletingPathExtension] ? : @""];
      break;
    case kDocumentActionOpenSelection:
    case kDocumentActionOpenSelectionWith:
      [[ibName cell] setPlaceholderString:NSLocalizedStringFromTableInBundle(@"OPEN_SELECTION_PLACEHOLDER", nil, 
                                                                             kDocumentActionBundle,
                                                                             @"Open Selection * Placeholder *")];
      break;
    case kDocumentActionOpenURL:
      [[ibName cell] setPlaceholderString:NSLocalizedStringFromTableInBundle(@"OPEN_URL_PLACEHOLDER", nil, 
                                                                             kDocumentActionBundle,
                                                                             @"Open URL * Placeholder *")];
      break;
    default:
      [[ibName cell] setPlaceholderString:@""];
  }
  
}

- (NSInteger)tabIndex {
  switch ([self action]) {
    case kDocumentActionOpen:
    case kDocumentActionReveal:
    case kDocumentActionOpenWith:
      return 0;
    case kDocumentActionOpenURL:
      return 2;
    default:
      return 1;
  }
}
- (void)setTabIndex:(NSInteger)newTabIndex {}

- (BOOL)displayWithMenu {
  return DocumentActionNeedApplication([self action]);
}

- (void)setDisplayWithMenu:(BOOL)newDisplayWithMenu { }

- (void)setDocumentName:(NSString *)aName {
  SPXSetterCopyAndDo(_documentName, aName, {
    [[ibName cell] setPlaceholderString:[aName stringByDeletingPathExtension] ? : @""];
  });
}

#pragma mark -
+ (NSImage *)plugInViewIcon {
  return [NSImage imageNamed:@"DocumentPlugin" inBundle:kDocumentActionBundle];
}

@end

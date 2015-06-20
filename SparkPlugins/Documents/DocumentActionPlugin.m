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

#import <WonderBox/NSImage+WonderBox.h>

#import <WonderBox/WBAlias.h>
#import <WonderBox/WBAliasedApplication.h>

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
      [self setDocument:[[sparkAction document] path]];
    }
    if (DocumentActionNeedApplication([sparkAction action])) {
      [self setApplication:[[sparkAction application] path]];
    }
    [self didChangeValueForKey:@"action"];
  } else {
    [self setAction:kDocumentActionOpen];
  }
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  int action = [self action];
  if (DocumentActionNeedDocument(action) && !_document) {
    return [NSAlert alertWithMessageText:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_DOCUMENT_ALERT", nil, 
                                                                            kDocumentActionBundle,
                                                                            @"Error when user try to create/update Action without choose document * Title *")
                           defaultButton:NSLocalizedStringFromTableInBundle(@"OK", nil, 
                                                                            kDocumentActionBundle,
                                                                            @"Alert default button")
                         alternateButton:nil
                             otherButton:nil
               informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_DOCUMENT_ALERT_MSG", nil, 
                                                                            kDocumentActionBundle,
                                                                            @"Error when user try to create/update Action without choose document * Msg *")];
  } else if (DocumentActionNeedApplication(action) && ![self application]) {
    return [NSAlert alertWithMessageText:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_APPLICATION_ALERT", nil, 
                                                                            kDocumentActionBundle,
                                                                            @"Error when user try to create/update Action without choose application * Title *")
                           defaultButton:NSLocalizedStringFromTableInBundle(@"OK", nil, 
                                                                            kDocumentActionBundle,
                                                                            @"Alert default button")
                         alternateButton:nil
                             otherButton:nil
               informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_APPLICATION_ALERT_MSG", nil, 
                                                                            kDocumentActionBundle,
                                                                            @"Error when user try to create/update Action without choose application * Msg *")];
  } else if (action == kDocumentActionOpenURL && ![self url]) {
    return [NSAlert alertWithMessageText:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_URL_ALERT", nil, 
                                                                            kDocumentActionBundle,
                                                                            @"Error when user try to create/update Action without choose application * Title *")
                           defaultButton:NSLocalizedStringFromTableInBundle(@"OK", nil, 
                                                                            kDocumentActionBundle,
                                                                            @"Alert default button")
                         alternateButton:nil
                             otherButton:nil
               informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_URL_ALERT_MSG", nil, 
                                                                            kDocumentActionBundle,
                                                                            @"Error when user try to create/update Action without choose application * Msg *")];    
  }
  return nil;
}

- (void)configureAction {
  DocumentAction *action = [self sparkAction];
  
  if ([ibName stringValue] && [[ibName stringValue] length])
    [action setName:[ibName stringValue]];
  else
    [action setName:[[ibName cell] placeholderString]];
  
  [action setDocumentPath:nil];
  [action setApplicationPath:nil];
  
  /* Set Icon */
  if (DocumentActionNeedDocument([action action])) {
    [action setIcon:_documentIcon];
    [action setDocumentPath:[self document]];
  } else if([action action] == kDocumentActionOpenSelectionWith) {
    [action setIcon:[[ibMenu selectedItem] image]];
  } else {
    [action setIcon:DocumentActionIcon(action)];
  }
  
  /* Set App Path */
  if (DocumentActionNeedApplication([action action])) {
    [action setApplicationPath:[self application]];
  }
  
  [action setActionDescription:DocumentActionDescription(action)];
}

#pragma mark -
- (IBAction)chooseDocument:(id)sender {
  NSOpenPanel *oPanel = [NSOpenPanel openPanel];
  [oPanel setAllowsMultipleSelection:NO];
  [oPanel setCanChooseDirectories:YES];
  [oPanel setCanCreateDirectories:NO];
  
  [oPanel beginSheetForDirectory:nil
                            file:nil
                           types:nil
                  modalForWindow:[sender window]
                   modalDelegate:self
                  didEndSelector:@selector(chooseItemPanel:returnCode:contextInfo:)
                     contextInfo:nil];
}

- (void)chooseItemPanel:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo {
  if (returnCode == NSCancelButton || [[sheet URLs] count] == 0) {
    return;
  }
  [self setDocument:[[sheet filenames] objectAtIndex:0]];
}

- (void)setDocument:(NSString *)file {
  if (_document != file) {
    _document = [file copy];
    [ibMenu loadAppForDocument:[NSURL fileURLWithPath:_document]];
    if (_document) {
      [self setDocumentIcon:[[NSWorkspace sharedWorkspace] iconForFile:_document]];
      [self setDocumentName:[[NSFileManager defaultManager] displayNameAtPath:_document]];
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
- (void)setApplication:(NSString *)aPath {
  NSUInteger idx = [ibMenu numberOfItems];
  NSURL *url = [NSURL fileURLWithPath:aPath];
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

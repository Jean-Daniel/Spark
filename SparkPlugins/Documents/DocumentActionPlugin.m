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

#import WBHEADER(NSImage+WonderBox.h)

@implementation DocumentActionPlugin

+ (void)initialize {
  if ([DocumentActionPlugin class] == self) {
    [self setKeys:[NSArray arrayWithObject:@"action"] triggerChangeNotificationsForDependentKey:@"url"];
    [self setKeys:[NSArray arrayWithObject:@"action"] triggerChangeNotificationsForDependentKey:@"tabIndex"];
    [self setKeys:[NSArray arrayWithObject:@"action"] triggerChangeNotificationsForDependentKey:@"displayWithMenu"];
  }
}

- (void)dealloc {
  [da_path release];
  [da_name release];
  [da_icon release];
  [super dealloc];
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
  if (DocumentActionNeedDocument(action) && !da_path) {
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
    [action setIcon:da_icon];
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
  if (returnCode == NSCancelButton || [[sheet filenames] count] == 0) {
    return;
  }
  [self setDocument:[[sheet filenames] objectAtIndex:0]];
}

- (NSString *)document {
  return da_path;
}
- (void)setDocument:(NSString *)file {
  if (da_path != file) {
    [da_path release];
    da_path = [file copy];
    [ibMenu loadAppForDocument:da_path];
    if (da_path) {
      [self setDocumentIcon:[[NSWorkspace sharedWorkspace] iconForFile:da_path]];
      [self setDocumentName:[[NSFileManager defaultManager] displayNameAtPath:da_path]];
    } else {
      [self setDocumentName:nil];
      [self setDocumentIcon:nil];
    }
  }
}

- (NSString *)application {
  NSDictionary *item = [[ibMenu selectedItem] representedObject];
  if ([item isKindOfClass:[NSDictionary class]]) {
    return [item objectForKey:@"path"];
  }
  return nil;
}
- (void)setApplication:(NSString *)aPath {
  NSUInteger idx = [ibMenu numberOfItems];
  while (idx-- > 0) {
    id obj = [[ibMenu itemAtIndex:idx] representedObject];
    if (obj && [obj isKindOfClass:[NSDictionary class]]) {
      NSString *path = [obj objectForKey:@"path"];
      if (path && [path isEqualToString:aPath]) {
        [ibMenu selectItemAtIndex:idx];
        return;
      }
    }
  }
  NSMenuItem *item = [ibMenu itemForPath:aPath];
  if (item) {
    [[ibMenu menu] insertItem:item atIndex:0];
    [ibMenu selectItemAtIndex:0];
  }
}

- (NSString *)url {
  return [(DocumentAction *)[self sparkAction] url];
}
- (void)setUrl:(NSString *)anUrl {
  [(DocumentAction *)[self sparkAction] setURL:anUrl];
}

- (int)action {
  return [(DocumentAction *)[self sparkAction] action];
}
- (void)setAction:(int)anAction {
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

- (int)tabIndex {
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
- (void)setTabIndex:(int)newTabIndex {}

- (BOOL)displayWithMenu {
  return DocumentActionNeedApplication([self action]);
}

- (void)setDisplayWithMenu:(BOOL)newDisplayWithMenu { }


- (NSString *)documentName {
  return da_name;
}

- (void)setDocumentName:(NSString *)aName {
  if (WBSetterCopy(&da_name, aName))
    [[ibName cell] setPlaceholderString:[aName stringByDeletingPathExtension] ? : @""];
}

- (NSImage *)documentIcon {
  return da_icon;
}
- (void)setDocumentIcon:(NSImage *)anIcon {
  WBSetterRetain(&da_icon, anIcon);
}

#pragma mark -
+ (NSImage *)plugInViewIcon {
  return [NSImage imageNamed:@"DocumentPlugin" inBundle:kDocumentActionBundle];
}

@end

//
//  DocumentActionPlugin.m
//  Short-Cut
//
//  Created by Fox on Mon Dec 08 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#if defined (DEBUG)
#warning Debug defined in DocumentAction!
#endif

#import "DocumentAction.h"
#import "DocumentActionPlugin.h"
#import "ApplicationMenu.h"

NSString * const kDocumentActionBundleIdentifier = @"fr.shadowlab.DocumentAction";

@implementation DocumentActionPlugin

+ (void)initialize {
  static BOOL tooLate = NO;
  if (!tooLate ) {
    [self setKeys:[NSArray arrayWithObject:@"action"] triggerChangeNotificationsForDependentKey:@"tabIndex"];
    [self setKeys:[NSArray arrayWithObject:@"action"] triggerChangeNotificationsForDependentKey:@"displayWithMenu"];
    tooLate = YES;
  }
}

- (void)dealloc {
  [_docPath release];
  [_docName release];
  [_docIcon release];
  [super dealloc];
}
/*===============================================*/

- (void)loadSparkAction:(id)sparkAction toEdit:(BOOL)edit {
  [super loadSparkAction:sparkAction toEdit:edit];
  [self setAction:[sparkAction docAction]];
  [self setFile:[[sparkAction docAlias] path]];
  id app = [[sparkAction appAlias] path];
  if (app) {
    [[appMenu menu] insertItem:[appMenu itemForPath:app] atIndex:0];
    [appMenu selectItemAtIndex:0];
  }
  if (edit) {
    [[self undoManager] registerUndoWithTarget:sparkAction selector:@selector(setUrl:) object:[sparkAction url]];
  }
  [nameField setStringValue:([sparkAction name]) ? [sparkAction name] : @""];
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  if ((action == kDocumentActionOpen || action == kDocumentActionOpenWith) &&  _docPath == nil) {
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
  }
  else if ((action == kDocumentActionOpenWith || action == kDocumentActionOpenSelectionWith) && [self appPath] == nil) {
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
  } else if (action == kDocumentActionOpenURL && ![[self sparkAction] url]) {
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
  DocumentAction *docAction = [self sparkAction];
  [docAction setDocAction:[self action]];
  [docAction setName:([[self name] length]) ? [self name] : _docName];
  /* Set Icon */
  if (action == kDocumentActionOpen || action == kDocumentActionOpenWith) {
    [docAction setIcon:[self docIcon]];
    [docAction setDocPath:_docPath];
  }
  else if (action == kDocumentActionOpenSelection) {
    [docAction setIcon:[NSImage imageNamed:@"Selection" inBundle:kDocumentActionBundle]];
    [docAction setDocPath:nil];
  } 
  else if (action == kDocumentActionOpenSelectionWith) {
    [docAction setIcon:[[appMenu selectedItem] image]];
  } else if (action == kDocumentActionOpenURL) {
    [docAction setIcon:[NSImage imageNamed:@"URLIcon" inBundle:kDocumentActionBundle]];
  }
  
  /* Set App Path */
  if (action == kDocumentActionOpenWith || action == kDocumentActionOpenSelectionWith) {
    [docAction setAppPath:[self appPath]];
  }
  else {
    [docAction setAppPath:nil];
  }
  
  [docAction setShortDescription:[self shortDescription]];
}

#pragma mark -
- (NSString *)shortDescription {
  NSString *desc = nil;
  switch (action) {
    case kDocumentActionOpen:
    case kDocumentActionOpenWith:
      desc = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_OPEN", nil,
                                                                           kDocumentActionBundle,
                                                                           @"Short description"), [self docName]];
      break;
    case kDocumentActionOpenSelection:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_OPEN_SELECTION", nil, 
                                                kDocumentActionBundle,
                                                @"Short description");
      break;
    case kDocumentActionOpenSelectionWith:
      desc = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_OPEN_SELECTION_WITH", nil, 
                                                                           kDocumentActionBundle,
                                                                           @"Short description"), [[appMenu selectedItem] title]];
      break;
    case kDocumentActionOpenURL:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_OPEN_URL", nil, 
                                                kDocumentActionBundle,
                                                @"Short description");
      break;
    default:
      desc = @"Invalid Action";
  }
  return desc;
}

/*===============================================*/
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
  if (returnCode == NSCancelButton) {
    return;
  }
  [self setFile:[[sheet filenames] objectAtIndex:0]];
}

- (void)setFile:(NSString *)file {
  if (file) {
    [_docPath release];
    _docPath = [file copy];
    [appMenu loadAppForDocument:file];
    id path = _docPath;
    if (path) {
      [self setValue:[[[NSFileManager defaultManager] displayNameAtPath:path] stringByDeletingPathExtension] forKeyPath:@"docName"];
      id icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
      [self setValue:icon forKeyPath:@"docIcon"];
    }
  }
}

- (NSString *)name {
  return [nameField stringValue];
}

- (NSString *)appPath {
  id item = [[appMenu selectedItem] representedObject];
  if ([item isKindOfClass:[NSDictionary class]]) {
    return [item objectForKey:@"path"];
  }
  return nil;
}
@end

/*===============================================*/
@implementation DocumentActionPlugin (KVC_Compliance)


- (DocumentActionType)action { return action; }
- (void)setAction:(DocumentActionType)newAction { action = newAction; }

- (int)tabIndex {
  return (action == kDocumentActionOpen || action == kDocumentActionOpenWith) ? 0 : (action == kDocumentActionOpenURL) ? 2 : 1;
}
- (void)setTabIndex:(int)newTabIndex {}

- (BOOL)displayWithMenu {
  return action == kDocumentActionOpenWith || action == kDocumentActionOpenSelectionWith;
}

- (void)setDisplayWithMenu:(BOOL)newDisplayWithMenu {
}


- (NSString *)docName {
  return [[_docName retain] autorelease];
}

- (void)setDocName:(NSString *)newDocName {
  if (_docName != newDocName) {
    [_docName release];
    _docName = [newDocName copy];
    [[nameField cell] setPlaceholderString:_docName];
    [nameField setStringValue:[nameField stringValue]];
  }
}

- (NSImage *)docIcon {
  return [[_docIcon retain] autorelease];
}

- (void)setDocIcon:(NSImage *)newDocIcon {
  if (_docIcon != newDocIcon) {
    [_docIcon release];
    _docIcon = [newDocIcon retain];
  }
}


@end
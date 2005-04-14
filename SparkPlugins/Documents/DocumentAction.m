//
//  ApplicationAction.m
//  Spark
//
//  Created by Fox on Wed Dec 10 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "DocumentAction.h"
#import "DocumentActionPlugin.h"

static NSString* const kDocumentActionURLKey = @"DocumentURL";
static NSString* const kDocumentActionSignKey = @"AppSign";
static NSString* const kDocumentActionTypeKey = @"DocAction";
static NSString* const kDocumentActionDocumentKey = @"DocAlias";
static NSString* const kDocumentActionApplicationKey = @"AppAlias";

@implementation DocumentAction

+ (void)initialize {
  static BOOL tooLate = NO;
  if (!tooLate ) {
    [self setVersion:0x110];
    tooLate = YES;
  }
}

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  DocumentAction* copy = [super copyWithZone:zone];
  copy->_docAction = _docAction;
  copy->_docAlias = [_docAlias copy];
  copy->_appAlias = [_appAlias copy];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:_docAction forKey:kDocumentActionTypeKey];
  if (_docAlias)
    [coder encodeObject:_docAlias forKey:kDocumentActionDocumentKey];
  if (_appAlias)
    [coder encodeObject:_appAlias forKey:kDocumentActionApplicationKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    _docAction = [coder decodeIntForKey:kDocumentActionTypeKey];
    _docAlias = [[coder decodeObjectForKey:kDocumentActionDocumentKey] retain];
    _appAlias = [[coder decodeObjectForKey:kDocumentActionApplicationKey] retain];
  }
  return self;
}

#pragma mark -
#pragma mark Required Methods.
- (id)initFromPropertyList:(id)plist {
  if (self = [super initFromPropertyList:plist]) {
    [self setDocAction:[[plist objectForKey:kDocumentActionTypeKey] intValue]];
    if (_docAction == kDocumentActionOpen || _docAction == kDocumentActionOpenWith) {
      [self setDocAlias:[SKAlias aliasWithData:[plist objectForKey:kDocumentActionDocumentKey]]];
    }
    if (_docAction == kDocumentActionOpenWith || _docAction == kDocumentActionOpenSelectionWith) {
      SKApplicationAlias *app = [SKApplicationAlias aliasWithData:[plist objectForKey:kDocumentActionApplicationKey]];
      if (![app path]) {
        [app setSignature:[plist objectForKey:kDocumentActionSignKey]];
      }
      [self setAppAlias:app];
    }
    if (_docAction == kDocumentActionOpenURL) {
      [self setUrl:[plist objectForKey:kDocumentActionURLKey]];
    }
  }
  return self;
}

- (void)dealloc {
  [_url release];
  [_docAlias release];
  [_appAlias release];
  [super dealloc];
}

- (NSMutableDictionary *)propertyList {
  id dico = [super propertyList];
  [dico setObject:SKInt(_docAction) forKey:kDocumentActionTypeKey];
  if (_docAction == kDocumentActionOpen || _docAction == kDocumentActionOpenWith) {
    [dico setObject:[_docAlias data] forKey:kDocumentActionDocumentKey];
  }
  if (_docAction == kDocumentActionOpenWith || _docAction == kDocumentActionOpenSelectionWith) {
    if (_appAlias) {
      if ([_appAlias signature])
        [dico setObject:[_appAlias signature] forKey:kDocumentActionSignKey];
      id aliasData = [_appAlias data];
      if (aliasData != nil)
        [dico setObject:aliasData forKey:kDocumentActionApplicationKey];
    }
  }
  if (_docAction == kDocumentActionOpenURL) {
    if (_url) {
      [dico setObject:_url forKey:kDocumentActionURLKey];
    }
  }
  return dico;
}

- (SparkAlert *)check {
  id alert = nil;
  if (_docAction == kDocumentActionOpen || _docAction == kDocumentActionOpenWith) {
    if ([[self docAlias] path] == nil) {
      //Alert Doc invalide
      alert = [SparkAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_DOCUMENT_ALERT", nil, 
                                                                                                             kDocumentActionBundle,
                                                                                                             @"Document not found * Check Title *"), [self name]]
                     informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_DOCUMENT_ALERT_MSG", nil, 
                                                                                  kDocumentActionBundle,
                                                                                  @"Document not found  * Check Msg *"), [self name]];
    }
  }
  if (_docAction == kDocumentActionOpenWith || _docAction == kDocumentActionOpenSelectionWith) {
    if ([[self appAlias] path] == nil) {
      //Alert App Invalide
      alert = [SparkAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_APPLICATION_ALERT", nil, 
                                                                                                             kDocumentActionBundle,
                                                                                                             @"Application not found * Check Title *"), [self name]]
                     informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_APPLICATION_ALERT_MSG", nil, 
                                                                                  kDocumentActionBundle,
                                                                                  @"Application not found  * Check Msg *"), [self name]];
    }
  }
  return alert;
}

- (SparkAlert *)execute {
  id alert = [self check];
  if (alert == nil) {
    if (_docAction == kDocumentActionOpen || _docAction == kDocumentActionOpenWith) {
      if (![[NSWorkspace sharedWorkspace] openFile:[[self docAlias] path] withApplication:[[self appAlias] path]]) {
        NSBeep();
        // Impossible d'ouvrir le document (alert = ?)
      }
    } else if (_docAction == kDocumentActionOpenSelection || _docAction == kDocumentActionOpenSelectionWith) {
      // Check if Finder is foreground
      if ([self isFinderForeground]) {
        [self openSelection];
      }
    } else if (_docAction == kDocumentActionOpenURL) {
      alert = [self openURL];
    }
  }
  return alert;
}

- (SparkAlert *)openURL {
  id alert = nil;
  if (![[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:_url]]) {
    // TODO
    /* alert = []; */
  }
  return alert;
}

- (void)openSelection {
  AEDescList selection = {typeNull, nil};
  long count = 0;
  
  // Get Finder Selection.
  OSStatus err = ShadowAEGetFinderSelection(&selection);
  if (noErr == err) {
    // Get selection Count
    err = AECountItems(&selection, &count);
  }
  if (noErr == err && count > 0) {
    // if selected items
    FSRef *refs = NSZoneCalloc(nil, count, sizeof(FSRef));
    int realCount;
    // Get FSRef for these items.
    err = ShadowAEFinderSelectionToFSRefs(&selection ,refs, count, &realCount);
    if (noErr == err && realCount > 0) {
      LSLaunchFSRefSpec spec;
      FSRef app;
      
      if ([[[self appAlias] path] getFSRef:&app]) {
        spec.appRef = &app;
      }
      else {
        spec.appRef = nil;
      }
      
      spec.numDocs = realCount;
      spec.itemRefs = refs;
      spec.passThruParams = nil;
      spec.launchFlags = kLSLaunchDefaults;
      spec.asyncRefCon = nil;
      LSOpenFromRefSpec(&spec, nil);
    }
    NSZoneFree(nil, refs);
  }
  ShadowAEDisposeDesc(&selection);
}

- (BOOL)isFinderForeground {
  ProcessSerialNumber psn;
  BOOL frontmost = NO;
  GetFrontProcess(&psn);
  if (psn.lowLongOfPSN != kNoProcess) {
    id info = (id)ProcessInformationCopyDictionary(&psn, 0); //kProcessDictionaryIncludeAllInformationMask);
    UInt32 sign = SKHFSTypeCodeFromFileType([info objectForKey:@"FileCreator"]);
    frontmost = (sign == 'MACS');
    [info release];
  }
  return frontmost;
}

- (DocumentActionType)docAction {
  return _docAction;
}

- (void)setDocAction:(DocumentActionType)newAction {
  _docAction = newAction;
}


- (void)setDocPath:(NSString *)path {
  [self setDocAlias:[SKAlias aliasWithPath:path]];
}

- (void)setAppPath:(NSString *)path {
  id app = [SKApplicationAlias aliasWithPath:path];
  [self setAppAlias:([app path]) ? app : nil];
}

- (NSString *)url {
  return _url;
}

- (void)setUrl:(NSString *)newUrl {
  if (_url != newUrl) {
    [_url release];
    _url = [newUrl copy];
  }
}

- (SKAlias *)docAlias {
  return [[_docAlias retain] autorelease];
}

- (void)setDocAlias:(SKAlias *)newDocAlias {
  if (_docAlias != newDocAlias) {
    [_docAlias release];
    _docAlias = [newDocAlias retain];
  }
}

- (SKApplicationAlias *)appAlias {
  return [[_appAlias retain] autorelease];
}

- (void)setAppAlias:(SKApplicationAlias *)newAppAlias {
  if (_appAlias != newAppAlias) {
    [_appAlias release];
    _appAlias = [newAppAlias retain];
  }
}

@end

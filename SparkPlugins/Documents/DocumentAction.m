//
//  ApplicationAction.m
//  Spark
//
//  Created by Fox on Wed Dec 10 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "DocumentAction.h"
#import "DocumentActionPlugin.h"

#import <ShadowKit/SKAlias.h>
#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/ShadowAEUtils.h>

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
  copy->da_action = da_action;
  copy->da_docAlias = [da_docAlias copy];
  copy->da_appAlias = [da_appAlias copy];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:da_action forKey:kDocumentActionTypeKey];
  if (da_docAlias)
    [coder encodeObject:da_docAlias forKey:kDocumentActionDocumentKey];
  if (da_appAlias)
    [coder encodeObject:da_appAlias forKey:kDocumentActionApplicationKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    da_action = [coder decodeIntForKey:kDocumentActionTypeKey];
    da_docAlias = [[coder decodeObjectForKey:kDocumentActionDocumentKey] retain];
    da_appAlias = [[coder decodeObjectForKey:kDocumentActionApplicationKey] retain];
  }
  return self;
}

#pragma mark -
#pragma mark Required Methods.
- (id)initFromPropertyList:(id)plist {
  if (self = [super initFromPropertyList:plist]) {
    [self setDocAction:[[plist objectForKey:kDocumentActionTypeKey] intValue]];
    if (da_action == kDocumentActionOpen || da_action == kDocumentActionOpenWith) {
      [self setDocAlias:[SKAlias aliasWithData:[plist objectForKey:kDocumentActionDocumentKey]]];
    }
    if (da_action == kDocumentActionOpenWith || da_action == kDocumentActionOpenSelectionWith) {
      SKApplicationAlias *app = [SKApplicationAlias aliasWithData:[plist objectForKey:kDocumentActionApplicationKey]];
      if (![app path]) {
        [app setSignature:[[plist objectForKey:kDocumentActionSignKey] unsignedIntValue]];
      }
      [self setAppAlias:app];
    }
    if (da_action == kDocumentActionOpenURL) {
      [self setUrl:[plist objectForKey:kDocumentActionURLKey]];
    }
  }
  return self;
}

- (void)dealloc {
  [da_url release];
  [da_docAlias release];
  [da_appAlias release];
  [super dealloc];
}

- (NSMutableDictionary *)propertyList {
  id dico = [super propertyList];
  [dico setObject:SKInt(da_action) forKey:kDocumentActionTypeKey];
  if (da_action == kDocumentActionOpen || da_action == kDocumentActionOpenWith) {
    [dico setObject:[da_docAlias data] forKey:kDocumentActionDocumentKey];
  }
  if (da_action == kDocumentActionOpenWith || da_action == kDocumentActionOpenSelectionWith) {
    if (da_appAlias) {
      if ([da_appAlias signature])
        [dico setObject:SKUInt([da_appAlias signature]) forKey:kDocumentActionSignKey];
      id aliasData = [da_appAlias data];
      if (aliasData != nil)
        [dico setObject:aliasData forKey:kDocumentActionApplicationKey];
    }
  }
  if (da_action == kDocumentActionOpenURL) {
    if (da_url) {
      [dico setObject:da_url forKey:kDocumentActionURLKey];
    }
  }
  return dico;
}

- (SparkAlert *)check {
  id alert = nil;
  if (da_action == kDocumentActionOpen || da_action == kDocumentActionOpenWith) {
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
  if (da_action == kDocumentActionOpenWith || da_action == kDocumentActionOpenSelectionWith) {
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
    if (da_action == kDocumentActionOpen || da_action == kDocumentActionOpenWith) {
      if (![[NSWorkspace sharedWorkspace] openFile:[[self docAlias] path] withApplication:[[self appAlias] path]]) {
        NSBeep();
        // Impossible d'ouvrir le document (alert = ?)
      }
    } else if (da_action == kDocumentActionOpenSelection || da_action == kDocumentActionOpenSelectionWith) {
      // Check if Finder is foreground
      if ([self isFinderForeground]) {
        [self openSelection];
      }
    } else if (da_action == kDocumentActionOpenURL) {
      alert = [self openURL];
    }
  }
  return alert;
}

- (SparkAlert *)openURL {
  id alert = nil;
  if (![[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:da_url]]) {
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
  return da_action;
}

- (void)setDocAction:(DocumentActionType)newAction {
  da_action = newAction;
}


- (void)setDocPath:(NSString *)path {
  [self setDocAlias:[SKAlias aliasWithPath:path]];
}

- (void)setAppPath:(NSString *)path {
  id app = [SKApplicationAlias aliasWithPath:path];
  [self setAppAlias:([app path]) ? app : nil];
}

- (NSString *)url {
  return da_url;
}

- (void)setUrl:(NSString *)url {
  SKSetterRetain(da_url, url);
}

- (SKAlias *)docAlias {
  return da_docAlias;
}

- (void)setDocAlias:(SKAlias *)alias {
  SKSetterRetain(da_docAlias, alias);
}

- (SKApplicationAlias *)appAlias {
  return da_appAlias;
}

- (void)setAppAlias:(SKApplicationAlias *)alias {
  SKSetterRetain(da_appAlias, alias);
}

@end

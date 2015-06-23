/*
 *  DocumentAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "DocumentAction.h"

#import <Sparkkit/SparkPrivate.h>

#import <WonderBox/WBAlias.h>
#import <WonderBox/WBFunctions.h>
#import <WonderBox/WBAEFunctions.h>
#import <WonderBox/WBFinderSuite.h>
#import <WonderBox/WBLSFunctions.h>
#import <WonderBox/WBImageFunctions.h>
#import <WonderBox/NSImage+WonderBox.h>

static NSString * const kDocumentActionURLKey = @"DocumentURL";
static NSString * const kDocumentActionKey = @"DocumentAction";
static NSString * const kDocumentActionAliasKey = @"DocumentAlias";
/* NSCoding only */
static NSString * const kDocumentActionApplicationKey = @"DocumentApplication";

@implementation DocumentAction

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  DocumentAction* copy = [super copyWithZone:zone];
  copy->_action = _action;
  copy->_document = [_document copy];
  copy->_application = [_application copy];
  copy->_URL = _URL;
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:_action forKey:kDocumentActionKey];
  if (_URL)
    [coder encodeObject:_URL forKey:kDocumentActionURLKey];
  if (_document)
    [coder encodeObject:_document forKey:kDocumentActionAliasKey];
  if (_application)
    [coder encodeObject:_application forKey:kDocumentActionApplicationKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    _action = [coder decodeIntForKey:kDocumentActionKey];
    _URL = [coder decodeObjectForKey:kDocumentActionURLKey];
    _document = [coder decodeObjectForKey:kDocumentActionAliasKey];
    _application = [coder decodeObjectForKey:kDocumentActionApplicationKey];
  }
  return self;
}

#pragma mark -
#pragma mark Required Methods.
- (instancetype)init {
  if (self = [super init]) {
    [self setVersion:0x200];
  }
  return self;
}

WB_INLINE
OSType _DocumentActionFromFlag(int flag) {
  switch (flag) {
    case 0:
      return kDocumentActionOpen;
    case 1:
      return kDocumentActionOpenWith;
    case 2:
      return kDocumentActionOpenSelection;
    case 3:
      return kDocumentActionOpenSelectionWith;
    case 4:
      return kDocumentActionOpenURL;
    default:
      SPXDebug(@"Invalid Action: %d", flag);
  }
  return 0;
}

- (void)initFromOldPropertyList:(id)plist {
  [self setAction:_DocumentActionFromFlag([[plist objectForKey:@"DocAction"] intValue])];
  if (DocumentActionNeedDocument(_action)) {
    NSData *data = [plist objectForKey:@"DocAlias"];
    if (data)
      _document = [[WBAlias alloc] initFromData:data];
  }
  if (DocumentActionNeedApplication(_action)) {
    NSData *data = [plist objectForKey:@"AppAlias"];
    if (data) {
      NSURL *url = nil;
      WBAlias *app = [[WBAlias alloc] initFromData:data];
      if (![app path]) {
        /* Search with signature */
        OSType sign = WBOSTypeFromString([plist objectForKey:@"AppSign"]);
        if (sign)
          url = SPXCFToNSURL(WBLSCopyApplicationURLForSignature(sign));
      } else {
        url = app.URL;
      }
      if (url) {
        _application = [[WBAliasedApplication alloc] initWithPath:[url path]];
      }
    }
  }
  if (_action == kDocumentActionOpenURL) {
    [self setURL:[plist objectForKey:@"DocumentURL"]];
  }
  if (![self shouldSaveIcon]) {
    [self setIcon:nil];
  }
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    if ([self version] < 0x200) {
      [self initFromOldPropertyList:plist];
      [self setVersion:0x200];
    } else {
      [self setAction:WBOSTypeFromString([plist objectForKey:kDocumentActionKey])];
      
      if (DocumentActionNeedDocument(_action)) {
        NSData *data = [plist objectForKey:kDocumentActionAliasKey];
        if (data)
          _document = [[WBAlias alloc] initFromData:data];
      }
      
      if (DocumentActionNeedApplication(_action)) {
        _application = [[WBAliasedApplication alloc] initWithSerializedValues:plist];
      }
      
      if (_action == kDocumentActionOpenURL) {
        [self setURL:[plist objectForKey:kDocumentActionURLKey]];
      }
    }
    /* Update description */
    NSString *description = DocumentActionDescription(self);
    if (description)
      [self setActionDescription:description];
  }
  return self;
}

#pragma mark -
- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    [plist setObject:WBStringForOSType(_action) forKey:kDocumentActionKey];
    if (DocumentActionNeedDocument(_action)) {
      NSData *data = [_document data];
      if (data) {
        [plist setObject:data forKey:kDocumentActionAliasKey];
      } else {
        SPXDebug(@"Invalid document alias");
        return NO;
      }
    }
    if (DocumentActionNeedApplication(_action)) {
      if (![_application serialize:plist]) {
        SPXDebug(@"Invalid Open With Application.");
        return NO;
      }
    }
    if (_action == kDocumentActionOpenURL) {
      if (_URL) {
        [plist setObject:_URL forKey:kDocumentActionURLKey];
      } else {
        SPXDebug(@"Invalid Document URL");
        return NO;
      }
    }
  }
  return YES;
}

- (SparkAlert *)actionDidLoad {
  if (DocumentActionNeedDocument(_action)) {
    if (![[self document] path]) {
      //Alert Doc invalide
      return [SparkAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_DOCUMENT_ALERT", nil, 
                                                                                                            kDocumentActionBundle,
                                                                                                            @"Document not found * Check Title *"), [self name]]
                    informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_DOCUMENT_ALERT_MSG", nil, 
                                                                                 kDocumentActionBundle,
                                                                                 @"Document not found  * Check Msg *"), [self name]];
    }
  }
  if (DocumentActionNeedApplication(_action)) {
    if (![[self application] path]) {
      //Alert App Invalide
      return [SparkAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_APPLICATION_ALERT", nil, 
                                                                                                            kDocumentActionBundle,
                                                                                                            @"Application not found * Check Title *"), [self name]]
                    informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_APPLICATION_ALERT_MSG", nil, 
                                                                                 kDocumentActionBundle,
                                                                                 @"Application not found  * Check Msg *"), [self name]];
    }
  }
  return nil;
}

- (SparkAlert *)performAction {
  SparkAlert *alert = nil;
  switch (_action) {
    case kDocumentActionOpen:
    case kDocumentActionOpenWith: {
      if (![[NSWorkspace sharedWorkspace] openFile:[[self document] path] withApplication:[[self application] path]]) {
        NSBeep();
        // Impossible d'ouvrir le document (alert = ?)
      }
    }
      break;
    case kDocumentActionOpenSelection:
    case kDocumentActionOpenSelectionWith: {
      // Check if Finder is foreground
      if ([[NSWorkspace sharedWorkspace].frontmostApplication.bundleIdentifier isEqualTo:kSparkFinderBundleIdentifier])
        [self openSelection];
    }
      break;
    case kDocumentActionOpenURL: {
      if (![[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:_URL]]) {
        NSBeep();
        /* alert = []; */
      }
    }
      break;
    case kDocumentActionReveal: {
      AliasHandle alias = [[self document] aliasHandle];
      if (alias) {
        AEDesc desc = WBAEEmptyDesc();
        OSStatus err = WBAECreateDescFromAlias(alias, &desc);
        if (noErr == err) {
          err = WBAEFinderRevealItem(&desc, TRUE);
          WBAEDisposeDesc(&desc);
        }
        
        if (noErr != err)
          NSBeep();
      } else {
        NSBeep();
      }
    }
      break;
      
    default:
      NSBeep();
  }
  return alert;
}

- (BOOL)shouldSaveIcon {
  switch ([self action]) {
    case kDocumentActionOpenSelection:
    case kDocumentActionOpenURL:
      return NO;
    default:
      return YES;
  }
}
/* Icon lazy loading */
- (NSImage *)icon {
  NSImage *icon = [super icon];
  if (!icon) {
    icon = DocumentActionIcon(self);
    [super setIcon:icon];
  }
  return icon;
}

- (NSImage *)iconCacheMiss {
  NSImage *icon = nil;
  if (DocumentActionNeedDocument([self action])) {
    if ([[self document] path])
      icon = [[NSWorkspace sharedWorkspace] iconForFile:[[self document] path]];
  } else if([self action] == kDocumentActionOpenSelectionWith) {
    icon = [[self application] icon];
  }
  if (icon)
    WBImageSetRepresentationsSize(icon, NSMakeSize(16, 16));
  return icon;
}

#pragma mark -
- (void)openSelection {
  AEDescList selection = {typeNull, nil};
  long count = 0;
  
  // Get Finder Selection.
  OSStatus err = WBAEFinderGetSelection(&selection);
  if (noErr == err) {
    // Get selection Count
    err = AECountItems(&selection, &count);
  }
  if (noErr == err && count > 0) {
    // if selected items
    CFIndex realCount;
    FSRef *refs = malloc(count * sizeof(FSRef));
    // Get FSRef for these items.
    err = WBAEFinderSelectionToFSRefs(&selection , refs, count, &realCount);
    if (noErr == err && realCount > 0) {
      FSRef app;
      LSLaunchFSRefSpec spec;
      
      if ([[self application] getFSRef:&app]) {
        spec.appRef = &app;
      } else {
        spec.appRef = nil;
      }
      
      spec.numDocs = realCount;
      spec.itemRefs = refs;
      spec.passThruParams = nil;
      spec.launchFlags = kLSLaunchDefaults;
      spec.asyncRefCon = nil;
      LSOpenFromRefSpec(&spec, nil);
    }
    free(refs);
  }
  WBAEDisposeDesc(&selection);
}

- (void)setDocumentPath:(NSString *)path {
  if (path)
    [self setDocument:[WBAlias aliasWithPath:path]];
  else
    [self setDocument:nil];
}

- (void)setApplicationPath:(NSString *)path {
  if (path)
    [self setApplication:[WBAliasedApplication applicationWithPath:path]];
  else
    [self setApplication:nil];
}

@end

NSImage *DocumentActionIcon(DocumentAction *anAction) {
  NSString *name = nil;
  switch ([anAction action]) {
    case kDocumentActionOpenSelection:
      name = @"DocSelection";
      break;
    case kDocumentActionOpenURL:
      name = @"DocURL";
      break;
    default:
      break;
  }
  if (name)
    return [NSImage imageNamed:name inBundle:kDocumentActionBundle];
  return nil;
}

NSString *DocumentActionDescription(DocumentAction *anAction) {
  NSString *desc = nil;
  switch ([anAction action]) {
    case kDocumentActionOpen: {
      NSString *path = [[anAction document] path];
      NSString *document = path ? [[NSFileManager defaultManager] displayNameAtPath:path] : nil;
      desc = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_OPEN", nil,
                                                                           kDocumentActionBundle,
                                                                           @"Open (%@ => document) * description *"), document];
    }
      break;
    case kDocumentActionOpenWith: {
      NSString *path = [[anAction document] path];
      NSString *document = path ? [[NSFileManager defaultManager] displayNameAtPath:path] : nil;
      desc = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_OPEN_WITH", nil,
                                                                           kDocumentActionBundle,
                                                                           @"Open with (%1$@ => document, %2$@ => application) * description *"),
        document, [[anAction application] name]];
    }
      break;
    case kDocumentActionReveal: {
      NSString *path = [[anAction document] path];
      NSString *document = path ? [[NSFileManager defaultManager] displayNameAtPath:path] : nil;
      desc = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_REVEAL_DOCUMENT", nil,
                                                                           kDocumentActionBundle,
                                                                           @"Open with (%@ => document) * description *"), document];
    }
      break;
    case kDocumentActionOpenSelection:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_OPEN_SELECTION", nil, 
                                                kDocumentActionBundle,
                                                @"Open Selection * description *");
      break;
    case kDocumentActionOpenSelectionWith:
      desc = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_OPEN_SELECTION_WITH", nil, 
                                                                           kDocumentActionBundle,
                                                                           @"Open Selection with (%@ => application) * description *"), [[anAction application] name]];
      break;
    case kDocumentActionOpenURL:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_OPEN_URL", nil, 
                                                kDocumentActionBundle,
                                                @"Open URL * description *");
      break;
    default:
      desc = @"<Invalid Action>";
  }
  return desc;
}



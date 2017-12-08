/*
 *  DocumentAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "DocumentAction.h"

#import <Sparkkit/SparkPrivate.h>

#import <WonderBox/WonderBox.h>

static NSString * const kDocumentActionURLKey = @"DocumentURL";
static NSString * const kDocumentActionKey = @"DocumentAction";
static NSString * const kDocumentActionBookmarkKey = @"DocumentBookmark";

/* NSCoding only */
static NSString * const kDocumentActionApplicationKey = @"DocumentApplication";

NSBundle *DocumentActionBundle(void) {
  static NSBundle *bundle = nil;
  if (!bundle)
    bundle = [NSBundle bundleWithIdentifier:@"org.shadowlab.spark.action.document"];
  return bundle;
}

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
    [coder encodeObject:_document forKey:kDocumentActionBookmarkKey];
  if (_application)
    [coder encodeObject:_application forKey:kDocumentActionApplicationKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    _action = [coder decodeIntForKey:kDocumentActionKey];
    _URL = [coder decodeObjectForKey:kDocumentActionURLKey];
    _document = [coder decodeObjectForKey:kDocumentActionBookmarkKey];
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
static inline WBAlias *AliasWithData(NSData *data) {
  return [[WBAlias alloc] initFromData:data];
}
#pragma clang diagnostic pop

- (void)initFromOldPropertyList:(id)plist {
  [self setAction:_DocumentActionFromFlag([[plist objectForKey:@"DocAction"] intValue])];
  if (DocumentActionNeedDocument(_action)) {
    NSData *data = [plist objectForKey:@"DocAlias"];
    if (data)
      _document = AliasWithData(data);
  }
  if (DocumentActionNeedApplication(_action)) {
    NSData *data = [plist objectForKey:@"AppAlias"];
    if (data) {
      WBAlias *app = AliasWithData(data);
      NSURL *url = app.URL;
      if (url)
        _application = [[WBApplication alloc] initWithURL:url];
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
        NSData *data = plist[kDocumentActionBookmarkKey];
        if (data)
          _document = [[WBAlias alloc] initFromBookmarkData:data];
        else if ((data = plist[@"DocumentAlias"]))
          _document = AliasWithData(data);
      }
      
      if (DocumentActionNeedApplication(_action)) {
        _application = WBApplicationFromSerializedValues(plist);
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
        [plist setObject:data forKey:kDocumentActionBookmarkKey];
      } else {
        SPXDebug(@"Invalid document alias");
        return NO;
      }
    }
    if (DocumentActionNeedApplication(_action)) {
      if (!WBApplicationSerialize(_application, plist)) {
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
    if (![[self document] URL]) {
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
    if (!self.application.URL) {
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
      NSURL *doc = self.document.URL;
      if (!doc || ![NSWorkspace.sharedWorkspace openURLs:@[doc]
                                 withAppBundleIdentifier:self.application.bundleIdentifier
                                                 options:NSWorkspaceLaunchDefault
                          additionalEventParamDescriptor:nil
                                       launchIdentifiers:NULL]) {
        // Impossible d'ouvrir le document (alert = ?)
        NSBeep();
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
      NSURL *alias = self.document.URL;
      if (alias) {
        [NSWorkspace.sharedWorkspace activateFileViewerSelectingURLs:@[ alias ]];
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
    [self.document.URL getResourceValue:&icon forKey:NSURLEffectiveIconKey error:NULL];
  } else if([self action] == kDocumentActionOpenSelectionWith) {
    icon = [[self application] icon];
  }
  if (icon)
    WBImageSetRepresentationsSize(icon, NSMakeSize(16, 16));
  return icon;
}

#pragma mark -
- (void)openSelection {
  NSArray *selection = SPXCFArrayBridgingRelease(WBAEFinderCopySelection());
  if ([selection count] <= 0 || ![NSWorkspace.sharedWorkspace openURLs:selection
                                               withAppBundleIdentifier:self.application.bundleIdentifier
                                                               options:NSWorkspaceLaunchDefault
                                        additionalEventParamDescriptor:nil
                                                     launchIdentifiers:NULL]) {
    NSBeep();
  }
}

- (void)setDocumentURL:(NSURL *)anURL {
  if (anURL)
    [self setDocument:[WBAlias aliasWithURL:anURL]];
  else
    [self setDocument:nil];
}

- (void)setApplicationURL:(NSURL *)anURL {
  if (anURL)
    [self setApplication:[WBApplication applicationWithURL:anURL]];
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
      NSString *document = nil;
      [anAction.document.URL getResourceValue:&document forKey:NSURLLocalizedNameKey error:NULL];
      desc = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_OPEN", nil,
                                                                           kDocumentActionBundle,
                                                                           @"Open (%@ => document) * description *"), document];
    }
      break;
    case kDocumentActionOpenWith: {
      NSString *document = nil;
      [anAction.document.URL getResourceValue:&document forKey:NSURLLocalizedNameKey error:NULL];
      desc = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_OPEN_WITH", nil,
                                                                           kDocumentActionBundle,
                                                                           @"Open with (%1$@ => document, %2$@ => application) * description *"),
        document, [[anAction application] name]];
    }
      break;
    case kDocumentActionReveal: {
      NSString *document = nil;
      [anAction.document.URL getResourceValue:&document forKey:NSURLLocalizedNameKey error:NULL];
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



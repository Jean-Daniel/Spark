//
//  ApplicationAction.m
//  Spark
//
//  Created by Fox on Wed Dec 10 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "DocumentAction.h"

#import <SparkKit/SparkShadowKit.h>

#import <ShadowKit/SKAlias.h>
#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKAEFunctions.h>
#import <ShadowKit/SKProcessFunctions.h>

static NSString * const kDocumentActionURLKey = @"DocumentURL";
static NSString * const kDocumentActionKey = @"DocumentAction";
static NSString * const kDocumentActionAliasKey = @"DocumentAlias";
/* NSCoding only */
static NSString * const kDocumentActionApplicationKey = @"DocumentApplication";

NSString * const kDocumentActionBundleIdentifier = @"org.shadowlab.spark.document";

@implementation DocumentAction

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  DocumentAction* copy = [super copyWithZone:zone];
  copy->da_action = da_action;
  copy->da_doc = [da_doc copy];
  copy->da_app = [da_app copy];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:da_action forKey:kDocumentActionKey];
  if (da_doc)
    [coder encodeObject:da_doc forKey:kDocumentActionAliasKey];
  if (da_app)
    [coder encodeObject:da_app forKey:kDocumentActionApplicationKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    da_action = [coder decodeIntForKey:kDocumentActionKey];
    da_doc = [[coder decodeObjectForKey:kDocumentActionAliasKey] retain];
    da_app = [[coder decodeObjectForKey:kDocumentActionApplicationKey] retain];
  }
  return self;
}

#pragma mark -
#pragma mark Required Methods.
- (id)init {
  if (self = [super init]) {
    [self setVersion:0x200];
  }
  return self;
}

SK_INLINE
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
      DLog(@"Invalid Action: %ld", flag);
  }
  return 0;
}

- (void)initFromOldPropertyList:(id)plist {
  [self setAction:_DocumentActionFromFlag([[plist objectForKey:@"DocAction"] intValue])];
  if (da_action == kDocumentActionOpen || da_action == kDocumentActionOpenWith) {
    NSData *data = [plist objectForKey:@"DocAlias"];
    if (data)
      da_doc = [[SKAlias alloc] initWithData:data];
  }
  if (da_action == kDocumentActionOpenWith || da_action == kDocumentActionOpenSelectionWith) {
    NSData *data = [plist objectForKey:@"AppAlias"];
    if (data) {
      SKAlias *app = [[SKAlias alloc] initWithData:data];
      if ([app path]) {
        da_app = [[SKAliasedApplication alloc] initWithPath:[app path]];
      }
      [app release];
    }
  }
  if (da_action == kDocumentActionOpenURL) {
    [self setURL:[plist objectForKey:@"DocumentURL"]];
  }
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    if ([self version] < 0x200) {
      [self initFromOldPropertyList:plist];
      [self setVersion:0x200];
    } else {
      [self setAction:SKOSTypeFromString([plist objectForKey:kDocumentActionKey])];
      
      if (da_action == kDocumentActionOpen || da_action == kDocumentActionOpenWith) {
        NSData *data = [plist objectForKey:kDocumentActionAliasKey];
        if (data)
          da_doc = [[SKAlias alloc] initWithData:data];
      }
      
      if (da_action == kDocumentActionOpenWith || da_action == kDocumentActionOpenSelectionWith) {
        da_app = [[SKAliasedApplication alloc] initWithSerializedValues:plist];
      }
      
      if (da_action == kDocumentActionOpenURL) {
        [self setURL:[plist objectForKey:kDocumentActionURLKey]];
      }
    }
  }
  return self;
}

- (void)dealloc {
  [da_url release];
  [da_doc release];
  [da_app release];
  [super dealloc];
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    [plist setObject:SKStringForOSType(da_action) forKey:kDocumentActionKey];
    if (da_action == kDocumentActionOpen || da_action == kDocumentActionOpenWith) {
      NSData *data = [da_doc data];
      if (data) {
        [plist setObject:data forKey:kDocumentActionAliasKey];
      } else {
        DLog(@"Invalid document alias");
        return NO;
      }
    }
    if (da_action == kDocumentActionOpenWith || da_action == kDocumentActionOpenSelectionWith) {
      if (![da_app serialize:plist]) {
        DLog(@"Invalid Open With Application.");
        return NO;
      }
    }
    if (da_action == kDocumentActionOpenURL) {
      if (da_url) {
        [plist setObject:da_url forKey:kDocumentActionURLKey];
      } else {
        DLog(@"Invalid Document URL");
        return NO;
      }
    }
  }
  return YES;
}

- (SparkAlert *)check {
  id alert = nil;
//  if (da_action == kDocumentActionOpen || da_action == kDocumentActionOpenWith) {
//    if ([[self docAlias] path] == nil) {
//      //Alert Doc invalide
//      alert = [SparkAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_DOCUMENT_ALERT", nil, 
//                                                                                                             kDocumentActionBundle,
//                                                                                                             @"Document not found * Check Title *"), [self name]]
//                     informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_DOCUMENT_ALERT_MSG", nil, 
//                                                                                  kDocumentActionBundle,
//                                                                                  @"Document not found  * Check Msg *"), [self name]];
//    }
//  }
//  if (da_action == kDocumentActionOpenWith || da_action == kDocumentActionOpenSelectionWith) {
//    if ([[self appAlias] path] == nil) {
//      //Alert App Invalide
//      alert = [SparkAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_APPLICATION_ALERT", nil, 
//                                                                                                             kDocumentActionBundle,
//                                                                                                             @"Application not found * Check Title *"), [self name]]
//                     informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_APPLICATION_ALERT_MSG", nil, 
//                                                                                  kDocumentActionBundle,
//                                                                                  @"Application not found  * Check Msg *"), [self name]];
//    }
//  }
  return alert;
}

- (SparkAlert *)execute {
  id alert = [self check];
  if (alert == nil) {
    if (da_action == kDocumentActionOpen || da_action == kDocumentActionOpenWith) {
      if (![[NSWorkspace sharedWorkspace] openFile:[[self document] path] withApplication:[[self application] path]]) {
        NSBeep();
        // Impossible d'ouvrir le document (alert = ?)
      }
    } else if (da_action == kDocumentActionOpenSelection || da_action == kDocumentActionOpenSelectionWith) {
      // Check if Finder is foreground
      if (SKProcessGetFrontProcessSignature() == 'MACS') {
        [self openSelection];
      }
    } else if (da_action == kDocumentActionOpenURL) {
      if (![[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:da_url]]) {
        NSBeep();
        /* alert = []; */
      }
    }
  }
  return alert;
}

- (void)openSelection {
  AEDescList selection = {typeNull, nil};
  long count = 0;
  
  // Get Finder Selection.
  OSStatus err = SKAEGetFinderSelection(&selection);
  if (noErr == err) {
    // Get selection Count
    err = AECountItems(&selection, &count);
  }
  if (noErr == err && count > 0) {
    // if selected items
    int realCount;
    FSRef *refs = NSZoneCalloc(nil, count, sizeof(FSRef));
    // Get FSRef for these items.
    err = SKAEFinderSelectionToFSRefs(&selection , refs, count, &realCount);
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
    NSZoneFree(nil, refs);
  }
  SKAEDisposeDesc(&selection);
}

- (int)action {
  return da_action;
}
- (void)setAction:(int)newAction {
  da_action = newAction;
}

- (void)setDocumentPath:(NSString *)path {
  if (path)
    [self setDocument:[SKAlias aliasWithPath:path]];
  else
    [self setDocument:nil];
}

- (void)setApplicationPath:(NSString *)path {
  if (path)
    [self setApplication:[SKAliasedApplication applicationWithPath:path]];
  else
    [self setApplication:nil];
}

- (NSString *)url {
  return da_url;
}
- (void)setURL:(NSString *)url {
  SKSetterRetain(da_url, url);
}

- (SKAlias *)document {
  return da_doc;
}
- (void)setDocument:(SKAlias *)alias {
  SKSetterRetain(da_doc, alias);
}

- (SKAliasedApplication *)application {
  return da_app;
}
- (void)setApplication:(SKAliasedApplication *)anApplication {
  SKSetterRetain(da_app, anApplication);
}

@end

NSString *DocumentActionDescription(DocumentAction *anAction, NSString *document, NSString *application) {
  NSString *desc = nil;
  switch ([anAction action]) {
    case kDocumentActionOpen:
      desc = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_OPEN", nil,
                                                                           kDocumentActionBundle,
                                                                           @"Open * description *"), document];
      break;
    case kDocumentActionOpenWith:
      desc = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_OPEN_WITH", nil,
                                                                           kDocumentActionBundle,
                                                                           @"Open with (%$1@ => document, %$2@ => application) * description *"), 
        document, application];
      break;
    case kDocumentActionOpenSelection:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_OPEN_SELECTION", nil, 
                                                kDocumentActionBundle,
                                                @"Open Selection * description *");
      break;
    case kDocumentActionOpenSelectionWith:
      desc = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESC_OPEN_SELECTION_WITH", nil, 
                                                                           kDocumentActionBundle,
                                                                           @"Open Selection with (%@ => application) * description *"), application];
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



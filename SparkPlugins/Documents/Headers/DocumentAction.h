/*
 *  DocumentAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>

enum {
  kDocumentActionOpen              = 'Open', /* 1332766062 */
  kDocumentActionReveal            = 'Reva', /* 1382381153 */
  kDocumentActionOpenWith          = 'OpWi', /* 1332762473 */
  kDocumentActionOpenSelection     = 'OpSe', /* 1332761445 */
  kDocumentActionOpenSelectionWith = 'OpSW', /* 1332761431 */
  kDocumentActionOpenURL           = 'OURL', /* 1330991692 */
};

#define kDocumentActionBundleIdentifier @"org.shadowlab.spark.action.document"
#define kDocumentActionBundle		    [NSBundle bundleWithIdentifier:kDocumentActionBundleIdentifier]

@class WBAlias, WBAliasedApplication;
@interface DocumentAction : SparkAction <NSCoding, NSCopying> {
  int da_action;
  WBAlias *da_doc;
  NSString *da_url;
  WBAliasedApplication *da_app;
}

- (int)action;
- (void)setAction:(int)anAction;

- (void)setDocumentPath:(NSString *)path;
- (void)setApplicationPath:(NSString *)path;

- (NSString *)url;
- (void)setURL:(NSString *)url;

- (WBAlias *)document;
- (void)setDocument:(WBAlias *)aDoc;
- (WBAliasedApplication *)application;
- (void)setApplication:(WBAliasedApplication *)anApplication;

- (void)openSelection;

@end

SPARK_PRIVATE
NSImage *DocumentActionIcon(DocumentAction *anAction);
WB_PRIVATE
NSString *DocumentActionDescription(DocumentAction *anAction);

WB_INLINE
BOOL DocumentActionNeedDocument(int act) {
  switch (act) {
    case kDocumentActionOpen:
    case kDocumentActionReveal:
    case kDocumentActionOpenWith:
      return YES;
  }
  return NO;
}

WB_INLINE
BOOL DocumentActionNeedApplication(int act) {
  switch (act) {
    case kDocumentActionOpenWith:
    case kDocumentActionOpenSelectionWith:
      return YES;
  }
  return NO;
}

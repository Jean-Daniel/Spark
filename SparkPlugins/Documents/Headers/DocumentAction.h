/*
 *  DocumentAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

typedef NS_ENUM(uint32_t, DocumentActionType) {
  kDocumentActionOpen              = 'Open', /* 1332766062 */
  kDocumentActionReveal            = 'Reva', /* 1382381153 */
  kDocumentActionOpenWith          = 'OpWi', /* 1332762473 */
  kDocumentActionOpenSelection     = 'OpSe', /* 1332761445 */
  kDocumentActionOpenSelectionWith = 'OpSW', /* 1332761431 */
  kDocumentActionOpenURL           = 'OURL', /* 1330991692 */
};

SPARK_PRIVATE
NSBundle *DocumentActionBundle(void);

#define kDocumentActionBundle	DocumentActionBundle()

@class WBAlias, WBApplication;
@interface DocumentAction : SparkAction <NSCoding, NSCopying>

- (void)setDocumentURL:(NSURL *)anURL;
- (void)setApplicationURL:(NSURL *)anURL;

@property(nonatomic) DocumentActionType action;

@property(nonatomic, retain) NSString *URL;
@property(nonatomic, retain) WBAlias *document;
@property(nonatomic, retain) WBApplication *application;

- (void)openSelection;

@end

SPARK_PRIVATE
NSImage *DocumentActionIcon(DocumentAction *anAction);
SPARK_PRIVATE
NSString *DocumentActionDescription(DocumentAction *anAction);

SPARK_INLINE
BOOL DocumentActionNeedDocument(DocumentActionType act) {
  switch (act) {
    case kDocumentActionOpen:
    case kDocumentActionReveal:
    case kDocumentActionOpenWith:
      return YES;
    default:
      return NO;
  }
}

SPARK_INLINE
BOOL DocumentActionNeedApplication(DocumentActionType act) {
  switch (act) {
    case kDocumentActionOpenWith:
    case kDocumentActionOpenSelectionWith:
      return YES;
    default:
      return NO;
  }
}

//
//  ApplicationAction.h
//  Spark
//
//  Created by Fox on Wed Dec 10 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit_API.h>

typedef enum {
  kDocumentActionOpen,
  kDocumentActionOpenWith,
  kDocumentActionOpenSelection,
  kDocumentActionOpenSelectionWith,
  kDocumentActionOpenURL
} DocumentActionType;

@class SKAlias, SKApplicationAlias;
@interface DocumentAction : SparkAction <NSCoding, NSCopying> {
  DocumentActionType _docAction;
  NSString *_url;
  SKAlias *_docAlias;
  SKApplicationAlias *_appAlias;
}

- (DocumentActionType)docAction;
- (void)setDocAction:(DocumentActionType)newAction;

- (void)setDocPath:(NSString *)path;
- (void)setAppPath:(NSString *)path;

- (NSString *)url;
- (void)setUrl:(NSString *)url;

- (SKAlias *)docAlias;
- (void)setDocAlias:(SKAlias *)newDocAlias;
- (SKApplicationAlias *)appAlias;
- (void)setAppAlias:(SKApplicationAlias *)newAppAlias;

- (BOOL)isFinderForeground;
- (void)openSelection;
- (SparkAlert *)openURL;

@end
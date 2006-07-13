//
//  ApplicationAction.h
//  Spark
//
//  Created by Fox on Wed Dec 10 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkPluginAPI.h>

typedef enum {
  kDocumentActionOpen,
  kDocumentActionOpenWith,
  kDocumentActionOpenSelection,
  kDocumentActionOpenSelectionWith,
  kDocumentActionOpenURL
} DocumentActionType;

@class SKAlias, SKApplicationAlias;
@interface DocumentAction : SparkAction <NSCoding, NSCopying> {
  DocumentActionType da_action;
  NSString *da_url;
  SKAlias *da_docAlias;
  SKApplicationAlias *da_appAlias;
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

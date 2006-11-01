//
//  ApplicationAction.h
//  Spark
//
//  Created by Fox on Wed Dec 10 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkPluginAPI.h>

enum {
  kDocumentActionOpen,
  kDocumentActionOpenWith,
  kDocumentActionOpenSelection,
  kDocumentActionOpenSelectionWith,
  kDocumentActionOpenURL
};

SPARK_PRIVATE
NSString * const kDocumentActionBundleIdentifier;

#define kDocumentActionBundle		[NSBundle bundleWithIdentifier:kDocumentActionBundleIdentifier]

@class SKAlias, SKApplication;
@interface DocumentAction : SparkAction <NSCoding, NSCopying> {
  int da_action;
  SKAlias *da_doc;
  NSString *da_url;
  SKApplication *da_app;
}

- (int)action;
- (void)setAction:(int)anAction;

- (void)setDocumentPath:(NSString *)path;
- (void)setApplicationPath:(NSString *)path;

- (NSString *)url;
- (void)setURL:(NSString *)url;

- (SKAlias *)document;
- (void)setDocument:(SKAlias *)aDoc;
- (SKApplication *)application;
- (void)setApplication:(SKApplication *)anApplication;

- (void)openSelection;

@end

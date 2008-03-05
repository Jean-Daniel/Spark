//
//  SEHTMLGenerator.h
//  Spark Editor
//
//  Created by Grayfox on 28/10/07.
//  Copyright 2007 Shadow Lab. All rights reserved.
//

@class SELibraryDocument;
@interface SEHTMLGenerator : NSObject {
  @private
  NSInteger se_group;
	BOOL se_icons, se_strike;
  SELibraryDocument *se_doc;
}

- (id)initWithDocument:(SELibraryDocument *)document;

- (BOOL)strikeDisabled;
- (void)setStrikeDisabled:(BOOL)flag;

- (BOOL)includesIcon;
- (void)setIncludesIcons:(BOOL)flag;

- (NSInteger)groupBy;
- (void)setGroupBy:(NSInteger)group;

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile error:(NSError **)error;

- (NSString *)imageTagForImage:(NSImage *)image size:(NSSize)size;

@end

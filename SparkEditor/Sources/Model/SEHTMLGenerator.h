//
//  SEHTMLGenerator.h
//  Spark Editor
//
//  Created by Grayfox on 28/10/07.
//  Copyright 2007 Shadow Lab. All rights reserved.
//

@class SELibraryDocument;
@interface SEHTMLGenerator : NSObject

- (instancetype)initWithDocument:(SELibraryDocument *)document;

@property(nonatomic) BOOL strikeDisabled;

@property(nonatomic) BOOL includesIcons;

@property(nonatomic) NSInteger groupBy;

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile error:(__autoreleasing NSError **)error;

- (NSString *)imageTagForImage:(NSImage *)image size:(NSSize)size;

@end

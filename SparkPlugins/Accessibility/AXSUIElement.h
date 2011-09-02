//
//  AXSUIElement.h
//  NeoLab
//
//  Created by Jean-Daniel Dupas on 27/11/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

@interface AXSUIElement : NSObject {
@private
  AXUIElementRef ax_elt;
}

- (id)initWithElement:(AXUIElementRef)anElement;

- (AXUIElementRef)element;

- (NSString *)role;

#pragma mark Attributes
- (NSArray *)attributeNames;
- (id)valueForAttribute:(NSString *)anAttribute;
- (BOOL)setValue:(id)aValue forAttribute:(NSString *)anAttribute;

- (NSUInteger)countOfValuesForAttribute:(NSString *)anAttribute;

- (NSArray *)valuesForAttribute:(NSString *)anAttribute;
- (NSArray *)valuesForAttribute:(NSString *)anAttribute range:(NSRange)aRange;

#pragma mark Actions
- (NSArray *)actionNames;
- (BOOL)performAction:(NSString *)anAction;
- (NSString *)actionDescription:(NSString *)anAction;

@end


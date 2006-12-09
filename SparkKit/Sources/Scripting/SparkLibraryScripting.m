/*
 *  SparkLibraryScripting.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkObject.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkLibrary.h>

#import <ShadowKit/SKFSFunctions.h>

/*
@implementation NSString (SparkScripting)

- (NSAppleEventDescriptor *)_scriptingFileDescriptor {
  FSRef ref;
  if ([self getFSRef:&ref]) {
    NSAppleEventDescriptor *desc = [[NSAppleEventDescriptor alloc] initWithDescriptorType:typeFSRef
                                                                                    bytes:&ref
                                                                                   length:sizeof(ref)];
    return [desc autorelease];
  } 
  return nil;
}

@end
*/

@implementation SparkLibrary (SparkLibraryScripting)

- (NSURL *)location {
  return [NSURL fileURLWithPath:[self path]];
}

- (NSScriptObjectSpecifier *)objectSpecifier {
  if (SparkSharedLibrary() == self) {
    id containerClassDesc = [NSScriptClassDescription classDescriptionForClass:[NSApp class]];
    return [[[NSPropertySpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                        containerSpecifier:nil 
                                                                       key:@"contents"] autorelease];
  }
  return nil;
}

@end


@implementation SparkObject (SparkLibraryScripting)

- (NSString *)scriptingKey {
  return nil;
}

- (NSScriptObjectSpecifier *)objectSpecifier {
  NSScriptObjectSpecifier *containerRef = [[self library] objectSpecifier];
  return [[[NSUniqueIDSpecifier alloc]    
            initWithContainerClassDescription:[containerRef keyClassDescription] 
                           containerSpecifier:containerRef
                                          key:[self scriptingKey]
                                     uniqueID:SKUInt([self uid])] autorelease];
}

@end

@implementation SparkAction (SparkLibraryScripting)

- (NSString *)scriptingKey {
  return @"actions";
}

@end

@implementation SparkTrigger (SparkLibraryScripting)

- (NSString *)scriptingKey {
  return @"triggers";
}

@end

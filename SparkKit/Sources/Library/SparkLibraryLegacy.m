//
//  SparkLibraryLegacy.m
//  SparkKit
//
//  Created by Grayfox on 01/12/07.
//  Copyright 2007 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkLibrary.h>

#import <SparkKit/SparkPrivate.h>

#import "SparkEntryPrivate.h"
#import "SparkLibraryPrivate.h"
#import "SparkEntryManagerPrivate.h"

#import <SparkKit/SparkList.h>
#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkEntryManager.h>

#import <ShadowKit/SKCFContext.h>
#import <ShadowKit/SKSerialization.h>
#import <ShadowKit/SKAppKitExtensions.h>

#pragma mark -
#pragma mark Placeholder
@interface SparkEntryPlaceholder : NSObject {
  @private
  BOOL sp_enabled;
  
  SparkUID sp_action;
  SparkUID sp_trigger;
  SparkUID sp_application;
}

- (id)initWithActionUID:(SparkUID)act triggerUID:(SparkUID)trg applicationUID:(SparkUID)app;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

- (SparkUID)actionUID;
- (SparkUID)triggerUID;
- (SparkUID)applicationUID;

- (void)setActionUID:(SparkUID)action;
- (void)setTriggerUID:(SparkUID)trigger;
- (void)setApplicationUID:(SparkUID)application;

- (SparkEntry *)newEntryWithLibrary:(SparkLibrary *)aLibrary;

@end

#pragma mark -
@implementation SparkEntryPlaceholder

- (id)initWithActionUID:(SparkUID)act triggerUID:(SparkUID)trg applicationUID:(SparkUID)app {
  if (self = [super init]) {
    [self setActionUID:act];
    [self setTriggerUID:trg];
    [self setApplicationUID:app];
  }
  return self;
}

- (BOOL)isEnabled {
  return sp_enabled;
}
- (void)setEnabled:(BOOL)flag {
  sp_enabled = flag;
}

- (SparkUID)actionUID {
  return sp_action;
}
- (SparkUID)triggerUID {
  return sp_trigger;
}
- (SparkUID)applicationUID {
  return sp_application;
}

- (void)setActionUID:(SparkUID)action {
  sp_action = action;
}
- (void)setTriggerUID:(SparkUID)trigger {
  sp_trigger = trigger;
}
- (void)setApplicationUID:(SparkUID)application {
  sp_application = application;
}

- (SparkEntry *)newEntryWithLibrary:(SparkLibrary *)aLibrary {
  SparkAction *act = [aLibrary actionWithUID:sp_action];
  SparkTrigger *trg = [aLibrary triggerWithUID:sp_trigger];
  SparkApplication *app = [aLibrary applicationWithUID:sp_application];
  
  SparkEntry *entry = [SparkEntry entryWithAction:act trigger:trg application:app];
  [entry setEnabled:[self isEnabled]];
  return entry;
}

@end

@implementation SparkLibrary (SparkLegacyReader)

- (BOOL)importv1LibraryFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)error {
  DLog(@"Loading Version 1.0 Library");
  /* Load HotKey items. Create trigger with internal values, and create entries with Application to Action Map */
  CFMutableSetRef actions = CFSetCreateMutable( kCFAllocatorDefault, 0, &kSKIntegerSetCallBacks);
  
  SparkUID finder = 0;
  NSArray *objects = nil;
  NSDictionary *plist = nil;
  NSEnumerator *enumerator = nil;
  SparkObjectSet *objectSet = nil;
  NSMutableArray *placeholders = [[NSMutableArray alloc] init];
  
  /* Load Applications. Ignore old '_SparkSystemApplication' items */
  objectSet = [self applicationSet];
  
  objects = [[wrapper propertyListForFilename:@"SparkApplications"] objectForKey:@"SparkObjects"];
  enumerator = [objects objectEnumerator];
  while (plist = [enumerator nextObject]) {
    NSString *class = [plist objectForKey:@"isa"];
    if (![class isEqualToString:@"_SparkSystemApplication"]) {
      SparkApplication *app = SKDeserializeObject(plist, nil);
      if (app && [app isKindOfClass:[SparkApplication class]]) {
        if ([app signature] == kSparkFinderSignature) {
          finder = [app uid];
          [app setUID:kSparkApplicationFinderUID];
        } else {
          [app setUID:[app uid] + kSparkLibraryReserved];
          [objectSet addObject:app];
        }
      } else {
        DLog(@"Discard invalid application: %@", app);
      }
    }
  }  
  
  objects = [[wrapper propertyListForFilename:@"SparkKeys"] objectForKey:@"SparkObjects"];
  enumerator = [objects objectEnumerator];
  objectSet = [self triggerSet];
  while (plist = [enumerator nextObject]) {
    SparkTrigger *trigger = SKDeserializeObject(plist, nil);      
    if (trigger && [trigger isKindOfClass:[SparkTrigger class]]) {
      [trigger setName:nil];
      [trigger setIcon:nil];
      [trigger setUID:[trigger uid] + kSparkLibraryReserved];
      [objectSet addObject:trigger];
      
      NSString *key;
      UInt32 status = [[plist objectForKey:@"IsActive"] unsignedIntValue];
      NSDictionary *map = [[plist objectForKey:@"ApplicationMap"] objectForKey:@"ApplicationMap"];
      NSEnumerator *entries = [map keyEnumerator];
      while (key = [entries nextObject]) {
        Boolean enabled;
        SparkUID act, trg, app;
        enabled = status ? TRUE : FALSE;
        act = [[map objectForKey:key] unsignedIntValue];
        /* If action is not 'Ignore Spark', adjust uid. */
        if (act) {
          act += kSparkLibraryReserved;
        } else {
          /* Should set status = 0 and action = action for trigger/application */
          enabled = FALSE;
          act = 0; /* Will be adjust later */
        }
        trg = [trigger uid];
        app = [key intValue];
        if (app) {
          if (finder == app)
            app = kSparkApplicationFinderUID;
          else
            app += kSparkLibraryReserved;
        }
        /* Should avoid action double usage, except for ignore action. */
        if (act || (app && (!act || !CFSetContainsValue(actions, (void *)(long)act)))) {
          CFSetAddValue(actions, (void *)(intptr_t)act);
          SparkEntryPlaceholder *entry = [[SparkEntryPlaceholder alloc] initWithActionUID:act triggerUID:trg applicationUID:app];
          [placeholders addObject:entry];
          [entry setEnabled:enabled];
          [entry release];
        }
      }
    } else {
      DLog(@"Discard invalid trigger: %@", trigger);
    }
  }
  
  objects = [[wrapper propertyListForFilename:@"SparkActions"] objectForKey:@"SparkObjects"];
  /* Load Actions. Ignore old '_SparkIgnoreAction' items */
  enumerator = [objects objectEnumerator];
  objectSet = [self actionSet];
  while (plist = [enumerator nextObject]) {
    NSString *class = [plist objectForKey:@"isa"];
    if (![class isEqualToString:@"_SparkIgnoreAction"]) {
      SparkAction *action = SKDeserializeObject(plist, nil);
      if (action && [action isKindOfClass:[SparkAction class]]) {
        [action setUID:[action uid] + kSparkLibraryReserved];
        if (CFSetContainsValue(actions, (void *)(long)[action uid])) {
          [objectSet addObject:action];
        } else {
          DLog(@"Ignore orphan action: %@", action);
        }
      } else {
        DLog(@"Discard invalid action: %@", plist);
      }
    }
  }
  
  /* create entries */
  NSUInteger idx = [placeholders count];
  NSMutableArray *entries = [[NSMutableArray alloc] init];
  while (idx-- > 0) {
    SparkEntry *entry = [[placeholders objectAtIndex:idx] newEntryWithLibrary:self];
    if (entry)
      [entries addObject:entry];
  }
  [sp_relations loadLegacyEntries:entries];
  [entries release];
  
  /* and finally load lists */
  objects = [[wrapper propertyListForFilename:@"SparkLists"] objectForKey:@"SparkObjects"];
  /* Load Key Lists as Trigger Lists. */
  enumerator = [objects objectEnumerator];
  objectSet = [self listSet];
  while (plist = [enumerator nextObject]) {
    NSString *class = [plist objectForKey:@"isa"];
    if ([class isEqualToString:@"SparkKeyList"]) {
      SparkList *list = [[SparkList alloc] initWithName:[plist objectForKey:@"Name"]];
      
      NSNumber *uid;
      NSEnumerator *uids = [[plist objectForKey:@"ObjectList"] objectEnumerator];
      while (uid = [uids nextObject]) {
        SparkTrigger *trigger = [self triggerWithUID:[uid unsignedIntValue] + kSparkLibraryReserved];
        if (trigger) {
          SparkEntry *entry = [sp_relations entryForTrigger:trigger application:[self systemApplication]];
          if (entry) {
            [list addEntry:entry];
          }
        }
      }
      [objectSet addObject:list];
      [list release];
    }
  }
  
  CFRelease(actions);
  return YES;
}

- (BOOL)importTriggerListFromFileWrapper:(NSFileWrapper *)wrapper error:(NSError **)outError {
  NSData *data = [wrapper regularFileContents];
  require(data, bail);
  NSDictionary *plist = [NSPropertyListSerialization propertyListFromData:data 
                                                         mutabilityOption:NSPropertyListImmutable
                                                                   format:nil errorDescription:nil];
  require(plist, bail);
  
  NSArray *lists = [plist objectForKey:@"SparkObjects"];
  NSUInteger lcount = [lists count];
  for (NSUInteger idx = 0; idx < lcount; idx++) {
    NSDictionary *object = [lists objectAtIndex:idx];
    SparkList *list = [SparkList objectWithName:[object objectForKey:@"SparkObjectName"]];
    /* convert trigger into entry */
    NSArray *uids = [object objectForKey:@"SparkObjects"];
    NSUInteger tcount = [uids count];
    while (tcount-- > 0) {
      SparkUID uid = SKIntegerValue([uids objectAtIndex:tcount]);
      SparkTrigger *trigger = [self triggerWithUID:uid];
      if (trigger) {
        SparkEntry *entry = [sp_relations entryForTrigger:trigger application:[self systemApplication]];
        if (entry) {
          [list addEntry:entry];
        }
      }
    }
    [[self listSet] addObject:list];
  }
  
  return YES;
bail:
    if (outError) *outError = nil;
  return NO;
}

@end

/*
 *  SparkMultipleAlerts.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKAppKitExtensions.h>

#import <SparkKit/SparkAlert.h>
#import <SparkKit/SparkActionPlugIn.h>
#import <SparkKit/SparkMultipleAlerts.h>

@interface SparkMultipleAlerts (Private)
- (void)refreshUI;
- (float)setText:(NSString *)msg inField:(id)textField;
@end;

@implementation SparkMultipleAlerts

- (id)init {
  if (self = [super init]) {
    sp_alerts = [[NSMutableArray alloc] init];
  }
  return self;
}

- (id)initWithAlert:(SparkAlert *)alert {
  if (self = [self init]) {
    [self addAlert:alert];
  }
  return self;
}

- (id)initWithAlerts:(NSArray *)alerts {
  if (self = [self init]) {
    [self addAlerts:alerts];
  }
  return self;
}

- (void)dealloc {
  [self close:nil];
  [sp_nib release];
  [sp_alerts release];
  [super dealloc];
}

- (NSString *)errorString {
  return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"ERROR_COUNTER", 
                                                                       nil, SKCurrentBundle(), @"Mutiple Alerts Counter"),
    sp_index + 1, [self alertCount]];
}

- (void)awakeFromNib {
  [previousButton setImage:[NSImage imageNamed:@"Back" inBundle:SKCurrentBundle()]];
  [previousButton setAlternateImage:[NSImage imageNamed:@"BackPressedBlue" inBundle:SKCurrentBundle()]];
  [nextButton setImage:[NSImage imageNamed:@"Forward" inBundle:SKCurrentBundle()]];
  [nextButton setAlternateImage:[NSImage imageNamed:@"ForwardPressedBlue" inBundle:SKCurrentBundle()]];
  [messageText setDrawsBackground:NO];
  [[messageText enclosingScrollView] setDrawsBackground:NO];
  [informativeText setDrawsBackground:NO];
  [[informativeText enclosingScrollView] setDrawsBackground:NO];
  [self refreshUI];
}

- (void)refreshUI {
  id alert = [sp_alerts objectAtIndex:sp_index];
  if ([sp_alerts count] < 2) {
    [previousButton setHidden:YES];
    [nextButton setHidden:YES];
  } else {
    [previousButton setHidden:NO];
    [nextButton setHidden:NO];
    [previousButton setEnabled:sp_index > 0];
    [nextButton setEnabled:sp_index != ([sp_alerts count] -1)];
  }
  [counter setStringValue:[self errorString]];
  
  float deltaWin = 0;
  float deltaH = [self setText:[alert messageText] inField:messageText];
  if (SKFloatEquals(0, deltaH)) {
    NSRect frame = [[messageText enclosingScrollView] frame];
    frame.origin.y -= deltaH;
    frame.size.height += deltaH;
    [[messageText enclosingScrollView] setFrame:frame];
    frame = [[informativeText enclosingScrollView] frame];
    frame.origin.y -= deltaH;
    [[informativeText enclosingScrollView] setFrameOrigin:frame.origin];
    deltaWin += deltaH;
  }
  deltaH = [self setText:[alert informativeText] inField:informativeText];
  if (SKFloatEquals(0, deltaH)) {
    NSRect frame = [[informativeText enclosingScrollView] frame];
    frame.origin.y -= deltaH;
    frame.size.height += deltaH;
    [[informativeText enclosingScrollView] setFrame:frame];
    deltaWin += deltaH;
  }
  /* Update Spark Button */
  [openSparkButton setHidden:[alert hideSparkButton]];
  
  /* Resize Window */
  NSRect win = [alertWindow frame];
  win.size.height += deltaH;
  float minHeight = [alertWindow minSize].height - 22;
  if (NSHeight(win) < minHeight) {
    deltaH += minHeight - NSHeight(win);
    win.size.height = minHeight;
  }
  win.origin.y -= deltaH;
  [alertWindow setFrame:win display:YES animate:YES];
}

- (float)setText:(NSString *)msg inField:(id)textField {
  id layout = [textField layoutManager];
  id container = [textField textContainer];
  id storage = [textField textStorage];
  
  float oldHeight = NSHeight([layout boundingRectForGlyphRange:NSMakeRange(0, [[storage string] length])
                                               inTextContainer:container]);
  [textField setString:msg];
  float newHeight = NSHeight([layout boundingRectForGlyphRange:NSMakeRange(0, [[storage string] length])
                                               inTextContainer:container]);
  return newHeight - oldHeight;
}

- (IBAction)next:(id)sender {
  sp_index++;
  [self refreshUI];
}

- (IBAction)previous:(id)sender {
  sp_index--;
  [self refreshUI];
}

- (IBAction)close:(id)sender {
  if ([alertWindow isSheet]) {
    [NSApp endSheet:alertWindow];
  }
  if (alertWindow) {
    [alertWindow close];
    [alertWindow autorelease];
    alertWindow = nil;
  }
  if (sp_retain) {
    sp_retain = NO;
    [self release];
  }
}

- (NSArray *)alerts {
  return sp_alerts;
}

- (int)alertCount {
  return [sp_alerts count];
}

- (void)addAlert:(SparkAlert *)alert {
  [sp_alerts addObject:alert];
}

- (void)addAlerts:(NSArray *)alerts {
  [sp_alerts addObjectsFromArray:alerts];
}

- (void)addAlertWithMessageText:(NSString *)message informativeTextWithFormat:(NSString *)format,... {
  SparkAlert *alert;
  
  va_list argList;
  va_start(argList, format);
  alert = [SparkAlert alertWithMessageText:message informativeTextWithFormat:format args:argList];
  va_end(argList);
  
  [self addAlert:alert];
}

- (void)insertAlert:(SparkAlert *)alert atIndex:(int)anIndex {
  [sp_alerts insertObject:alert atIndex:anIndex];
}

- (void)removeAlert:(SparkAlert *)alert {
  [sp_alerts removeObject:alert];
}

- (void)removeAlertAtIndex:(int)anIndex {
  [sp_alerts removeObjectAtIndex:anIndex];
}

- (void)removeAlerts:(NSArray *)alerts {
  [sp_alerts removeObjectsInArray:alerts];
}

- (void)removeAllAlerts {
  [sp_alerts removeAllObjects];
}

- (void)loadInterface {
  if (sp_nib == nil) {
    sp_nib = [[NSNib alloc] initWithNibNamed:@"MultipleAlerts" bundle:SKCurrentBundle()];
  }
  if (alertWindow == nil) {
    [sp_nib instantiateNibWithOwner:self topLevelObjects:nil];
  }
}

- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo {
  [self retain];
  sp_retain = YES;
  if (![alertWindow isSheet]) {
    [self loadInterface];
    [NSApp beginSheet:alertWindow modalForWindow:window modalDelegate:delegate didEndSelector:didEndSelector contextInfo:contextInfo];
  }
}

- (void)showAlerts {
  [self retain];
  sp_retain = YES;
  [self loadInterface];
  [alertWindow makeKeyAndOrderFront:self];
}

@end

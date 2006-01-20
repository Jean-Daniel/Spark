//
//  SparkMultipleAlerts.m
//  Labo Test
//
//  Created by Fox on Sun Jul 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/ShadowMacros.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKAppKitExtensions.h>

#import <SparkKit/SparkAlert.h>
#import <SparkKit/SparkMultipleAlerts.h>

@interface SparkMultipleAlerts (Private)
- (void)refreshUI;
- (float)setText:(NSString *)msg inField:(id)textField;
@end;

@implementation SparkMultipleAlerts

- (id)init {
  if (self = [super init]) {
    _alerts = [[NSMutableArray alloc] init];
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
  [_alerts release];
  _alerts = nil;
  [_nibFile release];
  _nibFile = nil;
  [super dealloc];
}

- (NSString *)errorString {
  return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"ERROR_COUNTER", 
                                                                       nil, SKCurrentBundle(), @"Mutiple Alerts Counter"),
    selectedIndex + 1, [self alertCount]];
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
  id alert = [_alerts objectAtIndex:selectedIndex];
  if ([_alerts count] < 2) {
    [previousButton setHidden:YES];
    [nextButton setHidden:YES];
  } else {
    [previousButton setHidden:NO];
    [nextButton setHidden:NO];
    [previousButton setEnabled:selectedIndex > 0];
    [nextButton setEnabled:selectedIndex != ([_alerts count] -1)];
  }
  [counter setStringValue:[self errorString]];
  
  float deltaWin = 0;
  float deltaH = [self setText:[alert messageText] inField:messageText];
  if (deltaH) {
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
  if (deltaH) {
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
  selectedIndex++;
  [self refreshUI];
}

- (IBAction)previous:(id)sender {
  selectedIndex--;
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
  if (_selfRetain) {
    _selfRetain = NO;
    [self release];
  }
}

- (NSArray *)alerts {
  return _alerts;
}

- (int)alertCount {
  return [_alerts count];
}

- (void)addAlert:(SparkAlert *)alert {
  [_alerts addObject:alert];
}

- (void)addAlerts:(NSArray *)alerts {
  [_alerts addObjectsFromArray:alerts];
}

- (void)addAlertWithMessageText:(NSString *)message informativeTextWithFormat:(NSString *)format,... {
  SparkAlert *alert;
  
  va_list argList;
  va_start(argList, format);
  alert = [SparkAlert alertWithMessageText:message informativeTextWithFormat:format args:argList];
  va_end(argList);
  
  [self addAlert:alert];
}

- (void)insertAlert:(SparkAlert *)alert atIndex:(int)index {
  [_alerts insertObject:alert atIndex:index];
}

- (void)removeAlert:(SparkAlert *)alert {
  [_alerts removeObject:alert];
}

- (void)removeAlertAtIndex:(int)index {
  [_alerts removeObjectAtIndex:index];
}

- (void)removeAlerts:(NSArray *)alerts {
  [_alerts removeObjectsInArray:alerts];
}

- (void)removeAllAlerts {
  [_alerts removeAllObjects];
}

- (void)loadInterface {
  if (_nibFile == nil) {
    _nibFile = [[NSNib alloc] initWithNibNamed:@"MultipleAlerts" bundle:SKCurrentBundle()];
  }
  if (alertWindow == nil) {
    [_nibFile instantiateNibWithOwner:self topLevelObjects:nil];
  }
}

- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo {
  [self retain];
  _selfRetain = YES;
  if (![alertWindow isSheet]) {
    [self loadInterface];
    [NSApp beginSheet:alertWindow modalForWindow:window modalDelegate:delegate didEndSelector:didEndSelector contextInfo:contextInfo];
  }
}

- (void)showAlerts {
  [self retain];
  _selfRetain = YES;
  [self loadInterface];
  [alertWindow makeKeyAndOrderFront:self];
}


@end

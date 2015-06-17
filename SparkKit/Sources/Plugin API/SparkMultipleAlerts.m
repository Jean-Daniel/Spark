/*
 *  SparkMultipleAlerts.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkAlert.h>
#import <SparkKit/SparkActionPlugIn.h>
#import <SparkKit/SparkMultipleAlerts.h>

#import <WonderBox/NSImage+WonderBox.h>

@interface SparkMultipleAlerts ()
- (void)refreshUI;
- (CGFloat)setText:(NSString *)msg inField:(id)textField;
@end;

@implementation SparkMultipleAlerts {
  NSNib *sp_nib;
  BOOL sp_retain;
  NSUInteger sp_index;
  NSMutableArray *sp_alerts;
}

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
}

- (NSString *)errorString {
  return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"ERROR_COUNTER",  nil,
                                                                       kSparkKitBundle, @"Mutiple Alerts Counter"),
          sp_index + 1, [self alertCount]];
}

- (void)awakeFromNib {
  [previousButton setImage:[NSImage imageNamed:@"Back" inBundle:kSparkKitBundle]];
  [previousButton setAlternateImage:[NSImage imageNamed:@"BackPressedBlue" inBundle:kSparkKitBundle]];
  [nextButton setImage:[NSImage imageNamed:@"Forward" inBundle:kSparkKitBundle]];
  [nextButton setAlternateImage:[NSImage imageNamed:@"ForwardPressedBlue" inBundle:kSparkKitBundle]];
  [messageText setDrawsBackground:NO];
  [[messageText enclosingScrollView] setDrawsBackground:NO];
  [informativeText setDrawsBackground:NO];
  [[informativeText enclosingScrollView] setDrawsBackground:NO];
  [self refreshUI];
}

- (void)refreshUI {
  SparkAlert *alert = [sp_alerts objectAtIndex:sp_index];
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
  
  CGFloat deltaWin = 0;
  CGFloat deltaH = [self setText:[alert messageText] inField:messageText];
  if (fnonzero(deltaH)) {
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
  if (fnonzero(deltaH)) {
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
  win.size.height += deltaWin;
  CGFloat minHeight = [alertWindow minSize].height - 22;
  if (NSHeight(win) < minHeight) {
    deltaWin += minHeight - NSHeight(win);
    win.size.height = minHeight;
  }
  win.origin.y -= deltaWin;
  [alertWindow setFrame:win display:YES animate:YES];
}

- (CGFloat)setText:(NSString *)msg inField:(id)textField {
  NSLayoutManager *layout = [textField layoutManager];
  NSTextContainer *container = [textField textContainer];
  NSTextStorage *storage = [textField textStorage];
  
  CGFloat oldHeight = NSHeight([layout boundingRectForGlyphRange:NSMakeRange(0, [[storage string] length])
                                                 inTextContainer:container]);
  [textField setString:msg];
  CGFloat newHeight = NSHeight([layout boundingRectForGlyphRange:NSMakeRange(0, [[storage string] length])
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
    alertWindow = nil;
  }
  if (sp_retain) {
    sp_retain = NO;
    CFRelease((__bridge CFTypeRef)(self));
  }
}

- (NSArray *)alerts {
  return sp_alerts;
}

- (NSUInteger)alertCount {
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

- (void)insertAlert:(SparkAlert *)alert atIndex:(NSUInteger)anIndex {
  [sp_alerts insertObject:alert atIndex:anIndex];
}

- (void)removeAlert:(SparkAlert *)alert {
  [sp_alerts removeObject:alert];
}

- (void)removeAlertAtIndex:(NSUInteger)anIndex {
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
    sp_nib = [[NSNib alloc] initWithNibNamed:@"SparkMultiAlert" bundle:kSparkKitBundle];
  }
  if (alertWindow == nil)
    [sp_nib instantiateNibWithOwner:self topLevelObjects:nil];
}

- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo {
  CFRetain((__bridge CFTypeRef)(self));
  sp_retain = YES;
  if (![alertWindow isSheet]) {
    [self loadInterface];
    [NSApp beginSheet:alertWindow modalForWindow:window modalDelegate:delegate didEndSelector:didEndSelector contextInfo:contextInfo];
  }
}

- (void)showAlerts {
  CFRetain((__bridge CFTypeRef)(self));
  sp_retain = YES;
  [self loadInterface];
  [alertWindow makeKeyAndOrderFront:self];
}

@end

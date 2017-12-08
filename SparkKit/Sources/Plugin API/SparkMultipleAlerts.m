/*
 *  SparkMultipleAlerts.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkAlert.h>

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkActionPlugIn.h>
#import <SparkKit/SparkMultipleAlerts.h>

#import <WonderBox/WonderBox.h>

@interface SparkMultipleAlerts ()

// Other objects
@property(nonatomic, assign) IBOutlet NSButton *nextButton;
@property(nonatomic, assign) IBOutlet NSButton *previousButton;
@property(nonatomic, assign) IBOutlet NSButton *openSparkButton;

@property(nonatomic, assign) IBOutlet NSTextField *counter;
@property(nonatomic, assign) IBOutlet NSTextView *messageText;
@property(nonatomic, assign) IBOutlet NSTextView *informativeText;

- (void)refreshUI;
- (CGFloat)setText:(NSString *)msg inField:(id)textField;
@end;

@implementation SparkMultipleAlerts {
  NSUInteger sp_index;
  NSMutableArray *sp_alerts;
}

- (instancetype)init {
  if (self = [super initWithWindowNibName:@"SparkMultiAlert"]) {
    sp_alerts = [[NSMutableArray alloc] init];
  }
  return self;
}

- (instancetype)initWithAlert:(SparkAlert *)alert {
  if (self = [self init]) {
    [self addAlert:alert];
  }
  return self;
}

- (instancetype)initWithAlerts:(NSArray *)alerts {
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
                                                                       SparkKitBundle(), @"Mutiple Alerts Counter"),
          sp_index + 1, [self alertCount]];
}

- (void)awakeFromNib {
  _previousButton.image = [NSImage imageNamed:@"Back" inBundle:SparkKitBundle()];
  _previousButton.alternateImage = [NSImage imageNamed:@"BackPressedBlue" inBundle:SparkKitBundle()];

  _nextButton.image = [NSImage imageNamed:@"Forward" inBundle:SparkKitBundle()];
  _nextButton.alternateImage = [NSImage imageNamed:@"ForwardPressedBlue" inBundle:SparkKitBundle()];

  _messageText.drawsBackground = NO;
  _messageText.enclosingScrollView.drawsBackground = NO;

  _informativeText.drawsBackground = NO;
  _informativeText.enclosingScrollView.drawsBackground = NO;
  [self refreshUI];
}

- (void)refreshUI {
  SparkAlert *alert = [sp_alerts objectAtIndex:sp_index];
  if ([sp_alerts count] < 2) {
    _previousButton.hidden = YES;
    _nextButton.hidden = YES;
  } else {
    _previousButton.hidden = NO;
    _nextButton.hidden = NO;
    _previousButton.enabled = sp_index > 0;
    _nextButton.enabled = sp_index != ([sp_alerts count] -1);
  }
  _counter.stringValue = [self errorString];
  
  CGFloat deltaWin = 0;
  CGFloat deltaH = [self setText:alert.messageText inField:_messageText];
  if (fnonzero(deltaH)) {
    NSRect frame = _messageText.enclosingScrollView.frame;
    frame.origin.y -= deltaH;
    frame.size.height += deltaH;
    _messageText.enclosingScrollView.frame = frame;

    frame = _informativeText.enclosingScrollView.frame;
    frame.origin.y -= deltaH;
    [_informativeText.enclosingScrollView setFrameOrigin:frame.origin];
    deltaWin += deltaH;
  }
  deltaH = [self setText:alert.informativeText inField:_informativeText];
  if (fnonzero(deltaH)) {
    NSRect frame = _informativeText.enclosingScrollView.frame;
    frame.origin.y -= deltaH;
    frame.size.height += deltaH;
    _informativeText.enclosingScrollView.frame = frame;
    deltaWin += deltaH;
  }
  /* Update Spark Button */
  _openSparkButton.hidden = [alert hideSparkButton];
  
  /* Resize Window */
  NSRect win = self.window.frame;
  win.size.height += deltaWin;
  CGFloat minHeight = self.window.minSize.height - 22;
  if (NSHeight(win) < minHeight) {
    deltaWin += minHeight - NSHeight(win);
    win.size.height = minHeight;
  }
  win.origin.y -= deltaWin;
  [self.window setFrame:win display:YES animate:YES];
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
  if (self.window.sheet) {
    [NSApp endSheet:self.window];
  }
  [self close];
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

- (void)beginSheetModalForWindow:(NSWindow *)sheetWindow completionHandler:(void (^ __nullable)(NSModalResponse returnCode))handler {
  if (!self.window.sheet)
    [self.window beginSheet:self.window completionHandler:handler];
}

- (void)showAlerts {
  [super showWindow:nil];
}

@end

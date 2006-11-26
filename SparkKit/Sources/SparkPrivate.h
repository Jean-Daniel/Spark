/*
 *  SparkPrivate.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkActionPlugIn.h>

@interface SparkActionPlugIn (Private)

/* Some kind of hack to resolve binding cyclic memory problem. 
- releaseViewOwnership says to the receiver that it no longer need retain
  the view because something else retained it. So SparkActionPlugin instance release
  the view and breaks the retain cycle. */
- (void)releaseViewOwnership;
- (void)setSparkAction:(SparkAction *)anAction edit:(BOOL)flag;

@end

@class SparkHotKey;
@interface SparkAction (Private)

- (id)duplicate;

- (BOOL)isInvalid;
- (void)setInvalid:(BOOL)flag;

  /*!
  @method     setCategorie:
   @abstract   Sets the categorie for this Action.
   @param      categorie Action categorie.
   */
- (void)setCategorie:(NSString *)categorie;

- (SparkAlert *)hotKeyShouldExecuteAction:(SparkHotKey *)hotkey;

@end

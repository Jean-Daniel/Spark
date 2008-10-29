//
//  SEUpdater.h
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 18/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <SUpdaterKit/SUpdater.h>

@interface SEUpdater : SUpdater {
  @private
  id se_delegate;
  //bool se_pending;
}

+ (SEUpdater *)sharedUpdater;

- (void)searchWithDelegate:(id)delegate;

@end

@interface NSObject (SEUpdaterDelegate)

- (void)updater:(SEUpdater *)updater didSearchVersion:(BOOL)newVersion error:(NSError *)anError;

@end

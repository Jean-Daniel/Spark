//
//  KeyWarningList.h
//  Spark Editor
//
//  Created by Grayfox on 01/11/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit.h>

extern NSString * const kWarningListDidChangeNotification;

@interface KeyWarningList : SparkKeyList {

}

- (void)reload;

@end

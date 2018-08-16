//
//  NcmbQueue.h
//  Copyright 2017-2018 FUJITSU CLOUD TECHNOLOGIES LIMITED All Rights Reserved.
//
//

#ifndef HelloCordova_NcmbQueue_h
#define HelloCordova_NcmbQueue_h
#import <Foundation/Foundation.h>

@interface NcmbQueue : NSObject {
    NSMutableArray *_data;
}


- (NSDictionary*)dequeue;
- (void)enqueue:(NSDictionary*)value ;
- (BOOL)isEmpty;
@end

#endif

//
//  NiftyQueue.m
//  Copyright 2017 FUJITSU CLOUD TECHNOLOGIES LIMITED All Rights Reserved.
//
//

#import "NiftyQueue.h"

@implementation NiftyQueue

- (id)init {
    self = [super init];
    
    if (self != nil) {
        _data = [[NSMutableArray alloc] init];
    }
 
    return self;
}

- (NSDictionary*)dequeue {
    id value;

    @synchronized(_data){
        value = [_data objectAtIndex:0];
        
        if (value != nil) {
            [_data removeObjectAtIndex:0];
        }
    }
    
    return value;
}

- (void)enqueue:(NSDictionary*)value {
    @synchronized(_data){
        if (value == nil) {
            return;
        }
        
        [_data addObject:value];
    }
}

- (BOOL)isEmpty {
    NSUInteger num;
    
    @synchronized(_data){
        num = [_data count];
    }
    
    return num == 0;
}
@end

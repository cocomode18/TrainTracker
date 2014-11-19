//
//  TrackingData.m
//  TrainTracker
//
//  Created by OtaniAtsushi1 on 2014/11/16.
//  Copyright (c) 2014年 AtsushiOtani. All rights reserved.
//

#import "TrackingData.h"

@implementation TrackingData

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self->_location forKey:@"location"];
    [aCoder encodeObject:self->_station forKey:@"station"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self->_location = [aDecoder decodeObjectForKey:@"location"];
        self->_station = [aDecoder decodeObjectForKey:@"station"];
    }
    return self;
}

@end

//
//  TrackingData.h
//  TrainTracker
//
//  Created by OtaniAtsushi1 on 2014/11/16.
//  Copyright (c) 2014年 AtsushiOtani. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface TrackingData : NSObject<NSCoding>

// encode, decode メソッドに追記のこと
@property (strong, nonatomic) CLLocation* location;
@property (strong, nonatomic) NSString* railroadLine;
@property (strong, nonatomic) NSString* station;
@property (assign, nonatomic) double distanceToStation;

@end

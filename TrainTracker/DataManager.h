//
//  DataManager.h
//  TrainTracker
//
//  Created by OtaniAtsushi1 on 2014/11/16.
//  Copyright (c) 2014年 AtsushiOtani. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataManager : NSObject

@property (strong, nonatomic) NSMutableArray* trackingDatas;


+ (DataManager *)sharedManager;

- (BOOL)save;
- (void)load;

@end

//
//  DataManager.m
//  TrainTracker
//
//  Created by OtaniAtsushi1 on 2014/11/16.
//  Copyright (c) 2014年 AtsushiOtani. All rights reserved.
//

#import "DataManager.h"

@interface DataManager()


@end

@implementation DataManager

static DataManager *_sharedManager = nil;

+ (DataManager *)sharedManager {
	if (!_sharedManager) {
		_sharedManager = [[DataManager alloc]init];
	}
	return _sharedManager;
}

- (id)init {
	self = [super init];
	if (self) {
        [self load];
	}
	return self;
}

-(BOOL)save{
    return [NSKeyedArchiver archiveRootObject:self.trackingDatas toFile:[self getUserDataFilePath]];
}

-(void)load{
    self.trackingDatas = [NSKeyedUnarchiver unarchiveObjectWithFile:[self getUserDataFilePath]];
    if (self.trackingDatas == nil) {
        self.trackingDatas = [@[] mutableCopy];
    }
}

-(NSString*)getUserDataFilePath{
    NSString *directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *filePath = [directory stringByAppendingPathComponent:@"locationData.dat"];
    return filePath;
}
@end

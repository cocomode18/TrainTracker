//
//  LocationViewController.h
//  TrainTracker
//
//  Created by OtaniAtsushi1 on 2014/11/16.
//  Copyright (c) 2014年 AtsushiOtani. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "DataManager.h"

@interface LocationViewController : UIViewController <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>
    
// ロケーションマネージャー
@property (strong, nonatomic) CLLocationManager *locationManager;

// 現在位置記録用
@property (assign, nonatomic) CLLocationDegrees longitude;
@property (assign, nonatomic) CLLocationDegrees latitude;

//iboutlet
@property (strong, nonatomic) IBOutlet UILabel *lonLabel;
@property (strong, nonatomic) IBOutlet UILabel *latLabel;
@property (strong, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UITableView *historyTableView;

@end

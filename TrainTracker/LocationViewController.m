//
//  LocationViewController.m
//  TrainTracker
//
//  Created by OtaniAtsushi1 on 2014/11/16.
//  Copyright (c) 2014年 AtsushiOtani. All rights reserved.
//

#import "LocationViewController.h"
#import "TrackingData.h"

@interface LocationViewController ()

@property (weak, nonatomic) NSMutableArray* trackingDatas;
@property (strong, nonatomic) NSDateFormatter *formatter;

@end

@implementation LocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.trackingDatas = [DataManager sharedManager].trackingDatas;
    self.formatter = [[NSDateFormatter alloc]init];
    [self.formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];

    // ロケーションマネージャーを作成
    self.locationManager = [[CLLocationManager alloc] init];

    if ([CLLocationManager locationServicesEnabled]) {
        
        // 位置情報取得開始
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0) {
            //[self.locationManager requestAlwaysAuthorization];
            [self.locationManager startUpdatingLocation];
            self.locationManager.delegate = self;
        }
        else{
            [self.locationManager startUpdatingLocation];
            self.locationManager.delegate = self;
            //self.locationManager.distanceFilter = 1.0; //1m移動で通知
        }
        NSLog(@"start");
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self.historyTableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    NSLog(@"%s", __func__);
}

#pragma mark - delegate methods

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSString* string;
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
            string = @"常に許可";
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            string = @"使用時のみ許可";
            break;
        case kCLAuthorizationStatusDenied:
            string = @"不許可";
            break;
        case kCLAuthorizationStatusNotDetermined:
            string = @"未設定";
            break;
        case kCLAuthorizationStatusRestricted:
            string = @"限定的";
            break;
        default:
            string = @"その他";
            break;
    }
    NSLog(@"%@", string);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [self processWithLocations:locations];
}

//iOS6より前
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    [self processWithLocations:@[oldLocation, newLocation]];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"error!");
    self.descLabel.text = @"error!";

    if (error) {
        NSString* message = nil;
        switch ([error code]) {
                // アプリでの位置情報サービスが許可されていない場合
            case kCLErrorDenied:
                // 位置情報取得停止
                [self.locationManager stopUpdatingLocation];
                message = [NSString stringWithFormat:@"このアプリは位置情報サービスが許可されていません。"];
                break;
            default:
                message = [NSString stringWithFormat:@"位置情報の取得に失敗しました。"];
                break;
        }
        if (message) {
            // アラートを表示
            UIAlertView* alert=[[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil
                                                 cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
}


#pragma mark - location

-(void)processWithLocations:(NSArray*)locations{
    CLLocation *recentLocation = locations.lastObject;
    
    self.longitude = recentLocation.coordinate.longitude;
    self.latitude  = recentLocation.coordinate.latitude;
    
    self.lonLabel.text = [NSString stringWithFormat:@"%f",self.longitude];
    self.latLabel.text = [NSString stringWithFormat:@"%f",self.latitude];

    //データ追加
    for (CLLocation* loc in locations) {
        TrackingData* data = [[TrackingData alloc]init];
        data.location = loc;
        data.station = @"無名";
        
        [self.trackingDatas addObject:data];
        
        NSLog(@"%@", [loc description]);
    }
    //TrackingData* data = [[TrackingData alloc]init];
    //data.location = recentLocation;
    //data.station = @"無名";
    
    //[self.trackingDatas addObject:data];
    
    [self.historyTableView reloadData];
}

#pragma mark - api call

-(void)getStationInfoFromLocation:(CLLocation*)location{
}


#pragma mark - table view

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.trackingDatas.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"LocationHistoryCell"];
    
    NSInteger index = self.trackingDatas.count - indexPath.row  - 1;
    TrackingData* trackingData = (TrackingData*)self.trackingDatas[index];
    cell.textLabel.text = [NSString stringWithFormat:@"駅:%@, 緯度%.5f, 経度%.5f, 高度%.5f",
                           trackingData.station,
                           trackingData.location.coordinate.latitude, trackingData.location.coordinate.longitude,
                           trackingData.location.altitude];
    cell.detailTextLabel.text = [self.formatter stringFromDate:trackingData.location.timestamp];
    
    return cell;
}


#pragma mark - console

-(IBAction)logOutput:(id)sender{
    for (TrackingData* data in self.trackingDatas) {
        NSLog(@"時刻:%@, 駅:%@, 緯度%.5f, 経度%.5f, 高度%.5f, 水平精度%.5f, 鉛直精度%.5f, 速度%.5f",
              [self.formatter stringFromDate:data.location.timestamp],
              data.station,
              data.location.coordinate.latitude,
              data.location.coordinate.longitude,
              data.location.altitude,
              data.location.horizontalAccuracy,
              data.location.verticalAccuracy,
              data.location.speed);

    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

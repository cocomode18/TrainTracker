//
//  LocationViewController.m
//  TrainTracker
//
//  Created by OtaniAtsushi1 on 2014/11/16.
//  Copyright (c) 2014年 AtsushiOtani. All rights reserved.
//

#import "LocationViewController.h"
#import "TrackingData.h"

//#define DISTANCE_WITHIN_STATION 100 //unit: meter

enum {
	SegmentedControlIndexOn = 0,
	SegmentedControlIndexOff = 1,
};

@interface LocationViewController ()

@property (weak, nonatomic) NSMutableArray *trackingDatas;
@property (strong, nonatomic) NSDateFormatter *formatter;

@end

@implementation LocationViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.

	self.distanceFilter = 10.0;
	self.distanceWithinStation = 100.0;

	self.trackingDatas = [DataManager sharedManager].trackingDatas;
	self.formatter = [[NSDateFormatter alloc]init];
	[self.formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];

	// ロケーションマネージャーを作成
	self.locationManager = [[CLLocationManager alloc] init];

	if ([CLLocationManager locationServicesEnabled] &&
	    [CLLocationManager significantLocationChangeMonitoringAvailable]) {
		//まずdelegateをセット(これによって -locationManager: didChangeAuthorizationStatus: メソッドが呼びだされる
		self.locationManager.delegate = self;

		//iOS8の場合、許可要求のアラートを明示的に呼び出す必要あり
		if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0) {
			//「常に使用を許可」でない場合、許可を求める
			if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways) {
				[self.locationManager requestAlwaysAuthorization];
			}
		}
		//開始(iOS7以前の場合、start系メソッドを呼ぶことによって許可要求のアラートが出る)
		else {
			[self startLocation];
		}

		//開始処理は -locationManager: didChangeAuthorizationStatus: から[self startLocation]を呼び出すことによって行う。
        //iOS7以前ですでに許可済みの場合だけ、2重に[self startLocation]が実行されることになるが、多重呼び出し可能にしてあるので問題無し
	}
	else {
        //このアプリが使えない
		[[[UIAlertView alloc]initWithTitle:@"" message:@"この端末では位置情報サービスを使用することができません" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	self.trackingDatas = [DataManager sharedManager].trackingDatas;
	[self.historyTableView reloadData];
}

- (void)viewDidLayoutSubviews {
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.

	NSLog(@"%s", __func__);
}

#pragma mark - location delegate methods

/**
 * 位置情報サービスの許可状態が変更されたときに呼び出される
 */
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	//NSLog(@"%@", [self getAuthorizationString:status]);

	if (status == kCLAuthorizationStatusAuthorizedAlways) {
		[self startLocation];
	}
	else if (status == kCLAuthorizationStatusDenied) {
		[self stopLocation];
	}
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
	NSLog(@"%s", __func__);
	[self processWithLocations:locations];
}

//iOS6より前
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	[self processWithLocations:@[oldLocation, newLocation]];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"error : %@", [error description]);
	self.descLabel.text = [error description];

	if (error) {
		NSString *message = nil;
		switch ([error code]) {
			// アプリでの位置情報サービスが許可されていない場合
			case kCLErrorDenied:
				// 位置情報取得停止
				[self stopLocation];
				message = [NSString stringWithFormat:@"このアプリは位置情報サービスが許可されていません。"];
				break;

			default:
				//message = [NSString stringWithFormat:@"位置情報の取得に失敗しました。"];
				break;
		}
		if (message) {
			// アラートを表示
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil
			                                      cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
	}
}

#pragma mark - location

/**
 * CLLocationManagerの位置情報サービス取得を開始する
 * 複数回呼んでもよいようにしておく(iOSバージョンによって呼び出しタイミングが変化するため)
 */
- (void)startLocation {
	[self.locationManager startUpdatingLocation];
	[self.locationManager startMonitoringSignificantLocationChanges];

	self.locationManager.distanceFilter = self.distanceFilter;

	//viewの設定
	self.notifyMeterTextField.text = [NSString stringWithFormat:@"%d", (int)self.distanceFilter];
	self.distanceWithinStationTextField.text = [NSString stringWithFormat:@"%d", (int)self.distanceWithinStation];
	self.normalLocationSegmentedControl.selectedSegmentIndex = SegmentedControlIndexOn;
	self.significantLocationSegmentedControl.selectedSegmentIndex = SegmentedControlIndexOn;
}

- (void)stopLocation {
	[self.locationManager stopUpdatingLocation];
	[self.locationManager stopMonitoringSignificantLocationChanges];
}

- (void)processWithLocations:(NSArray *)locations {
	CLLocation *recentLocation = locations.lastObject;

	self.longitude = recentLocation.coordinate.longitude;
	self.latitude  = recentLocation.coordinate.latitude;

	self.lonLabel.text = [NSString stringWithFormat:@"%f", self.longitude];
	self.latLabel.text = [NSString stringWithFormat:@"%f", self.latitude];

	//データ追加
	for (CLLocation *loc in locations) {
		TrackingData *data = [[TrackingData alloc]init];
		data.location = loc;

		//駅情報
		NSDictionary *stationInfo = [self getStationInfoFromLocation:loc];

		if (stationInfo) {
			data.station = stationInfo[@"name"];
			data.railroadLine = stationInfo[@"line"];
			data.distanceToStation = ((NSString *)stationInfo[@"distance"]).doubleValue;
		}

		[self.trackingDatas addObject:data];
		[[DataManager sharedManager] save];

		NSLog(@"%@", [loc description]);
	}

	[self.historyTableView reloadData];
}

- (BOOL)isInStation:(TrackingData *)trackingData {
	return trackingData.station && trackingData.distanceToStation <= self.distanceWithinStation;
}

- (NSString *)getAuthorizationString:(CLAuthorizationStatus)status {
	NSString *string;
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
	return string;
}

#pragma mark - api call

- (id)getStationInfoFromLocation:(CLLocation *)location {
	//使用API
	//http://blog.ch3cooh.jp/entry/20141113/1415883600
	//

	NSString *urlString = [NSString stringWithFormat:@"http://moyoristation.azurewebsites.net/moyori?latitude=%f&longitude=%f&version=v1", location.coordinate.latitude, location.coordinate.longitude];
	NSURL *url = [NSURL URLWithString:urlString];

	NSError *error;
	NSData *jsonData = [NSData dataWithContentsOfURL:url options:kNilOptions error:&error];
	if (error) {
		NSLog(@"%@", [error description]);
		return nil;
	}

	NSArray *jsonResponse = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
	if (error) {
		NSLog(@"%@", [error description]);
		return nil;
	}

	/*for( NSDictionary * json in jsonResponse )
	   {
	    NSString* stationName = json[@"name"];
	    NSString* companyName = json[@"company"];
	    NSString* lineName = json[@"line"];
	    NSString* distance = json[@"distance"]; //メートル

	    //駅にいる判定が出たら返す
	    double distance_meter = distance.doubleValue;
	    if (distance_meter < DISTANCE_WITHIN_STATION) {
	        return json;
	    }
	   }
	 */

	//NSLog(@"%@", response);

	return jsonResponse[0]; //無条件でもっとも近い駅を返す
}

#pragma mark - table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.trackingDatas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LocationHistoryCell"];

	NSInteger index = self.trackingDatas.count - indexPath.row  - 1;
	TrackingData *trackingData = (TrackingData *)self.trackingDatas[index];
	cell.textLabel.text = [self getMainDescription:trackingData];
	cell.detailTextLabel.text = [self getSubDescription:trackingData];

	//駅にいたら色付ける
	UIColor *textColor = [self isInStation:trackingData] ? [UIColor redColor] : [UIColor blackColor];
	cell.textLabel.textColor = textColor;

	return cell;
}

#pragma mark - console

- (NSString *)getMainDescription:(TrackingData *)trackingData {
	return [NSString stringWithFormat:@"%@ %@駅(%.1fm), 緯度%.5f, 経度%.5f, 高度%.5f",
	        trackingData.railroadLine, trackingData.station, trackingData.distanceToStation,
	        trackingData.location.coordinate.latitude, trackingData.location.coordinate.longitude,
	        trackingData.location.altitude];
}

- (NSString *)getSubDescription:(TrackingData *)trackingData {
	return [NSString stringWithFormat:@"%@ 速度%.2f,精度(h=%.1f,v=%.1f)",
	        [self.formatter stringFromDate:trackingData.location.timestamp],
	        trackingData.location.speed,
	        trackingData.location.horizontalAccuracy,
	        trackingData.location.verticalAccuracy];
}

#pragma mark - IBAction

- (IBAction)logOutput:(id)sender {
	for (TrackingData *data in self.trackingDatas) {
		NSLog(@"%@ %@",
		      [self getMainDescription:data],
		      [self getSubDescription:data]);
	}
}

- (IBAction)reloadTable:(id)sender {
	self.trackingDatas = [DataManager sharedManager].trackingDatas;
	[self.historyTableView reloadData];
}

- (IBAction)switchedNorm:(UISegmentedControl *)control {
	switch (control.selectedSegmentIndex) {
		case 0:
			[self.locationManager startUpdatingLocation];
			break;

		case 1:
			[self.locationManager stopUpdatingLocation];
			break;
	}
}

- (IBAction)switchedSig:(UISegmentedControl *)control {
	switch (control.selectedSegmentIndex) {
		case 0:
			[self.locationManager startMonitoringSignificantLocationChanges];
			break;

		case 1:
			[self.locationManager stopMonitoringSignificantLocationChanges];
			break;
	}
}

- (IBAction)notifyMeterChanged:(UITextField *)textField {
	float meter = textField.text.floatValue;
	self.distanceFilter = meter;
	self.locationManager.distanceFilter = meter;
}

- (IBAction)distanceWithinStationChanged:(UITextField *)textField {
	float distance = textField.text.floatValue;
	self.distanceWithinStation = distance;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	if (touch.view != self.notifyMeterTextField) {
		[self.notifyMeterTextField resignFirstResponder];
	}
	if (touch.view != self.distanceWithinStationTextField) {
		[self.distanceWithinStationTextField resignFirstResponder];
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

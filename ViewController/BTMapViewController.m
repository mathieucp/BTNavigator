//
//  BTMapViewController.m
//  BTNavigator
//
//  Created by Tu Nguyen on 7/10/15.
//  Copyright (c) 2015 TDStudio. All rights reserved.
//

#import "BTMapViewController.h"

@interface BTMapViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITextField *locationTextField;

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation BTMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    if (SYSTEM_VERSION_GREATER_THAN(@"8.0")) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    [self.mapView setShowsUserLocation:YES];
    // Do any additional setup after loading the view.
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

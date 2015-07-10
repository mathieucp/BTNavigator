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

@property (nonatomic, retain) MKPointAnnotation *centerAnnotation;

@end

@implementation BTMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    if (SYSTEM_VERSION_GREATER_THAN(@"8.0")) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    [self.mapView setShowsUserLocation:YES];
    
    //Set center Annotation
    self.centerAnnotation = [[MKPointAnnotation alloc] init];
    self.centerAnnotation.coordinate = self.mapView.centerCoordinate;
    self.centerAnnotation.title = @"Your location";
    [self.mapView addAnnotation:self.centerAnnotation];
    [self.mapView selectAnnotation:self.centerAnnotation animated:NO];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    CLLocationCoordinate2D newCoord2D = [self.mapView centerCoordinate];
    
    self.centerAnnotation.coordinate = newCoord2D;
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:newCoord2D.latitude longitude:newCoord2D.longitude];
    
    //Get address from location (latitude, longtitude)
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks.count > 0) {
            CLPlacemark *placemark = placemarks[0];
            
            self.centerAnnotation.title = placemark.addressDictionary[@"Name"];
            [self.mapView selectAnnotation:self.centerAnnotation animated:NO];
        }
    }];
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

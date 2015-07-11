//
//  BTMapViewController.m
//  BTNavigator
//
//  Created by Tu Nguyen on 7/10/15.
//  Copyright (c) 2015 TDStudio. All rights reserved.
//

#import "BTMapViewController.h"
#import "BTAutoCompleteTableView.h"

@interface BTMapViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, retain) MKPointAnnotation *centerAnnotation;

@property (nonatomic, strong) BTAutoCompleteTableView *autoCompleteTableView;
@property (nonatomic, strong) NSString *lastSearchString;
@property (nonatomic, assign) CGFloat autoCompleteTableViewHeight;

@end

@implementation BTMapViewController

-(BTAutoCompleteTableView *)autoCompleteTableView {
    if (!_autoCompleteTableView) {
        CGFloat height = CGRectGetMaxY(self.view.frame) - CGRectGetMaxY(self.searchBar.frame);
        self.autoCompleteTableViewHeight = height/2;
        
        self.autoCompleteTableView = [[BTAutoCompleteTableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.searchBar.frame), self.view.bounds.size.width, 0) style:UITableViewStylePlain];
        
        [self.view addSubview:self.autoCompleteTableView];
        [self.view sendSubviewToBack:self.mapView];
        
        [self.autoCompleteTableView setHidden:YES];
    }
    return _autoCompleteTableView;
}

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
    
    //Setup autoCompleteTableView
    [self.autoCompleteTableView setDataArray:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAutoCompleteRow:) name:kNotificationAutoCompleteRowSelected object:nil];
}

#pragma mark - MapViewDelegate

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

#pragma mark - searchBar Delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.searchBar.showsCancelButton = YES;
    
    self.autoCompleteTableView.hidden = NO;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    self.searchBar.showsCancelButton = NO;
    self.autoCompleteTableView.hidden = YES;
    [self.searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchBar.showsCancelButton = NO;
    self.autoCompleteTableView.hidden = YES;
    [self.searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.searchBar.showsCancelButton = NO;
    [self.searchBar resignFirstResponder];
    self.searchBar.text = self.lastSearchString;
    
    [self getAutoCompleteDataWithLocationName:self.lastSearchString];
    
    self.autoCompleteTableView.hidden = NO;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getAutoCompleteDataWithLocationName:) object:self.lastSearchString];
    
    self.lastSearchString = searchText;
    
    [self performSelector:@selector(getAutoCompleteDataWithLocationName:) withObject:searchText afterDelay:0.3];
}

#pragma mark - Support

- (void)didSelectAutoCompleteRow:(NSNotification *)notification {
    if ([notification.name isEqualToString:kNotificationAutoCompleteRowSelected]) {
        MKMapItem *mapItem = notification.userInfo[kNotificationAutoCompleteRowSelected];
        
        [self.autoCompleteTableView setHidden:YES];
        
        WTLog(@"%@", mapItem.placemark);
    }
}

- (void)getAutoCompleteDataWithLocationName:(NSString *)searchString {
    if (searchString.length == 0)
        return;
    
    MKLocalSearchRequest *searchRequest = [[MKLocalSearchRequest alloc] init];
    searchRequest.naturalLanguageQuery = searchString;
    
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:searchRequest];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        if (response.mapItems.count > 0) {
            [self resizeAutoCompleteTableViewToFitNumberOfItems:response.mapItems.count];
            [self.autoCompleteTableView setDataArray:response.mapItems];
        }
    }];
}

- (void)resizeAutoCompleteTableViewToFitNumberOfItems:(NSInteger)numOfRow {
    CGFloat estimateHeight = numOfRow * 40;
    CGFloat newHeigh = estimateHeight > self.autoCompleteTableViewHeight ? self.autoCompleteTableViewHeight : estimateHeight;
    
    self.autoCompleteTableView.frame = CGRectMake(self.autoCompleteTableView.frame.origin.x,
                                                  self.autoCompleteTableView.frame.origin.y,
                                                  self.autoCompleteTableView.frame.size.width,
                                                  newHeigh);
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

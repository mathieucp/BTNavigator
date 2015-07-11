//
//  BTMapViewController.m
//  BTNavigator
//
//  Created by Tu Nguyen on 7/10/15.
//  Copyright (c) 2015 TDStudio. All rights reserved.
//

#import "BTMapViewController.h"
#import "BTAutoCompleteTableView.h"
#import "Route.h"

@interface BTMapViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIView *travelDetails;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) BTAutoCompleteTableView *autoCompleteTableView;

@end

@implementation BTMapViewController {
    MKPointAnnotation *_centerAnnotation;
    NSString *_lastSearchString;
    CGFloat _autoCompleteTableViewHeight;
    Route *_route;
    
    UILongPressGestureRecognizer *_longPressGesture;
}

-(BTAutoCompleteTableView *)autoCompleteTableView {
    if (!_autoCompleteTableView) {
        CGFloat height = CGRectGetMaxY(self.view.frame) - CGRectGetMaxY(self.searchBar.frame);
        _autoCompleteTableViewHeight = height/2;
        
        self.autoCompleteTableView = [[BTAutoCompleteTableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.searchBar.frame), self.view.bounds.size.width, 0) style:UITableViewStylePlain];
        
        [self.view addSubview:self.autoCompleteTableView];
        [self.view sendSubviewToBack:self.mapView];
        
        [self.autoCompleteTableView setHidden:YES];
    }
    return _autoCompleteTableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.travelDetails.frame = CGRectMake(self.travelDetails.frame.origin.x, self.travelDetails.frame.origin.y, self.travelDetails.frame.size.width, 0);
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    if (SYSTEM_VERSION_GREATER_THAN(@"8.0")) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    [self.mapView setShowsUserLocation:YES];
    
    //Set center Annotation
    _centerAnnotation = [[MKPointAnnotation alloc] init];
    _centerAnnotation.coordinate = self.mapView.centerCoordinate;
    _centerAnnotation.title = @"Your location";
    [self.mapView addAnnotation:_centerAnnotation];
    [self.mapView selectAnnotation:_centerAnnotation animated:NO];
    
    //Setup autoCompleteTableView
    [self.autoCompleteTableView setDataArray:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAutoCompleteRow:) name:kNotificationAutoCompleteRowSelected object:nil];
    
    //Setup Gesture
    //App will show path to destination according to LongPressGesture's Point
    _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressFired:)];
    [self.view addGestureRecognizer:_longPressGesture];
}

#pragma mark - GestureRecognizer

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
    CGPoint touchPoint = [touch locationInView:self.view];
    
    //Hide autocomplete TableView when user touch outside TableView
    if (!CGRectContainsPoint(self.autoCompleteTableView.frame, touchPoint)) {
        self.autoCompleteTableView.hidden = YES;
        [self.searchBar resignFirstResponder];
    }
}

- (void)longPressFired:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint point = [recognizer locationInView:self.view];
        
        //Get coord by touch point
        CLLocationCoordinate2D locCoord2d = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
        CLLocation *location = [[CLLocation alloc] initWithLatitude:locCoord2d.latitude longitude:locCoord2d.longitude];
        
        //Get route by coord
        CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
        [geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            if (placemarks.count > 0) {
                MKPlacemark *placemark = [[MKPlacemark alloc] initWithPlacemark:[placemarks firstObject]];
                MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
                [self.activityIndicator startAnimating];
                [self calculateRouteToMapItem:mapItem];
            }
        }];
    }
}

#pragma mark - MapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 1000, 1000);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
    
    [self.mapView setUserTrackingMode:MKUserTrackingModeNone];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    CLLocationCoordinate2D newCoord2D = [self.mapView centerCoordinate];
    
    _centerAnnotation.coordinate = newCoord2D;
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:newCoord2D.latitude longitude:newCoord2D.longitude];
    
    //Get address from location (latitude, longtitude)
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks.count > 0) {
            CLPlacemark *placemark = placemarks[0];
            
            _centerAnnotation.title = placemark.addressDictionary[@"Name"];
            [self.mapView selectAnnotation:_centerAnnotation animated:NO];
        }
    }];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    renderer.strokeColor = [UIColor redColor];
    renderer.lineWidth = 4.0;
    return  renderer;
}

#pragma mark - Caculation Route

- (void)calculateRouteToMapItem:(MKMapItem *)mapItem {
    MKPointAnnotation *sourceAnnotaion = [MKPointAnnotation new];
    sourceAnnotaion.coordinate = self.mapView.userLocation.coordinate;
    sourceAnnotaion.title = @"Your location";
    
    MKPointAnnotation *destinationAnnotation = [MKPointAnnotation new];
    destinationAnnotation.coordinate = mapItem.placemark.coordinate;
    destinationAnnotation.title = mapItem.placemark.title;
    
    MKMapItem *sourceMapItem = [MKMapItem mapItemForCurrentLocation];
    MKMapItem *destinationMapItem = mapItem;
    
    [self obtainDirectionsFrom:sourceMapItem to:destinationMapItem completion:^(MKRoute *route, NSError *error) {
        if (route) {
            Route *newRoute = [Route new];
            newRoute.source = sourceAnnotaion;
            destinationAnnotation.subtitle = [self stringFromTimeInterval:route.expectedTravelTime];
            newRoute.destination = destinationAnnotation;
            newRoute.routeOverlay = route.polyline;
            
            self.addressLabel.text = [NSString stringWithFormat:@"Address: %@", destinationMapItem.placemark.title];
            self.timeLabel.text = [NSString stringWithFormat:@"Expert Time: %@", [self stringFromTimeInterval:route.expectedTravelTime]];
            
            self.travelDetails.hidden = NO;
            [self setupWithNewRoute:newRoute];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                            message:@"Failed to find directions! Please try again."
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil];
            [alert show];
        }
        
        [self.activityIndicator stopAnimating];
    }];
}

- (void)obtainDirectionsFrom:(MKMapItem*)from to:(MKMapItem*)to completion:(void(^)(MKRoute *route, NSError *error))completion {
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    
    request.source = from;
    request.destination = to;
    
    request.transportType = MKDirectionsTransportTypeAutomobile;
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        MKRoute *route = nil;
        
        if (response.routes.count > 0) {
            route = [response.routes firstObject];
        } else if (!error) {
            error = [NSError errorWithDomain:@"com.SSS.ProjectNavigator" code:404 userInfo:@{NSLocalizedDescriptionKey:@"No routes found!"}];
        }
        
        if (completion) {
            completion(route, error);
        }
    }];
}

- (void)setupWithNewRoute:(Route*)route {
    if (_route) {
        [self.mapView removeAnnotations:@[_route.source, _route.destination]];
        [_mapView removeOverlays:@[_route.routeOverlay]];
        _route = nil;
    }
    
    _route = route;
    
    [_mapView addAnnotations:@[route.source, route.destination]];
    [_mapView addOverlay:route.routeOverlay level:MKOverlayLevelAboveRoads];
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
    self.searchBar.text = _lastSearchString;
    
    [self getAutoCompleteDataWithLocationName:_lastSearchString];
    
    self.autoCompleteTableView.hidden = NO;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getAutoCompleteDataWithLocationName:) object:_lastSearchString];
    
    _lastSearchString = searchText;
    
    [self performSelector:@selector(getAutoCompleteDataWithLocationName:) withObject:searchText afterDelay:0.3];
}

#pragma mark - Autocomplete TableView Support

- (void)didSelectAutoCompleteRow:(NSNotification *)notification {
    if ([notification.name isEqualToString:kNotificationAutoCompleteRowSelected]) {
        [self.searchBar resignFirstResponder];
        MKMapItem *mapItem = notification.userInfo[kNotificationAutoCompleteRowSelected];
        
        [self.autoCompleteTableView setHidden:YES];
        
        //Setup route to the choosen location
        [self.activityIndicator startAnimating];
        [self calculateRouteToMapItem:mapItem];
    }
}

- (void)getAutoCompleteDataWithLocationName:(NSString *)searchString {
    if (searchString.length == 0)
        return;
    
    [self.activityIndicator startAnimating];
    
    MKLocalSearchRequest *searchRequest = [[MKLocalSearchRequest alloc] init];
    searchRequest.naturalLanguageQuery = searchString;
    
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:searchRequest];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        if (response.mapItems.count > 0) {
            [self resizeAutoCompleteTableViewToFitNumberOfItems:response.mapItems.count];
            [self.autoCompleteTableView setDataArray:response.mapItems];
        }
        
        [self.activityIndicator stopAnimating];
    }];
}

- (void)resizeAutoCompleteTableViewToFitNumberOfItems:(NSInteger)numOfRow {
    CGFloat estimateHeight = numOfRow * 40;
    CGFloat newHeigh = estimateHeight > _autoCompleteTableViewHeight ? _autoCompleteTableViewHeight : estimateHeight;
    
    self.autoCompleteTableView.frame = CGRectMake(self.autoCompleteTableView.frame.origin.x,
                                                  self.autoCompleteTableView.frame.origin.y,
                                                  self.autoCompleteTableView.frame.size.width,
                                                  newHeigh);
}

#pragma mark - Others Support

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    
    if (!hours && !minutes && !seconds) {
        return @"";
    } else if (!hours && !minutes) {
        return [NSString stringWithFormat:@"%02ld seconds", (long)seconds];
    } else if (!hours) {
        return [NSString stringWithFormat:@"%02ld:%02ld minutes", (long)minutes, (long)seconds];
    } else {
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld hours", (long)hours, (long)minutes, (long)seconds];
    }
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

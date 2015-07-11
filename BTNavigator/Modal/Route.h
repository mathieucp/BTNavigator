//
//  Route.h
//  BTNavigator
//
//  Created by Tu Nguyen on 7/11/15.
//  Copyright (c) 2015 TDStudio. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MKPointAnnotation;
@class MKPolyline;

@interface Route : NSObject

@property (nonatomic, strong) MKPointAnnotation *source;
@property (nonatomic, strong) MKPointAnnotation *destination;
@property (nonatomic, strong) MKPolyline *routeOverlay;

@end

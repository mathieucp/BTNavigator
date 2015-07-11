//
//  BTAutoCompleteTableView.h
//  FreeMusic
//
//  Created by Tu Nguyen on 6/25/15.
//  Copyright (c) 2015 TDStudio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BTAutoCompleteTableView : UITableView <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray *dataArray;

@end

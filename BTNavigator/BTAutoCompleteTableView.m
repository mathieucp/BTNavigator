//
//  BTAutoCompleteTableView.m
//  FreeMusic
//
//  Created by Tu Nguyen on 6/25/15.
//  Copyright (c) 2015 TDStudio. All rights reserved.
//

#import "BTAutoCompleteTableView.h"

@implementation BTAutoCompleteTableView

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
        
        [self registerClass:[UITableViewCell class] forCellReuseIdentifier:@"autocompleteCell"];
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.scrollEnabled = YES;
        self.hidden = YES;
    }
    
    return self;
}

- (void)setDataArray:(NSArray *)dataArray {
    _dataArray = nil;
    _dataArray = dataArray;
    [self reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"autocompleteCell" forIndexPath:indexPath];
    
    //cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.textLabel.text = self.dataArray[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationAutoCompleteRowSelected
//                                                        object:nil
//                                                      userInfo:@{kNotificationAutoCompleteRowSelected:indexPath}];
}

@end

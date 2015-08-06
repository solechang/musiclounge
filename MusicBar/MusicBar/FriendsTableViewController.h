//
//  iLLFriendsTableViewController.h
//  iLList
//
//  Created by Jake Choi on 1/14/15.
//  Copyright (c) 2015 iLList. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

#import "UIScrollView+EmptyDataSet.h"

@interface FriendsTableViewController : UITableViewController <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UISearchBarDelegate, UISearchControllerDelegate>

@end

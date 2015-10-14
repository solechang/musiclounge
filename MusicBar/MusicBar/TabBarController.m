//
//  TabBarController.m
//  MusicLounge
//
//  Created by Jake Choi on 10/6/15.
//  Copyright © 2015 Sole Chang. All rights reserved.
//

#import "TabBarController.h"

@interface TabBarController ()

@end

@implementation TabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setDelegate:self];
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

//- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
//{
//    
////    if (viewController.navigation)
//    NSLog(@"1.) %lu", tabBarController.selectedViewController.childViewControllers.count);
//    NSLog(@"2.) %@", viewController.childViewControllers.description);
//    
//    return (viewController != tabBarController.selectedViewController);
//}


@end

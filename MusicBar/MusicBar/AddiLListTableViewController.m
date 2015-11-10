//
//  iLLAddiLListTableViewController.m
//  MusicLounge
//
//  Created by Chang Choi on 12/17/14.
//  Copyright (c) 2014 MusicLounge. All rights reserved.
//

#import "AddiLListTableViewController.h"
#import <Parse/Parse.h>
#import <SVProgressHUD/SVProgressHUD.h>

// CoreData
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"
#import "Playlist.h"

@interface AddiLListTableViewController () {
    
    NSManagedObjectContext *defaultContext;
}
// iLList = Lounge
@property (weak, nonatomic) IBOutlet UITextField *iLListName;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;

@end

@implementation AddiLListTableViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setUpNavigationBar];

    [self setNSManagedObjectContext];
    self.iLListName.delegate = self;
   
}

-(void) setUpNavigationBar{
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:(49/255.0) green:(17/255.0f) blue:(65/255.0f) alpha:1];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];

    
    [self.tabBarController.tabBar setTintColor:[UIColor whiteColor]];
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
     [self.iLListName becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setNSManagedObjectContext {
    
    defaultContext = [NSManagedObjectContext MR_defaultContext];
    
}

#pragma mark - Buttons
- (IBAction)backButton:(id)sender {
    
    [self.iLListName resignFirstResponder];
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void) setButtonsEnabled {
    [self.doneButton setEnabled:YES];
    [self.backButton setEnabled:YES];
}

- (IBAction)doneButton:(id)sender {
    
    [self.doneButton setEnabled:NO];
    [self.backButton setEnabled:NO];
    [self.iLListName resignFirstResponder];
    
    // Check if there are any characters in the lounge's text field
    if ([self.iLListName.text isEqualToString:@""]) {
        
        // Show error
        [SVProgressHUD showErrorWithStatus:@"Please enter your lounge name"];
        [self setButtonsEnabled];
        
    } else {
     
        [self checkIfPlayListNameIsTooLong];
        
    }
    

            
}

- (void) checkIfPlayListNameIsTooLong {

    // Check if lounge name is too long
    if ([self.iLListName.text length] < 30) {
        
        [self savePlaylistToServer];
        
    } else {
   
        // Show error
        [SVProgressHUD showErrorWithStatus:@"Your Lounge name is too long. It has to be less than 30 characters"];
        [self setButtonsEnabled];
        
        
    }

}


- (void) savePlaylistToServer{
    
    // A lounge is a iLList
    PFObject *iLList = [PFObject objectWithClassName:@"Illist"];
    CurrentUser *currentUser = [CurrentUser MR_findFirstInContext:defaultContext];
    
    iLList[@"userName"] = currentUser.name;

    iLList[@"iLListName"] = self.iLListName.text;

    iLList[@"userId"] = currentUser.userId;
    
    iLList[@"SongCount"] = @(0);
    
    // Setting privacy for accesing the parse object
    PFACL *defaultACL = [PFACL ACL];
    
    [defaultACL setPublicWriteAccess:YES];

    [defaultACL setPublicReadAccess:YES];
    
    iLList.ACL = defaultACL;
 
    // Creating a Parse Lounge object
    [iLList saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {

        if (!error) {
            
            [self savePlaylistToLocal:iLList];

        } else {
            // Show error
            NSString *errorString = [[NSString alloc] initWithFormat:@"%@", error.localizedDescription];
            [SVProgressHUD showErrorWithStatus:errorString];
            
            [self setButtonsEnabled];
        }
        
    }];
    

}


- (void) savePlaylistToLocal:(PFObject*)iLList {
    
    // create Playlist into local (core data)
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        CurrentUser *currentUser = [CurrentUser MR_findFirstInContext:localContext];

        Playlist *playlist = [Playlist MR_createEntityInContext:localContext];
        playlist.name = self.iLListName.text;
        playlist.objectId = iLList.objectId;
        playlist.updatedAt = iLList.updatedAt;

        playlist.userId = currentUser.userId;
        playlist.createdAt = iLList.createdAt;
        playlist.userName = [PFUser currentUser][@"name"];
        playlist.songCount = [NSNumber numberWithInt:0];
        
        
    } completion:^(BOOL success, NSError *error) {
        
        if (!error) {

            // Show Success
            NSString *successString = [[ NSString alloc] initWithFormat:@"Added %@", self.iLListName.text];
            [SVProgressHUD showSuccessWithStatus:successString];
            
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                
            }];
            
            
        } else {
            
            NSString *errorString = [[NSString alloc] initWithFormat:@"%@", error.localizedDescription];
            [SVProgressHUD showErrorWithStatus:errorString];

            [self setButtonsEnabled];
        }
        
        
    }];
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // Return the number of rows in the section.
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    return cell;
}

#pragma textfield delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.iLListName) {
        [textField resignFirstResponder];
        [self doneButton:self];
    }
    return YES;
}



@end

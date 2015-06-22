//
//  iLLProfilePictureTableViewController.m
//  iLList
//
//  Created by Jake Choi on 5/18/15.
//  Copyright (c) 2015 iLList. All rights reserved.
//

#import "iLLProfilePictureTableViewController.h"
#import <Parse/Parse.h>

// Core Data
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"
#import "UserFriendList.h"
#import "Friend.h"
#import "FriendPhonenumber.h"
#import "Playlist.h"
#import "Song.h"
#import "PlaylistFriend.h"
#import "SongFriend.h"
#import "NowPlaying.h"
#import "NowPlayingSong.h"

#import <SVProgressHUD/SVProgressHUD.h>

@interface iLLProfilePictureTableViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
        NSManagedObjectContext *defaultContext;
}
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@end

@implementation iLLProfilePictureTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void) setNSManagedObjectContext {
    
    defaultContext = [NSManagedObjectContext MR_defaultContext];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
 
    return @"Profile Picture";
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    
    if (indexPath.row == (NSInteger) 0) {
     
        [self getProfileImageWithImagePicker];
    }

}

#pragma marks - Getting Profile Image
- (void) getProfileImageWithImagePicker {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //You can retrieve the actual UIImage
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    //Or you can get the image url from AssetsLibrary
//    NSURL *path = [info valueForKey:UIImagePickerControllerReferenceURL];
    
    
    [SVProgressHUD showWithStatus:@"Saving Picture :)"];
    
    
    [picker dismissViewControllerAnimated:YES completion:^{
        [SVProgressHUD dismiss];
        
    }];

    

    [self savePictureToServer:image];
    
    
    
}

- (void) savePictureToServer: (UIImage*) image {
    
    NSData* imageData = UIImageJPEGRepresentation(image, 0.9);
    PFFile *imageFile = [PFFile fileWithData:imageData];
    
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (!error) {
            if (succeeded) {
                
                [self saveProfileImageToUserInServer: imageFile :image];
                
                
            } else {
                NSLog(@"Did not succeded 158");
            }
            
        } else {
            // Handle error
        }
    }];
    
}

- (void) saveProfileImageToUserInServer: (PFFile *) imageFile :(UIImage*) image{
    
    PFObject *profilePictureObject = [PFObject objectWithClassName:@"ProfilePicture" ];
    profilePictureObject[@"hostObjectId"] = [[PFUser currentUser] objectId];
    profilePictureObject[@"profilePic"] = imageFile;
    
    PFACL *defaultACL = [PFACL ACL];
    
    [defaultACL setPublicWriteAccess:YES];
    
    [defaultACL setPublicReadAccess:YES];
    
    profilePictureObject.ACL = defaultACL;
    
    [profilePictureObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (succeeded) {
            [self savePictureToLocal:image];
            
        } else {
            NSLog(@"Failed to save picture to CurrentUser in Server 180");
        }
        
        
    }];
    
    
}

- (void) savePictureToLocal:(UIImage*) image {
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        CurrentUser *currentUser = [CurrentUser MR_findFirstInContext:localContext];
        
        NSData* coreDataImage = UIImageJPEGRepresentation(image, 0.9);
        
        currentUser.profilePicture = coreDataImage;
        
    } completion:^(BOOL success, NSError *error) {
        
        if (!error) {
            if (success) {
                
                 [SVProgressHUD showSuccessWithStatus:@"Successfully saved Profile Picture :)"];
               
            } else {
                
            }
            
        } else {
            
        }
        
    }];
    

}



#pragma marks - Buttons
- (IBAction)saveButtonPressed:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
    
    
}



@end

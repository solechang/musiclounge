//
//  iLLFriendTabTheirCollectionViewController.m
//  iLList
//
//  Created by Jake Choi on 2/24/15.
//  Copyright (c) 2015 iLList. All rights reserved.
//

#import "iLLFriendTabTheirCollectionViewController.h"
#import "CSStickyHeaderFlowLayout.h"

#import "SCUI.h"

#import "iLLFriendSearchSongsTableViewController.h"
#import "DZNSegmentedControl.h"

#import "CSParallaxHeader.h"
#import "iLLmyPlaylistCollectionViewCell.h"
#import "iLLfollowingPlaylistCollectionViewCell.h"
#import "CollectionViewCell.h"

// CoreData
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"

#import "PlaylistFriend.h"
#import "SongFriend.h"

#import <SVProgressHUD/SVProgressHUD.h>

@interface iLLFriendTabTheirCollectionViewController ()   <UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate> {
    
    NSMutableArray* myiLListArray;
    
    // The iLList dictionary that contain's its info such as the created user's id, iLListName, the iLList's objectId
    NSMutableDictionary* iLListInfo;
    
    CGPoint swipeLocation ;
    NSIndexPath *swipedIndexPath ;
    UICollectionViewCell* swipedCell ;
    BOOL swipedCellPastHalfWay;
    
        NSManagedObjectContext *defaultContext;
    
        NSString *hostName;
}


@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) UINib *headerNib;
@property (nonatomic, strong) DZNSegmentedControl *control;
@property (nonatomic, strong) NSArray *menuItems;
@property (nonatomic, retain) UIImage *profilePictureImage;

@end

@implementation iLLFriendTabTheirCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.profilePictureImage = [UIImage imageNamed: @"placeholder.png"];
    
//    [self setUpNavigationBar];
    [self setUpCollectionView];
    [self setUpHeaderFlowLayout];
    
    [self setUpCell];
    
    [self setUpGesture];
    
    [self setNSManagedObjectContext];
    
    [self control];
    
    
    //IK - Offset the text on the back button
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -60)
                                                         forBarMetrics:UIBarMetricsDefault];
    
}

- (void) setNSManagedObjectContext {
    
    defaultContext = [NSManagedObjectContext MR_defaultContext];
}

- (void) setUpHeaderFlowLayout {
    CSStickyHeaderFlowLayout *layout = (id)self.collectionViewLayout;
    
    if ([layout isKindOfClass:[CSStickyHeaderFlowLayout class]]) {
        layout.parallaxHeaderReferenceSize = CGSizeMake(self.view.frame.size.width, 210);
        
        layout.parallaxHeaderMinimumReferenceSize = CGSizeMake(self.view.frame.size.width, 0);
        
        layout.itemSize = CGSizeMake(self.view.frame.size.width, layout.itemSize.height);
        
        layout.parallaxHeaderAlwaysOnTop = YES;
        
        // If we want to disable the sticky header effect
        layout.disableStickyHeaders = NO;
    }
}

- (void) testUser {
    
   NSArray *playlistsArrayInLocal = [PlaylistFriend MR_findByAttribute:@"userId" withValue:self.friendInfo.userId];
    NSLog(@"0.1.) playlist.count: %lu", (unsigned long)playlistsArrayInLocal.count);
}

- (void) viewWillDisappear:(BOOL)animated {
    [SVProgressHUD dismiss];
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if (viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count-2] == self) {
        
        // View is disappearing because a new view controller was pushed onto the stack
//        NSLog(@"New view controller was pushed");
        
    } else if ([viewControllers indexOfObject:self] == NSNotFound) {
        
        // View is disappearing because it was popped from the stack
//        NSLog(@"View controller was popped");
       
        [self deletePlaylistFriendInLocal];
    }
    
    
    
}

- (void) deletePlaylistFriendInLocal {
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        NSArray *playlistsArrayInLocal = [PlaylistFriend MR_findByAttribute:@"userId" withValue:self.friendInfo.userId inContext:localContext];
        
        for (PlaylistFriend *playlistToDelete in playlistsArrayInLocal) {
            [playlistToDelete MR_deleteEntity];
        }
        
    } completion:^(BOOL success, NSError *error) {
        
        if (success) {
            NSArray *playlistArray = [PlaylistFriend MR_findAllSortedBy:@"createdAt" ascending:NO inContext:defaultContext];
         
            myiLListArray = [[NSMutableArray alloc] initWithArray:playlistArray];
            
            [self.collectionView reloadData];
            
        } else {
   
        }
        
        
    }];
}

//added below
- (void)viewDidAppear:(BOOL)animated {
   
     [self userPlaylistLogic];
        
}

- (void) userPlaylistLogic {
    
    [self getProfilePicture];
    //    Basically only need to do:

    
    
}

- (void) getProfilePicture {
    [SVProgressHUD showWithStatus:@"Loading Profile"];
    
    PFQuery *query = [PFQuery queryWithClassName:@"ProfilePicture"];

    [query whereKey:@"hostObjectId" equalTo:self.friendInfo.userId];
    [query orderByDescending:@"createdAt"];
    
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
        if (!error) {
            
            PFFile *file = (PFFile *)object[@"profilePic"];
            
            [self getPhotoFile:file];
            
        } else {
            
            
            [self getPlaylistFromServer];
        }
        
    }];

    
}
- (void) getPhotoFile: (PFFile*)file {
    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        
        if (!error) {
            UIImage *image = [[UIImage alloc] initWithData:data];
            self.profilePictureImage = image;

        } else {
            
        }
        
        [self getPlaylistFromServer];
        

       
    }];
}

- (void) getPlaylistFromServer {
    
    /* If the local storage does not have the iLList, the PFObject of the iLList
     * is retrieved from Parse and saved into the local storage
     * For example, when the user deletes app, local storage will be empty, so we need
     * to fetch the playlists from the server of the current playlists and store the fetched objects
     * in the local storage as well
     *
     */
    

    
    PFQuery *updateQuery = [PFQuery queryWithClassName:@"Illist"];
    [updateQuery whereKey:@"userId" equalTo:self.friendInfo.userId];
    
    [updateQuery orderByDescending:@"createdAt"];
    
    [updateQuery findObjectsInBackgroundWithBlock:^(NSArray *playlists, NSError *error) {
   
        if (!error) {
   
            [self savePlaylistToLocal: playlists];
        }
        
    }];
    
}

- (void) savePlaylistToLocal: (NSArray*) playlists {
    
    myiLListArray = [[NSMutableArray alloc] init];
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        // clear myillist array
        //        [myiLListArray removeAllObjects];
        
        NSArray *playlistsArrayInLocal = [PlaylistFriend MR_findAllInContext:localContext];
        
        for (PFObject *playlistObject in playlists) {
            
            PlaylistFriend *playlist = [PlaylistFriend MR_createEntityInContext:localContext];
            playlist.userId = self.friendInfo.userId;
            playlist.name = playlistObject[@"iLListName"];
            playlist.objectId = playlistObject.objectId;

            playlist.userName = playlistObject[@"userName"];
            playlist.createdAt = playlistObject.createdAt;
            playlist.songCount = playlistObject[@"SongCount"];
            
            for (PlaylistFriend *playlistToDelete in playlistsArrayInLocal) {
                
                if ([playlist.objectId isEqualToString:playlistToDelete.objectId]) {
                    
                    playlist.updatedAt = playlistToDelete.updatedAt;
                    
                }
            }

        }
        for (PlaylistFriend *playlistToDelete in playlistsArrayInLocal) {
            [playlistToDelete MR_deleteEntityInContext:localContext];
        }
        
    } completion:^(BOOL success, NSError *error) {
        
        if (!error) {
            
            [self displayPlaylistFriend];
            
        } else {
            
            NSLog(@"No playlist changes 244");
            [self.collectionView reloadData];
            [SVProgressHUD dismiss];
            
        }
  
        
    }];

    
}

- (void) displayPlaylistFriend {
    NSArray *playlistArray = [PlaylistFriend MR_findAllSortedBy:@"createdAt" ascending:NO inContext:defaultContext];
    PlaylistFriend *friendName = [PlaylistFriend MR_findFirstByAttribute:@"userId" withValue:self.friendInfo.userId inContext:defaultContext];
    
    if (playlistArray.count != 0 ) {
        
        hostName = [[NSString alloc] initWithString:friendName.userName];
        myiLListArray = [[NSMutableArray alloc] initWithArray:playlistArray];
        [self setCountOnControl];
        
     
        
    }
    [self.collectionView reloadData];
    [SVProgressHUD dismiss];
    
  
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    [self getUserName];
}

- (void) setUpCollectionView {
    
    //    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    //    CGFloat screenScale = [[UIScreen mainScreen] scale];
    //    CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);

    //    NSLog(@"%f", screenSize.height);
    
    //    self.collectionView.contentSize = screenSize;
    
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.bounces = YES;
    self.collectionView.delaysContentTouches = NO;
    self.collectionView.directionalLockEnabled = YES;
    
    
}

-(void) setUpNavigationBar{
    
    NSDictionary *size = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Wisdom Script" size:24.0],NSFontAttributeName, nil];
    self.navigationController.navigationBar.topItem.title = @"MusicBar";
    self.navigationController.navigationBar.titleTextAttributes = size;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    
    
    [self.tabBarController.tabBar setTintColor:[UIColor whiteColor]];
    
}

- (void) getUserName {
  
        
        hostName = [[NSString alloc] initWithString:self.friendInfo.name];
        
        [self.collectionView reloadData];
   
    
}

-(void)setUpCell{
    //IK - registering custom cells into the collection view programmatically
    
    [self.collectionView registerNib:self.headerNib
          forSupplementaryViewOfKind:CSStickyHeaderParallaxHeader
                 withReuseIdentifier:@"header"];
    
    [self.collectionView registerClass:[UICollectionReusableView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:@"HeaderView"];
    
    [self.collectionView registerClass:[iLLmyPlaylistCollectionViewCell class]
            forCellWithReuseIdentifier:NSStringFromClass([iLLmyPlaylistCollectionViewCell class])];
    
    [self.collectionView registerClass:[iLLfollowingPlaylistCollectionViewCell class]
            forCellWithReuseIdentifier:NSStringFromClass([iLLfollowingPlaylistCollectionViewCell class])];
    
}

-(void)setUpGesture{
    //IK - registering gestures
    
    UIPanGestureRecognizer * handlePan=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
    [handlePan setDelegate:self];
    [handlePan setMaximumNumberOfTouches:1];
    [self.collectionView addGestureRecognizer:handlePan];
    
    
}

//added above

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    
    
    if (self) {
        
        self.headerNib = [UINib nibWithNibName:@"CSParallaxHeader" bundle:nil];
        
        
    }
    
    return self;
}

- (DZNSegmentedControl *)control
{
    if (!_control)
    {
//        _menuItems = @[[@"My Lounges" uppercaseString], [@"All Lounges" uppercaseString]];
        _menuItems = @[[@"Lounges" uppercaseString]];
        
        _control = [[DZNSegmentedControl alloc] initWithItems:self.menuItems];

        _control.selectedSegmentIndex = 0;
        _control.bouncySelectionIndicator = YES;
        
        _control.height = 54.0f;
        _control.width = self.view.bounds.size.width;
        _control.showsGroupingSeparators = YES;

        _control.tintColor = [UIColor colorWithRed:(202/255.0) green:(84/255.0) blue:(158/255.0) alpha:1];
        _control.hairlineColor = [UIColor grayColor];

        
        [_control addTarget:self action:@selector(selectedSegment:) forControlEvents:UIControlEventValueChanged];
    }
    return _control;
}

- (void) setCountOnControl {
    NSArray *playlistArray = [PlaylistFriend MR_findAllInContext:defaultContext];
    [_control setCount:[NSNumber numberWithUnsignedInteger:playlistArray.count] forSegmentAtIndex:0];
    
}

//Must implement switching the segmented control stuff
- (void)selectedSegment:(DZNSegmentedControl *)control
{
    [self.collectionView reloadData];
    
}


#pragma mark UICollectionViewDataSource


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}



- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    NSInteger count = 0;
    
    if (_control.selectedSegmentIndex == 0) {
        
        count = [myiLListArray count];
        return count;
        
    } else if (_control.selectedSegmentIndex == 1){
        
        //IK - Need to edit in the future to populate the number of playlists you're following
        
        count = 10;
        return count;
    }
    
    return 0;
    
}


//IK - CollectionViewCell Size
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return CGSizeMake(self.view.bounds.size.width, 54);
    
}



- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section{
    
    //    if (_control.selectedSegmentIndex == 0){
    //    return CGSizeMake(self.view.bounds.size.width, 50);
    //    }
    //
    //    else if (_control.selectedSegmentIndex == 1){
    //    return CGSizeMake(self.view.bounds.size.width, 50);
    //
    //    }
    
    return CGSizeMake(self.view.bounds.size.width, 54);
}



- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (self.control.selectedSegmentIndex == 0) {
        
        iLLmyPlaylistCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([iLLmyPlaylistCollectionViewCell class]) forIndexPath:indexPath];
        
        PlaylistFriend *playlist = [myiLListArray objectAtIndex:indexPath.row];
        
        NSString *iLListName = playlist.name;
        
        //        NSString *iLListCreator =[myiLListArray objectAtIndex:indexPath.row][@"userName"];
         NSString *iLListCreator = [NSString stringWithFormat:@"Song count: %@", playlist.songCount];
        
        cell.labelPlaylistTitle.text = iLListName;
        //        cell.labelPlaylistCreator.text = [NSString stringWithFormat:@"Created by: %@", iLListCreator];
        cell.labelPlaylistCreator.text = iLListCreator;
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(10, cell.contentView.frame.size.height - 1.0, cell.contentView.frame.size.width, 1)];
        
        CGFloat borderWidth = 0.1f;
        lineView.layer.borderWidth = borderWidth;
        lineView.backgroundColor = [UIColor lightGrayColor];
        [cell.contentView addSubview:lineView];

        return cell;
        
        
    } else if (self.control.selectedSegmentIndex == 1){
        
        //IK - Temporarily populating static cells; will import the list of playlists that the user is following
        
        iLLfollowingPlaylistCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([iLLfollowingPlaylistCollectionViewCell class]) forIndexPath:indexPath];        // -1 because of the buttonCell
        
        cell.labelPlaylistTitle.text = [NSString stringWithFormat:@"Following playlist"];
        cell.labelPlaylistCreator.text = [NSString stringWithFormat:@"Created by: Whoever"];
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(10, cell.contentView.frame.size.height - 1.0, cell.contentView.frame.size.width, 1)];
        
        CGFloat borderWidth = 0.1f;
        lineView.layer.borderWidth = borderWidth;
        lineView.backgroundColor = [UIColor lightGrayColor];
        [cell.contentView addSubview:lineView];

        return cell;
        
    }
    
    return nil;
}



- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        
        
        UICollectionViewCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                        withReuseIdentifier:@"HeaderView"
                                                                               forIndexPath:indexPath];
        
        //IK - Segmented Control in the header cell
        
        _control.frame = CGRectMake(0, 0, cell.bounds.size.width, cell.bounds.size.height);
        
        [cell addSubview: _control];
        
        //        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        ////        [button addTarget:self
        ////                   action:@selector(aMethod:)
        ////         forControlEvents:UIControlEventTouchUpInside];
        //        [button setTitle:@"Add New Lounge" forState:UIControlStateNormal];
        //        button.frame = CGRectMake(0, 0, cell.bounds.size.width, cell.bounds.size.height);
        //        [cell addSubview:button];
        
        return cell;
        
        
    }
    if ([kind isEqualToString:CSStickyHeaderParallaxHeader]) {
        
        
        CSParallaxHeader* cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                    withReuseIdentifier:@"header"
                                                                           forIndexPath:indexPath];
        
        cell.textLabelName.text = hostName;
        [cell.profileImage setImage: self.profilePictureImage];
        cell.profileImage.contentMode = UIViewContentModeScaleAspectFill;
        
        
//        [[cell addNewPlaylistButton] addTarget:self action:@selector(addNewLounge:) forControlEvents:UIControlEventTouchUpInside];
//        [[cell editProfileButton] addTarget:self action:@selector(editProfile:) forControlEvents:UIControlEventTouchUpInside];
        
        //         _control.frame = CGRectMake(0, 0, cell.bounds.size.width, cell.bounds.size.height);
        //         [cell.headerView addSubview: _control];
        
        return cell;
    }
    
    return nil;
}



- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.control.selectedSegmentIndex == 0) {
        
        [self performSegueWithIdentifier:@"iLListSegue" sender:self];
        
    }
    
    else if (self.control.selectedSegmentIndex == 1) {
        
    }
}



- (void)collectionView:(UICollectionView *)collectionView
didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    //    UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath:indexPath];
    //    cell.backgroundColor = nil;
}


- (void)collectionView:(UICollectionView *)collectionView
didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor lightGrayColor];
    
}



- (void)collectionView:(UICollectionView *)collectionView
didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.contentView.backgroundColor = nil;
    
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"iLListSegue"]) {
        
        // Get destination view
        iLLFriendSearchSongsTableViewController *ssc = [segue destinationViewController];
        
        // Initializing indexpath for the playlist cell
        NSIndexPath *selectedIndexPath = [[self.collectionView indexPathsForSelectedItems] objectAtIndex:0];
        
        PlaylistFriend *playlist = [myiLListArray objectAtIndex:selectedIndexPath.row];
        ssc.playlistInfo = playlist;
        
    }
    
}

-(IBAction) addNewLounge:(id) sender
{
    [self performSegueWithIdentifier:@"addNewPlaylist" sender:sender];
}
-(IBAction) editProfile:(id) sender
{
    [self performSegueWithIdentifier:@"editProfile" sender:sender];
}


#pragma mark - scroll view delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return YES;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return NO;
}

-(BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
    CGPoint translation = [gestureRecognizer translationInView:[self collectionView]];
    
    // Check for horizontal gesture
    if (fabs(translation.x) > fabs(translation.y)) {
        return YES;
    }
    
    return NO;
}

#pragma mark - horizontal pan gesture delegate

-(void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer {
    // 1
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        // if the gesture has just started, record the current centre location
        //
        self.collectionView.scrollEnabled = NO;
        swipeLocation = [gestureRecognizer locationInView:self.collectionView];
        swipedIndexPath = [self.collectionView indexPathForItemAtPoint:swipeLocation];
        swipedCell = [self.collectionView cellForItemAtIndexPath:swipedIndexPath];
        
    }
    
    // 2
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        // translate the center
        
        CGPoint translation = [gestureRecognizer translationInView:[self collectionView]];
        swipedCell.center = CGPointMake((swipedCell.bounds.size.width)/2 +translation.x, swipedCell.center.y);
        
        // determine whether the item has been dragged far enough to initiate a delete / complete
        
    }
    
    // 3
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        // the frame this cell would have had before being dragged
        
        [self animateForDeletingLounge];
        
    }
}
- (void) animateForDeletingLounge {
    CGRect originalFrame = CGRectMake(0, swipedCell.frame.origin.y,
                                      swipedCell.bounds.size.width, swipedCell.bounds.size.height);
    
    if(swipedCell.frame.origin.x < -swipedCell.frame.size.width / 4){
        
        swipedCellPastHalfWay = YES;
        
        if (_control.selectedSegmentIndex == 0){
            
            originalFrame = CGRectMake(-swipedCell.bounds.size.width, swipedCell.frame.origin.y,
                                       swipedCell.bounds.size.width, swipedCell.bounds.size.height);
            
            //                [self popAlertViewForMyLoungeDelete];
        }
        
        [UIView animateWithDuration:0.2
                         animations:^{
                             swipedCell.frame = originalFrame;
                         }
         ];
    }
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         swipedCell.frame = originalFrame;
                     }
     ];
    
    swipedCellPastHalfWay = NO;
    
    self.collectionView.scrollEnabled = YES;

}

- (void)popAlertViewForMyLoungeDelete{
    UIAlertView *deleteAlert = [[UIAlertView alloc]
                                initWithTitle:@"Delete?"
                                message:@"Are you sure you want to delete this playlist?"
                                delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [deleteAlert show];
    
}
- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    //IK - if user presses "YES" in the alert view
    if (buttonIndex == 1) {
        
//        [self deletePlaylist];
    }
    
    else if (buttonIndex == 0) {
        CGRect originalFrame = CGRectMake(0, swipedCell.frame.origin.y,
                                          swipedCell.bounds.size.width, swipedCell.bounds.size.height);
        [UIView animateWithDuration:0.2
                         animations:^{
                             swipedCell.frame = originalFrame;
                         }
         ];
        
    }
    
}

//- (void) deletePlaylist {
//    
//
//    
//    Playlist *playlistToDelete = [myiLListArray objectAtIndex:[swipedIndexPath row]];
//    
//    NSString* playlistObjectID = playlistToDelete.objectId;
//    PFQuery *deleteQuery = [PFQuery queryWithClassName:@"Illist"];
//    
//    [deleteQuery getObjectInBackgroundWithId:playlistObjectID block:^(PFObject *object, NSError *error) {
//        // deleted illist in server
//        if (!error) {
//            
//            [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//                
//                if( succeeded ) {
//                    
//                    
//                    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
//                        
//                        PlaylistFriend *deletePlaylist = [PlaylistFriend MR_findFirstByAttribute:@"objectId" withValue:playlistObjectID inContext:localContext];
//                        NSArray *deleteSongArray = [SongFriend MR_findByAttribute:@"playlistId" withValue:playlistObjectID inContext:localContext];
//                        
//                        for( SongFriend *deleteSong in deleteSongArray) {
//                            // TODO: Check for deleting songs after setting core data for searchsongsTVC
//                            if( deleteSong.playlistFriend == deletePlaylist ) {
//                                
//                                [deleteSong MR_deleteInContext:localContext];
//                            }
//                            
//                        }
//                        
//                        [deletePlaylist MR_deleteInContext:localContext];
//                        
//                        
//                    } completion:^(BOOL success, NSError *error) {
//                        
//                        if (success) {
//                            
//                            [myiLListArray removeObjectAtIndex:[swipedIndexPath row]];
//                            NSArray* indexPathsToRemove = [NSArray arrayWithObject:swipedIndexPath];
//                            [self.collectionView deleteItemsAtIndexPaths:indexPathsToRemove];
//                            
//                        } else {
//                            NSLog(@"743");
//                        }
//                        
//                        
//                    }];
//                    
//                } else {
//                    NSLog(@"Error in delete: clickedButtonAtIndex");
//                    
//                }
//                
//            }];
//            
//            
//        }
//        
//        
//    }];
//}



@end

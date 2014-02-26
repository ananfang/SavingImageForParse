//
//  ViewController.m
//  JustPic
//
//  Created by Fang Yung-An on 2014/2/26.
//  Copyright (c) 2014年 Openmouse Studio. All rights reserved.
//

#import "ViewController.h"

#import <Parse/Parse.h>
#import <Parse/PF_MBProgressHUD.h>

#import "CameraHelper.h"
#import "PFObjectImageCell.h"
#import "PhotoDetailViewController.h"

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate, PF_MBProgressHUDDelegate, CameraHelperDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) NSArray *imageIDs;
@property (strong, nonatomic) NSArray *imagePFObjects;

@property (strong, nonatomic) PF_MBProgressHUD *HUD;
@property (strong, nonatomic) PF_MBProgressHUD *refreshHUD;

- (void)uploadImage:(UIImage *)image;
- (void)downloadAllImages;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Register cell
    NSString *cellClassName = NSStringFromClass([PFObjectImageCell class]);
    UINib *cellNib = [UINib nibWithNibName:cellClassName bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:cellClassName];
    
    // Sign up a dummy user
    PFUser *currentUser = [PFUser currentUser];
    
    if (currentUser) {
        DLog(@"[%@ %@ %d] Already log in ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__);
        [self pressedRefresh:nil];
    } else {
        // Dummy username and password
        PFUser *user = [PFUser user];
        user.username = @"Openmouse";
        user.password = @"Studio";
        user.email = @"openmouse@me.com";
        
        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                DLog(@"[%@ %@ %d] Sign up successful ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__);
                [self pressedRefresh:nil];
            } else {
                [PFUser logInWithUsernameInBackground:user.username password:user.password block:^(PFUser *user, NSError *error) {
                    if (!error) {
                        DLog(@"[%@ %@ %d] Log in successful ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__);
                        [self pressedRefresh:nil];
                    } else {
                        DLog(@"[%@ %@ %d] Log in fail: %@ ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__, error);
                    }
                }];
            }
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Getters and Setters
- (void)setImagePFObjects:(NSArray *)imagePFObjects
{
    _imagePFObjects = imagePFObjects;
    
    if (imagePFObjects.count) {
        NSMutableArray *imageIDs = [NSMutableArray array];
        for (PFObject *eachObject in imagePFObjects) {
            [imageIDs addObject:eachObject.objectId];
        }
        
        self.imageIDs = [imageIDs copy];
    }
}

- (void)setImageIDs:(NSArray *)imageIDs
{
    if (![_imageIDs isEqualToArray:imageIDs]) {
        _imageIDs = imageIDs;
        
        [self.collectionView reloadData];
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.imagePFObjects.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PFObjectImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PFObjectImageCell class]) forIndexPath:indexPath];
    
    cell.imagePFObject = [self.imagePFObjects objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PFObjectImageCell *cell = (PFObjectImageCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    
    PhotoDetailViewController *photoDetailViewController = [[PhotoDetailViewController alloc] initWithNibName:nil bundle:nil];
    photoDetailViewController.selectedImage = cell.image;
    [self.navigationController pushViewController:photoDetailViewController animated:YES];
}

#pragma mark - PF_MBProgressHUDDelegate
- (void)hudWasHidden:(PF_MBProgressHUD *)hud
{
    // Remove HUD from screen when the HUD hides
    [hud removeFromSuperview];
    hud = nil;
}

#pragma mark - CameraHelperDelegate
- (void)cameraDidEndWithImage:(UIImage *)image
{
    DLog(@"[%@ %@ %d] %@ ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__, NSStringFromCGSize(image.size));
    
    if (image.size.width > 640.0) {
        CGFloat imageScale = 640.0 / image.size.width;
        CGSize targetSize = CGSizeMake(640.0, image.size.height * imageScale);
        
        UIGraphicsBeginImageContextWithOptions(targetSize, YES, 0);
        [image drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];
        UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        image = resizedImage;
    }
    
    [self uploadImage:image];
}

#pragma mark - Target-Action
- (IBAction)pressedRefresh:(UIBarButtonItem *)sender
{
    DLog(@"[%@ %@ %d] refresh ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__);
    
    // HUD
    self.refreshHUD = [[PF_MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:self.refreshHUD];
    self.refreshHUD.delegate = self;
    [self.refreshHUD show:YES];
    
    [self downloadAllImages];
}

- (IBAction)pressedCamera:(UIBarButtonItem *)sender
{
    [[CameraHelper sharedHelper] showImagePickerFromViewController:self];
}

#pragma mark
- (void)uploadImage:(UIImage *)image
{
    DLog(@"[%@ %@ %d] upload size: %@ ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__, NSStringFromCGSize(image.size));
    
    // Upload image
    NSData *imageData = UIImageJPEGRepresentation(image, .5);
    PFFile *imageFile = [PFFile fileWithName:@"photo.jpg" data:imageData];
    
    // HUD creation
    self.HUD = [[PF_MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:self.HUD];
    
    self.HUD.mode = PF_MBProgressHUDModeDeterminate;
    self.HUD.delegate = self;
    self.HUD.labelText = @"Uploading";
    [self.HUD show:YES];
    
    // Save PFFile
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            // Hid old HUD, show completed HUD
            [self.HUD hide:YES];
            
            self.HUD = [[PF_MBProgressHUD alloc] initWithView:self.view];
            [self.view addSubview:self.HUD];
            
            self.HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
            self.HUD.mode = PF_MBProgressHUDModeCustomView;
            self.HUD.delegate = self;
            
            // Create a PFObject around a PFFile and associate it with the current user
            PFObject *userPhoto = [PFObject objectWithClassName:@"UserPhoto"];
            [userPhoto setObject:imageFile forKey:@"imageFile"];
            
            // Set the access control list to current user for security purposes
            userPhoto.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
            
            PFUser *user = [PFUser currentUser];
            [userPhoto setObject:user forKey:@"user"];
            
            [userPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    DLog(@"[%@ %@ %d] upload photo successful ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__);
                    [self pressedRefresh:nil];
                } else {
                    DLog(@"[%@ %@ %d] error: %@ ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__, error);
                }
            }];
        } else {
            // HUD hide
            [self.HUD hide:YES];
            
            DLog(@"[%@ %@ %d] error: %@ ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__, error);
        }
    } progressBlock:^(int percentDone) {
        // update HUD progress
        self.HUD.progress = (float)percentDone / 100.0;
    }];
}

- (void)downloadAllImages
{
    PFQuery *query = [PFQuery queryWithClassName:@"UserPhoto"];
    PFUser *user = [PFUser currentUser];
    [query whereKey:@"user" equalTo:user];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [self.refreshHUD hide:YES];
        
        if (!error) {
            self.imagePFObjects = objects;
        } else {
            DLog(@"[%@ %@ %d] error: %@ ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__, error);
        }
        
    }];
}

@end
//
//  CameraHelper.m
//  DearDays
//
//  Created by Fang Yung-An on 2013/12/16.
//  Copyright (c) 2013年 Openmouse Studio. All rights reserved.
//

#import "CameraHelper.h"

// Private class for no status bar ImagePicker
@interface ImagePickerStatusBarHiddenController : UIImagePickerController
@end

@implementation ImagePickerStatusBarHiddenController
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return nil;
}
@end


static CameraHelper *_sharedHelper = nil;

@interface CameraHelper () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) ImagePickerStatusBarHiddenController *imagePicker;
@property (weak, nonatomic) id<CameraHelperDelegate> delegate;
@end

@implementation CameraHelper
+ (CameraHelper *)sharedHelper
{
    if (_sharedHelper == nil) {
        _sharedHelper = [[CameraHelper alloc] init];
        
        _sharedHelper.imagePicker = [[ImagePickerStatusBarHiddenController alloc] init];
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            _sharedHelper.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        }
        
        _sharedHelper.imagePicker.allowsEditing = NO;
        _sharedHelper.imagePicker.delegate = _sharedHelper;
    }
    
    return _sharedHelper;
}

#pragma mark - Public methods
- (BOOL)showImagePickerFromViewController:(UIViewController<CameraHelperDelegate> *)viewController
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO
        || viewController == nil) {
        DLog(@"[%@ %@ %d] Can't call image picker ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__);
        return NO;
    }
    
    DLog(@"[%@ %@ %d] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__, self.imagePicker);
    self.delegate = viewController;
    [viewController presentViewController:self.imagePicker animated:YES completion:nil];
    return YES;
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    DLog(@"[%@ %@ %d] cancel: %@ ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__, picker);
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    DLog(@"[%@ %@ %d] finish ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__);
    UIImage *originalImage, *editedImage, *imageToSave;
    
    editedImage = (UIImage *)[info objectForKey:UIImagePickerControllerEditedImage];
    originalImage = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    
    imageToSave = (editedImage) ? editedImage : originalImage;
    
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [self.delegate cameraDidEndWithImage:imageToSave];
    }];
}

#pragma mark - UINavigationControllerDelegate
@end
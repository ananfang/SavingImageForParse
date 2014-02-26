//
//  CameraHelper.h
//  DearDays
//
//  Created by Fang Yung-An on 2013/12/16.
//  Copyright (c) 2013年 Openmouse Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CameraHelperDelegate <NSObject>
@optional
- (void)cameraDidEndWithImage:(UIImage *)image;
@end

@interface CameraHelper : NSObject
+ (CameraHelper *)sharedHelper;
- (BOOL)showImagePickerFromViewController:(UIViewController<CameraHelperDelegate> *)viewController;
@end
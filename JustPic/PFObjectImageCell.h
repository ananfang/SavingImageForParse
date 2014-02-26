//
//  PFObjectImageCell.h
//  JustPic
//
//  Created by Fang Yung-An on 2014/2/26.
//  Copyright (c) 2014年 Openmouse Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Parse/Parse.h>

@interface PFObjectImageCell : UICollectionViewCell
@property (strong, nonatomic) PFObject *imagePFObject;
@property (strong, nonatomic, readonly) UIImage *image;
@end
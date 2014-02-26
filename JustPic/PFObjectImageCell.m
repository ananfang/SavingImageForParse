//
//  PFObjectImageCell.m
//  JustPic
//
//  Created by Fang Yung-An on 2014/2/26.
//  Copyright (c) 2014年 Openmouse Studio. All rights reserved.
//

#import "PFObjectImageCell.h"

@interface PFObjectImageCell ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) UIImage *image;
@end

@implementation PFObjectImageCell
#pragma mark - Getters and Setters
- (void)setImagePFObject:(PFObject *)imagePFObject
{
    _imagePFObject = imagePFObject;
    
    self.imageView.image = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PFFile *theImage = [imagePFObject objectForKey:@"imageFile"];
        NSData *imageData = [theImage getData];
        self.image = [UIImage imageWithData:imageData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = self.image;
        });
    });
}

@end
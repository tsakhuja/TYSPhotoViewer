//
//  TYSImageScrollView.h
//  ForagerDiary
//
//  Created by Tim Sakhuja on 7/28/13.
//  Copyright (c) 2013 Timothy Sakhuja. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TYSPhoto;

@interface TYSImageScrollView : UIScrollView

@property (nonatomic) NSUInteger index;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) TYSPhoto *photo;

- (void)setImage:(UIImage *)image;
- (void)toggleMaxMinZoomWithCenter:(CGPoint)center;
- (void)zoomToMinScale;


@end

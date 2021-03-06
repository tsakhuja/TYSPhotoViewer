//
//  TYSPhotoViewer.h
//  TYSPhotoViewer
//
//  Created by Timothy Sakhuja on 9/27/13.
//  Copyright (c) 2013 Timothy Sakhuja. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TYSPhotoViewer : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) NSArray *photos;
@property (nonatomic) NSInteger currentPhotoIndex;
@property (nonatomic, strong) NSString *titleName;

- (id)initWithPhotos:(NSArray *)photos;

@end

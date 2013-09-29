//
//  TYSPhoto.h
//  TYSPhotoViewer
//
//  Created by Timothy Sakhuja on 9/28/13.
//  Copyright (c) 2013 Timothy Sakhuja. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define TYSPHOTO_LOADING_COMPLETE_NOTIFICATION @"TYSPHOTO_LOADING_COMPLETE_NOTIFICATION"

@interface TYSPhoto : NSObject

@property (nonatomic, strong) UIImage *baseImage;

+ (TYSPhoto *)photoWithImage:(UIImage *)image;
+ (TYSPhoto *)photoWithFilePath:(NSString *)path;

- (id)initWithImage:(UIImage *)image;
- (id)initWithFilePath:(NSString *)path;

- (void)loadBaseImageAndNotify;

@end

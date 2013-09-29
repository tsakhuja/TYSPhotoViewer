//
//  TYSPhoto.m
//  TYSPhotoViewer
//
//  Created by Timothy Sakhuja on 9/28/13.
//  Copyright (c) 2013 Timothy Sakhuja. All rights reserved.
//

#import "TYSPhoto.h"

@interface TYSPhoto ()

@property (nonatomic, strong) NSString *imagePath;

@end

@implementation TYSPhoto

#pragma mark - Class methods

+ (TYSPhoto *)photoWithFilePath:(NSString *)path
{
    return [[TYSPhoto alloc] initWithFilePath:path];
}

+ (TYSPhoto *)photoWithImage:(UIImage *)image
{
    return [[TYSPhoto alloc] initWithImage:image];
}

#pragma mark - Init

- (id)initWithFilePath:(NSString *)path
{
    if ((self = [super init])) {
        self.imagePath = [path copy];
    }
    
    return self;
}

- (id)initWithImage:(UIImage *)image
{
    if ((self = [super init])) {
        self.baseImage = image;
    }
    
    return self;
}

#pragma mark - Image loading

- (void)loadBaseImageAndNotify
{
    if (self.baseImage) {
        [self imageLoadingComplete];
    } else if (self.imagePath) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self loadImageFromFile];
        });
    } else {
        self.baseImage = nil;
        [self imageLoadingComplete];
    }
}

- (void)loadImageFromFile
{
    @try {
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfFile:self.imagePath options:NSDataReadingUncached error:&error];
        if (!error) {
            self.baseImage = [UIImage imageWithData:data];
        }
    }
    @catch (NSException *exception) {
        self.baseImage = nil;
    }
    @finally {
        [self imageLoadingComplete];
    }
}

- (void)imageLoadingComplete
{
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    [[NSNotificationCenter defaultCenter] postNotificationName:TYSPHOTO_LOADING_COMPLETE_NOTIFICATION object:self];
}


@end

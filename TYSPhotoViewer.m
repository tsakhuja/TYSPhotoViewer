//
//  TYSPhotoViewer.m
//  TYSPhotoViewer
//
//  Created by Timothy Sakhuja on 9/27/13.
//  Copyright (c) 2013 Timothy Sakhuja. All rights reserved.
//

#import "TYSPhotoViewer.h"
#import "TYSImageScrollView.h"
#import "TYSPhoto.h"

#define kPaddingWidth 15

@interface TYSPhotoViewer ()

@property (nonatomic) NSUInteger lastViewedIndex;
@property (nonatomic, strong) NSTimer *controlVisibilityTimer;
@property (nonatomic, strong) UIGestureRecognizer *singleTapRecongnizer;
@property (nonatomic, strong) UIGestureRecognizer *doubleTapRecongnizer;
@property (nonatomic, strong) UIScrollView *containingScrollView;
@property (nonatomic, strong) NSArray *imageScrollViews;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation TYSPhotoViewer

- (id)init
{
    return nil;
}

- (id)initWithPhotos:(NSArray *)photos
{
    self = [super init];
    if (self) {
        self.photos = photos;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleTYSPhotoLoadingCompleteNotification:)
                                                     name:TYSPHOTO_LOADING_COMPLETE_NOTIFICATION
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self.navigationItem setTitle:self.titleName];
    
    // Create, configure, and add scrollview
    self.containingScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.containingScrollView.delegate = self;
	self.containingScrollView.pagingEnabled = YES;
	self.containingScrollView.delegate = self;
	self.containingScrollView.showsHorizontalScrollIndicator = NO;
	self.containingScrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.containingScrollView];
    
    // Create and add tap gesture recognizers
    UITapGestureRecognizer *singleTapRecongnizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControls)];
    [singleTapRecongnizer setNumberOfTapsRequired:1];
    [self.containingScrollView addGestureRecognizer:singleTapRecongnizer];
    self.singleTapRecongnizer = singleTapRecongnizer;
    
    UITapGestureRecognizer *doubleTap = [self doubleTapGestureRecognizer];
    self.doubleTapRecongnizer = doubleTap;
    [self.containingScrollView addGestureRecognizer:doubleTap];
    
    [self.singleTapRecongnizer requireGestureRecognizerToFail:self.doubleTapRecongnizer];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.frame = CGRectInset(self.view.frame, 50, 50);
    [self.view addSubview:activityIndicator];
    self.activityIndicator = activityIndicator;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self hideControlsAfterDelay];
    
    [self updateImageScrollViews];
    
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    // Increase width of scrollview to accommodate padding.
    CGRect scrollFrame = self.view.frame;
    scrollFrame.size.width += kPaddingWidth;
    [self.containingScrollView setFrame:scrollFrame];
    [self.containingScrollView setAutoresizesSubviews:NO];
    
    [self layoutImagesInContainingScrollView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Show controls
    [self setControlsHidden:NO animated:NO permanent:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Layout ScrollView with imageScrollViews.

- (void)layoutImagesInContainingScrollView
{
    // Indicate whether photos should be added for the first time or re-layed out
    BOOL shouldAddPhotos = YES;
    
    if (self.containingScrollView.subviews.count != 0) {
        shouldAddPhotos = NO;
    }
    
    if (self.photos == nil || [self.photos count] == 0 ) {
        return;
    }
    
    NSInteger imageCount = [self.photos count];
    NSMutableArray *imageScrollViews = [NSMutableArray arrayWithCapacity:imageCount];
    
    CGRect cRect = self.containingScrollView.frame;
    
    // Adjust width of image view to that of screen.
    cRect.size.width -= kPaddingWidth;
    
    // Create ImageScrollViews to add to scrollview
    if (shouldAddPhotos) {
        for (int i = 0; i < imageCount; i++) {
            TYSImageScrollView *imageScrollView = [[TYSImageScrollView alloc] initWithFrame:cRect];
            imageScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [imageScrollView setContentMode:UIViewContentModeScaleAspectFit];
            
            [imageScrollViews addObject:imageScrollView];
        }
    } else {
        imageScrollViews = [NSMutableArray arrayWithArray:self.containingScrollView.subviews];
    }
    
    // Set frames of imageScrollViews and add to scrollview if applicable.
    UIImageView *cView;
    for (int i = 0; i < imageScrollViews.count; i++){
        cView = [imageScrollViews objectAtIndex:i];
        [cView setFrame:cRect];
        
        if (shouldAddPhotos) {
            [self.containingScrollView addSubview:cView];
        }
        cRect.origin.x += cRect.size.width + kPaddingWidth;
    }
    self.containingScrollView.contentSize = CGSizeMake(imageScrollViews.count * (cRect.size.width) + (imageScrollViews.count) * kPaddingWidth, 0);
    
    // Scroll to photo that was tapped.
    self.containingScrollView.contentOffset = CGPointMake(self.currentPhotoIndex * (cRect.size.width + kPaddingWidth), 0);
    self.lastViewedIndex = self.currentPhotoIndex;
    
    self.imageScrollViews = [NSArray arrayWithArray:imageScrollViews];
    [self updateImageScrollViews];
}

#pragma mark - Supported orientation modes

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    self.currentPhotoIndex = self.lastViewedIndex;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark - ScrollViewDelegate methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	// Hide controls when dragging begins
	[self setControlsHidden:YES animated:YES permanent:NO];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    int page = [self currentPage:scrollView];
    if (self.lastViewedIndex != page) {
        [self.imageScrollViews[self.lastViewedIndex] zoomToMinScale];
    }
    
    self.lastViewedIndex = page;
    
    if (!((TYSImageScrollView *) self.imageScrollViews[page]).image) {
        [self.activityIndicator startAnimating];
    }
    [self updateImageScrollViews];    
}

- (int)currentPage:(UIScrollView *)scrollView
{
    CGFloat pageWidth = scrollView.frame.size.width;
    return floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
}

#pragma mark - Double tap gesture

- (UITapGestureRecognizer *)doubleTapGestureRecognizer
{
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleMaxMinZoomOfPhoto:)];
    tapRecognizer.numberOfTapsRequired = 2;
    tapRecognizer.numberOfTouchesRequired = 1;
    
    return tapRecognizer;
}

- (void)toggleMaxMinZoomOfPhoto:(UITapGestureRecognizer *)sender
{
    CGPoint location = [sender locationInView:self.view];
    TYSImageScrollView *imageView = [self.imageScrollViews objectAtIndex:self.lastViewedIndex];
    
    [imageView toggleMaxMinZoomWithCenter:location];
}

#pragma mark - UIImage loading

- (void)updateImageScrollViews
{
    int startIndex = [self currentPage:self.containingScrollView] - 1;
    for (int i = startIndex; i <= [self currentPage:self.containingScrollView] + 1; i++) {
        if (i < self.imageScrollViews.count && i >= 0) {
            TYSImageScrollView *scrollView = [self.imageScrollViews objectAtIndex:i];
            scrollView.photo =  self.photos[i];
            [self loadImageForImageScrollView:scrollView];
        }
    }
}

- (TYSImageScrollView *)scrollViewDisplayingPhoto:(TYSPhoto *)photo
{
    for (int i = 0; i < self.imageScrollViews.count; i++) {
        TYSImageScrollView *scrollView = [self.imageScrollViews objectAtIndex:i];
        if (scrollView.photo == photo) {
            return scrollView;
        }
    }
    return nil;
}

- (void)loadImageForImageScrollView:(TYSImageScrollView *)imageScrollView
{
    [imageScrollView.photo loadBaseImageAndNotify];
}

- (void)unloadImageAtIndex:(NSInteger)index
{
    if (index < self.imageScrollViews.count && index >= 0) {
        TYSImageScrollView *imageScrollView = [self.imageScrollViews objectAtIndex:index];
        
        imageScrollView.image = nil;
    }
}

#pragma mark - Control hiding/showing

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent
{
    [self cancelControlHiding];
    
    // Status Bar
    if ([UIApplication instancesRespondToSelector:@selector(setStatusBarHidden:withAnimation:)]) {
        [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:animated?UIStatusBarAnimationFade:UIStatusBarAnimationNone];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:UIStatusBarAnimationFade];
    }
    
    // Navigation bar
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.35];
    }
    CGFloat alpha = hidden ? 0 : 1;
	[self.navigationController.navigationBar setAlpha:alpha];
    
    if (animated) [UIView commitAnimations];
    
    if (!permanent) [self hideControlsAfterDelay];
}

- (void)cancelControlHiding {
	// If a timer exists then cancel and release
	if (_controlVisibilityTimer) {
		[_controlVisibilityTimer invalidate];
		_controlVisibilityTimer = nil;
	}
}

// Enable/disable control visiblity timer
- (void)hideControlsAfterDelay {
	if (![self areControlsHidden]) {
        [self cancelControlHiding];
		_controlVisibilityTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
	}
}

- (BOOL)areControlsHidden { return (self.navigationController.navigationBar.alpha == 0); }
- (void)hideControls { [self setControlsHidden:YES animated:YES permanent:NO]; }
- (void)toggleControls { [self setControlsHidden:![self areControlsHidden] animated:YES permanent:NO]; }

#pragma mark - Photo Loading

- (void)handleTYSPhotoLoadingCompleteNotification:(NSNotification *)notification
{
    TYSImageScrollView *scrollView;
    TYSPhoto *photo = [notification object];
    if ((scrollView = [self scrollViewDisplayingPhoto:photo])) {
        [self.activityIndicator stopAnimating];
        scrollView.image = photo.baseImage;
    }
}

@end

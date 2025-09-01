//
//  JDFlipNumberDigitView.m
//
//  Created by Markus Emrich on 26.02.11.
//  Copyright 2011 Markus Emrich. All rights reserved.
//
//

#import <QuartzCore/QuartzCore.h>

#import "JDFlipNumberDigitView.h"

#import "JDFlipNumberViewImageBundle.h"
#import "JDFlipNumberViewImageCache.h"
#import "JDFlipNumberViewImageSet.h"

static NSString *const kFlipAnimationKey = @"kFlipAnimationKey";
static CGFloat kFlipAnimationMinimumAnimationDuration = 0.05;
static CGFloat kFlipAnimationMaximumAnimationDuration = 0.70;

typedef NS_OPTIONS(NSInteger, JDFlipAnimationState) {
    JDFlipAnimationStateFirstHalf,
    JDFlipAnimationStateSecondHalf
};

@implementation JDFlipNumberDigitConfig


@end

@interface JDFlipNumberDigitView () <CAAnimationDelegate>

@property (nonatomic, strong) UIImageView *topImageView;
@property (nonatomic, strong) UIImageView *flipImageView;
@property (nonatomic, strong) UIImageView *bottomImageView;
@property (nonatomic, assign) JDFlipAnimationState animationState;
@property (nonatomic, assign) JDFlipAnimationType animationType;
@property (nonatomic, assign) NSInteger previousValue;
@property (nonatomic, copy) JDDigitAnimationCompletionBlock completionBlock;
@property (nonatomic, strong) JDFlipNumberViewImageBundle *imageBundle;

@property (nonatomic, strong) NSMutableArray *topImages;
@property (nonatomic, strong) NSMutableArray *bottomImages;
@property (nonatomic, readonly) CGSize imageSize;

@property (nonatomic, strong) NSArray<NSString *> *digits;

@property (nonatomic, strong) JDFlipNumberDigitConfig *config;

@end


@implementation JDFlipNumberDigitView

- (instancetype)initWithImageBundle:(JDFlipNumberViewImageBundle *)imageBundle;
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        // setup view
        _imageBundle = (imageBundle == nil
                        ? [JDFlipNumberViewImageBundle defaultImageBundle]
                        : imageBundle);
        [self initConfig];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initConfig];
    }
    return self;
}


- (instancetype)initWithConfig:(JDFlipNumberDigitConfig *)config
{
    self = [super initWithFrame:config.frame];
    if (self) {
        self.config = config;
        
        [self initConfig];
    }
    return self;
}


- (void)initConfig {
    self.backgroundColor = [UIColor clearColor];
    self.autoresizesSubviews = NO;
    
    self.topImages = [NSMutableArray new];
    self.bottomImages = [NSMutableArray new];
    self.digits = @[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
    [self prepareDigitImages];
    
    // default values
    _value = 0;
    _animationState = JDFlipAnimationStateFirstHalf;
    _animationDuration = kFlipAnimationMaximumAnimationDuration;
    
    [self setupImagesForImageBundle];
    [self initImagesAndFrames];
}

- (NSArray<UIImage *> *)textToHalfImages:(NSString *)text {
    // 1. 渲染整个 label 为 UIImage
    
    CGFloat kRatio = UIScreen.mainScreen.bounds.size.width / 375.0;
    CGRect frame = CGRectMake(0, 0, self.config.frame.size.width, self.config.frame.size.height);
    
    UIView *view = [UIView new];
    view.frame = frame;
    
    CGFloat space = self.config.space;
    UIColor *blockColor = self.config.blockColor;
    UIColor *bgColor = self.config.bgColor;
    UIColor *textColor = self.config.textColor;
    UIFont *font= self.config.font;
    CGSize size = self.config.frame.size;
    
    CGFloat layerHalfHeight = (frame.size.height - space)/2.0;
    
    CALayer *topLayer = [CALayer new];
    [view.layer addSublayer:topLayer];
    topLayer.frame = CGRectMake(0, 0, frame.size.width, layerHalfHeight);
    topLayer.backgroundColor = blockColor.CGColor;
    
    CALayer *mediumLayer = [CALayer new];
    [view.layer addSublayer:mediumLayer];
    mediumLayer.frame = CGRectMake(0, layerHalfHeight, frame.size.width, 2 * kRatio);
    mediumLayer.backgroundColor = bgColor.CGColor;

    CALayer *bottomLayer = [CALayer new];
    [view.layer addSublayer:bottomLayer];
    bottomLayer.frame = CGRectMake(0, (frame.size.height + space)/2.0, frame.size.width, layerHalfHeight);
    bottomLayer.backgroundColor = blockColor.CGColor;
    
    UILabel *label = [UILabel new];
    label.textAlignment = NSTextAlignmentCenter;
    label.frame = frame;
    label.font = font;
    label.textColor = textColor;

    label.text = text;
    [view addSubview:label];
    view.layer.cornerRadius = 2;
    view.layer.masksToBounds = true;
        
//    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *fullImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 2. 计算一半高度
    CGFloat halfHeight = fullImage.size.height / 2.0;
    CGFloat scale = fullImage.scale;
    

    // 3. 上半部分
    CGRect topRect = CGRectMake(0,
                                0,
                                fullImage.size.width * scale,
                                halfHeight * scale);
    CGImageRef topCGImage = CGImageCreateWithImageInRect(fullImage.CGImage, topRect);
    UIImage *topImage = [UIImage imageWithCGImage:topCGImage
                                            scale:scale
                                      orientation:fullImage.imageOrientation];
    CGImageRelease(topCGImage);
    
    // 4. 下半部分
    CGRect bottomRect = CGRectMake(0,
                                   halfHeight * scale,
                                   fullImage.size.width * scale,
                                   halfHeight * scale);
    CGImageRef bottomCGImage = CGImageCreateWithImageInRect(fullImage.CGImage, bottomRect);
    UIImage *bottomImage = [UIImage imageWithCGImage:bottomCGImage
                                               scale:scale
                                         orientation:fullImage.imageOrientation];
    CGImageRelease(bottomCGImage);
    
    return @[topImage, bottomImage];
}

- (void)prepareDigitImages {
    for (NSString *digit in self.digits) {
        NSArray<UIImage *> *images = [self textToHalfImages:digit];
        if (images.count == 2) {
            [self.topImages addObject:images[0]];
            [self.bottomImages addObject:images[1]];
        }
    }
}

- (void)initImagesAndFrames;
{
    // setup image views
        self.topImageView     = [[UIImageView alloc] initWithImage:self.topImages[0]];
    self.flipImageView     = [[UIImageView alloc] initWithImage:self.topImages[0]];
    self.bottomImageView = [[UIImageView alloc] initWithImage:self.bottomImages[0]];

    self.flipImageView.hidden = YES;
    
    // set z positions
    self.topImageView.layer.zPosition = -1;
    self.bottomImageView.layer.zPosition = -1;
    self.flipImageView.layer.zPosition = 0;
    
    // add image views
    [self addSubview:self.topImageView];
    [self addSubview:self.bottomImageView];
    [self addSubview:self.flipImageView];
    
    // setup default 3d transform
    [self setZDistance: (self.imageSize.height*2)*3];
    
    // setup frames
    CGSize size = self.imageSize;
    self.bottomImageView.frame = CGRectMake(0, size.height, size.width, size.height);
    super.frame = CGRectMake(0, 0, size.width, size.height*2);
}

#pragma mark image set access

- (void)setupImagesForImageBundle {
    // fallback to default image bundle
    if (_imageBundle == nil || nil == _imageBundle.imageBundlePath) {
        _imageBundle = [JDFlipNumberViewImageBundle defaultImageBundle];
    }

    // create & set images
    self.topImageView.image       = self.topImages[self.value];
    self.flipImageView.image   = self.topImages[self.value];
    self.bottomImageView.image = self.bottomImages[self.value];
}

- (JDFlipNumberViewImageSet *)imageSet {
    if (_imageBundle == nil) {
        return nil;
    }

    JDFlipNumberViewImageCache *cache = [JDFlipNumberViewImageCache sharedInstance];
    return [cache imageSetForImageBundle:_imageBundle];
}

- (CGSize)imageSize {
    UIImage *firstImg = self.topImages.firstObject;
    return firstImg.size;
}

#pragma mark -
#pragma mark layout

- (CGSize)sizeThatFits:(CGSize)aSize;
{
    CGSize imageSize = self.imageSize;
    
    CGFloat ratioW     = aSize.width/aSize.height;
    CGFloat origRatioW = imageSize.width/(imageSize.height*2);
    CGFloat origRatioH = (imageSize.height*2)/imageSize.width;
    
    if (ratioW>origRatioW) {
        aSize.width = aSize.height*origRatioW;
    } else {
        aSize.height = aSize.width*origRatioH;
    }
    
    if (!self.upscalingAllowed) {
        aSize = [self sizeWithMaximumSize:aSize];
    }
    
    return aSize;
}

- (CGSize)sizeWithMaximumSize:(CGSize)size;
{
    size.width  = MIN(size.width, self.imageSize.width);
    size.height = MIN(size.height, self.imageSize.height*2);
    return size;
}

- (void)setFrame:(CGRect)rect;
{
    rect.size = [self sizeThatFits:rect.size];
    [super setFrame:rect];
    
    // update imageView frames
    rect.origin = CGPointMake(0, 0);
    rect.size.height /= 2.0;
    self.topImageView.frame = rect;
    rect.origin.y += rect.size.height;
    self.bottomImageView.frame = rect;

    // update flip imageView frame
    [self updateFlipViewFrame];
    
    // reset Z distance
    [self setZDistance: self.frame.size.height*3];
}

- (void)setZDistance:(NSInteger)zDistance;
{
    _zDistance = zDistance;
    
    // setup 3d transform
    CATransform3D aTransform = CATransform3DIdentity;
    aTransform.m34 = -1.0 / zDistance;
    self.layer.sublayerTransform = aTransform;
}

#pragma mark value setter

- (void)setValue:(NSInteger)value {
    [self setValueAnimated:value animationType:JDFlipAnimationTypeNone completion:nil];
}

- (void)setValueAnimated:(NSInteger)value
           animationType:(JDFlipAnimationType)animationType
              completion:(JDDigitAnimationCompletionBlock _Nullable)completionBlock {
    // copy completion block
    self.completionBlock = completionBlock;
    
    // save previous value
    self.previousValue = self.value;
    NSInteger newValue = value % 10;

    // update animation type
    self.animationType = animationType;
    BOOL animated = (animationType != JDFlipAnimationTypeNone);
    
    // save new value
    _value = newValue;
    
    [self updateImagesAnimated:animated];
}

#pragma mark -
#pragma mark animation

- (void)updateImagesAnimated:(BOOL)animated
{
    if (!animated || self.animationDuration < kFlipAnimationMinimumAnimationDuration) {
        // show new value
        self.topImageView.image       = self.topImages[self.value];
        self.flipImageView.image   = self.topImages[self.value];
        self.bottomImageView.image = self.bottomImages[self.value];
        
        // reset state
        self.flipImageView.hidden = YES;
        
        // call completion immediatly
        if (self.completionBlock) {
            JDDigitAnimationCompletionBlock completion = self.completionBlock;
            self.completionBlock = nil;
            completion(YES);
        }
    } else {
        self.animationState = JDFlipAnimationStateFirstHalf;
        [self runAnimation];
    }
}

- (void)runAnimation;
{
    [self updateFlipViewFrame];
    
    BOOL isTopDown = self.animationType == JDFlipAnimationTypeTopDown;
    
    // setup animation
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.duration    = MIN(kFlipAnimationMaximumAnimationDuration/2.0,self.animationDuration/2.0);
    animation.delegate    = self;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    
    // exchange images & setup animation
    if (self.animationState == JDFlipAnimationStateFirstHalf) {
        // remove any old animations
        [self.flipImageView.layer removeAllAnimations];
        
        // setup first animation half
        self.topImageView.image       = self.topImages[isTopDown ? self.value : self.previousValue];
        self.flipImageView.image   = isTopDown ? self.topImages[self.previousValue] : self.bottomImages[self.previousValue];
        self.bottomImageView.image = self.bottomImages[isTopDown ? self.previousValue : self.value];
        
        animation.fromValue    = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0, 1, 0, 0)];
        animation.toValue   = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(isTopDown ? -M_PI_2 : M_PI_2, 1, 0, 0)];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    } else {
        // setup second animation half
        if (isTopDown) {
            self.flipImageView.image = self.bottomImages[self.value];
        } else {
            self.flipImageView.image = self.topImages[self.value];
        }
        
        animation.fromValue    = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(isTopDown ? M_PI_2 : -M_PI_2, 1, 0, 0)];
        animation.toValue   = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0.0, 1, 0, 0)];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    }
    
    // add/start animation
    [self.flipImageView.layer addAnimation: animation forKey: kFlipAnimationKey];
    
    // show animated view
    self.flipImageView.hidden = NO;
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)finished
{
    if (!finished) {
        if (self.completionBlock) {
            JDDigitAnimationCompletionBlock completion = self.completionBlock;
            self.completionBlock = nil;
            completion(NO);
        }
        return;
    }
    
    if (self.animationState == JDFlipAnimationStateFirstHalf) {
        // do second animation step
        self.animationState = JDFlipAnimationStateSecondHalf;
        [self runAnimation];
    } else {
        // reset state
        self.animationState = JDFlipAnimationStateFirstHalf;
        
        // update images
        if(self.animationType == JDFlipAnimationTypeTopDown) {
            self.bottomImageView.image = self.bottomImages[self.value];
        } else {
            self.topImageView.image = self.topImages[self.value];
        }
        
        // remove old animation
        [self.flipImageView.layer removeAnimationForKey: kFlipAnimationKey];
        
        // hide animated view
        self.flipImageView.hidden = YES;
        
        // call completion block
        if (self.completionBlock) {
            JDDigitAnimationCompletionBlock completion = self.completionBlock;
            self.completionBlock = nil;
            completion(YES);
        }
    }
}

- (void)updateFlipViewFrame;
{
    if ((self.animationType == JDFlipAnimationTypeTopDown && self.animationState == JDFlipAnimationStateFirstHalf) ||
        (self.animationType == JDFlipAnimationTypeBottomUp && self.animationState == JDFlipAnimationStateSecondHalf)) {
        self.flipImageView.layer.anchorPoint = CGPointMake(0.5, 1.0);
        self.flipImageView.frame = self.topImageView.frame;
    } else {
        self.flipImageView.layer.anchorPoint = CGPointMake(0.5, 0.0);
        self.flipImageView.frame = self.bottomImageView.frame;
    }
}

@end


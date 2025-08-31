//
//  CALayer+HalfLayer.h
//  FlipNumberViewExample
//
//  Created by hlym on 2025/9/1.
//  Copyright © 2025 markusemrich. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CALayer (HalfLayer)

/// 创建一个上下半层的数字 Layer
+ (CALayer *)makeHalfLayerWithText:(NSString *)text
                           bgColor:(UIColor *)bgColor
                         isTopHalf:(BOOL)isTopHalf
           anchorPointKeepingFrame:(BOOL)anchorPointKeepingFrame
                             bounds:(CGRect)bounds
                               font:(UIFont *)font;

/// 根据文本生成上下双色、中间透明带的图片
+ (UIImage *)textToImageWithText:(NSString *)text
                             font:(UIFont *)font
                             size:(CGSize)size
                          bgColor:(UIColor *)bgColor
                        middleGap:(CGFloat)middleGap
                         textColor:(UIColor *)textColor;

@end

NS_ASSUME_NONNULL_END

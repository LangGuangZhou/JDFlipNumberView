//
//  CALayer+HalfLayer.m
//  FlipNumberViewExample
//
//  Created by hlym on 2025/9/1.
//  Copyright © 2025 markusemrich. All rights reserved.
//

#import "CALayer+HalfLayer.h"
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
// CALayer+HalfLayer.m
#import "CALayer+HalfLayer.h"

@implementation CALayer (HalfLayer)

+ (CALayer *)makeHalfLayerWithText:(NSString *)text
                           bgColor:(UIColor *)bgColor
                         isTopHalf:(BOOL)isTopHalf
           anchorPointKeepingFrame:(BOOL)anchorPointKeepingFrame
                             bounds:(CGRect)bounds
                               font:(UIFont *)font
{
    CALayer *halfLayer = [CALayer layer];
    CGFloat height = bounds.size.height / 2.0;
    halfLayer.frame = CGRectMake(0, isTopHalf ? 0 : height, bounds.size.width, height);
    
    UIImage *image = [self textToImageWithText:text font:font size:bounds.size bgColor:bgColor middleGap:2 textColor:[UIColor greenColor]];
    halfLayer.contents = (__bridge id _Nullable)(image.CGImage);
    
    // 只显示上下半部分
    halfLayer.contentsRect = CGRectMake(0, isTopHalf ? 0 : 0.5, 1, 0.5);
    
//    if (isTopHalf && anchorPointKeepingFrame) {
//        [halfLayer setAnchorPoint:CGPointMake(0.5, 1)];
//        // 如果需要保持 frame，可额外实现 setAnchorPointKeepingFrame 方法
//    }
    
    return halfLayer;
}

+ (UIImage *)textToImageWithText:(NSString *)text
                             font:(UIFont *)font
                             size:(CGSize)size
                          bgColor:(UIColor *)bgColor
                        middleGap:(CGFloat)middleGap
                         textColor:(UIColor *)textColor
{
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        CGContextRef ctx = context.CGContext;
        
        // 上半部分
        CGRect topRect = CGRectMake(0, 0, size.width, (size.height - middleGap)/2);
        CGContextSetFillColorWithColor(ctx, bgColor.CGColor);
        CGContextFillRect(ctx, topRect);
        
        // 下半部分
        CGRect bottomRect = CGRectMake(0, (size.height + middleGap)/2, size.width, (size.height - middleGap)/2);
        CGContextSetFillColorWithColor(ctx, bgColor.CGColor);
        CGContextFillRect(ctx, bottomRect);
        
        // 文本绘制（居中）
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        
        NSDictionary *attributes = @{
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: textColor,
            NSParagraphStyleAttributeName: paragraphStyle
        };
        
        CGSize textSize = [text sizeWithAttributes:attributes];
        CGRect textRect = CGRectMake((size.width - textSize.width)/2,
                                     (size.height - textSize.height)/2,
                                     textSize.width,
                                     textSize.height);
        
        [text drawInRect:textRect withAttributes:attributes];
    }];
    
    return image;
}

@end

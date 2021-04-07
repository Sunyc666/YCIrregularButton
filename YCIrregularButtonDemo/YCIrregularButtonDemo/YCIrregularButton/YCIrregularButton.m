//
//  YCIrregularButton.m
//  YCIrregularButton
//
//  Created by Sunyc on 2021/4/7.
//

#import "YCIrregularButton.h"

//最小可见阈值,配合不规则背景图片的边缘 alpha 使用.
//注意:如图片中间有 alpha ,请沟通好其值,并针对设置 kMinimumVisibilityThreshold
CGFloat const kMinimumVisibilityThreshold = 0.1f;

@interface YCIrregularButton()

@property (nonatomic, strong) UIImage *btnImg;
@property (nonatomic, strong) UIImage *btnBackgroundImg;

@property (nonatomic, assign) CGPoint previousTouchPoint;
@property (nonatomic, assign) BOOL previousTouchHitTestResponse;

@end

@implementation YCIrregularButton

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setup];
    }
    return self;
}

//如需在 xib 或 storyboard中使用,请将注释打开
- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    self.adjustsImageWhenHighlighted = NO;
    
    [self updateImageCacheForCurrentState];
    [self resetHitTestCache];
}

// 判断图片在此点区域是否是透明的
- (BOOL)isAlphaVisibleAtPoint:(CGPoint)point forImage:(UIImage *)image
{
    CGSize iSize = image.size;
    CGSize bSize = self.bounds.size;
    
    point.x *= (bSize.width != 0) ? (iSize.width / bSize.width) : 1;
    point.y *= (bSize.height != 0) ? (iSize.height / bSize.height) : 1;
    
    UIColor *pixelColor = [self colorAtPoint:point withimg:image];
    CGFloat alpha = 0.0;
    
    if ([pixelColor respondsToSelector:@selector(getRed:green:blue:alpha:)])
    {
        [pixelColor getRed:NULL green:NULL blue:NULL alpha:&alpha];
    }
    else
    {
        CGColorRef cgPixelColor = [pixelColor CGColor];
        alpha = CGColorGetAlpha(cgPixelColor);
    }
    return alpha >= kMinimumVisibilityThreshold;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL superResult = [super pointInside:point withEvent:event];
    
    if (!superResult) { return superResult; }
    
    if (CGPointEqualToPoint(point, self.previousTouchPoint))
    {
        return self.previousTouchHitTestResponse;
    }
    else
    {
        self.previousTouchPoint = point;
    }
    
    BOOL response = NO;
    
    if (self.btnImg == nil && self.btnBackgroundImg == nil)
    {
        response = YES;
        
    }
    else if (self.btnImg != nil && self.btnBackgroundImg == nil)
    {
        response = [self isAlphaVisibleAtPoint:point forImage:self.btnImg];
        
    }
    else if (self.btnImg == nil && self.btnBackgroundImg != nil)
    {
        response = [self isAlphaVisibleAtPoint:point forImage:self.btnBackgroundImg];
        
    }
    else
    {
        if ([self isAlphaVisibleAtPoint:point forImage:self.btnImg])
        {
            response = YES;
        }
        else
        {
            response = [self isAlphaVisibleAtPoint:point forImage:self.btnBackgroundImg];
        }
    }
    
    self.previousTouchHitTestResponse = response;
    return response;
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state
{
    [super setImage:image forState:state];
    [self updateImageCacheForCurrentState];
    [self resetHitTestCache];
}

- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state
{
    [super setBackgroundImage:image forState:state];
    [self updateImageCacheForCurrentState];
    [self resetHitTestCache];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self updateImageCacheForCurrentState];
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    [UIView transitionWithView:self duration:0.15 options:UIViewAnimationOptionCurveEaseOut animations:^{
        if (highlighted)
        {
            self.alpha = 0.5f;
        }
        else
        {
            self.alpha = 1.0f;
        }
    } completion:nil];
    
    [self updateImageCacheForCurrentState];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self updateImageCacheForCurrentState];
}


#pragma mark - Helper methods
- (void)updateImageCacheForCurrentState
{
    _btnBackgroundImg = [self currentBackgroundImage];
    _btnImg = [self currentImage];
}

- (void)resetHitTestCache
{
    self.previousTouchPoint = CGPointMake(CGFLOAT_MIN, CGFLOAT_MIN);
    self.previousTouchHitTestResponse = NO;
}

- (UIColor *)colorAtPoint:(CGPoint)point withimg:(UIImage *)currentImg
{
    // Cancel if point is outside image coordinates
    if (!CGRectContainsPoint(CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height), point)) { return nil; }
    
    NSInteger pointX = trunc(point.x);
    NSInteger pointY = trunc(point.y);
    CGImageRef cgImage = currentImg.CGImage;
    NSUInteger width = self.frame.size.width;
    NSUInteger height = self.frame.size.height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int bytesPerPixel = 4;
    int bytesPerRow = bytesPerPixel * 1;
    NSUInteger bitsPerComponent = 8;
    unsigned char pixelData[4] = { 0, 0, 0, 0 };
    CGContextRef context = CGBitmapContextCreate(pixelData,
                                                 1,
                                                 1,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    
    CGContextTranslateCTM(context, -pointX, pointY-(CGFloat)height);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, (CGFloat)width, (CGFloat)height), cgImage);
    CGContextRelease(context);
    
    // Convert color values [0..255] to floats [0.0..1.0]
    CGFloat red   = (CGFloat)pixelData[0] / 255.0f;
    CGFloat green = (CGFloat)pixelData[1] / 255.0f;
    CGFloat blue  = (CGFloat)pixelData[2] / 255.0f;
    CGFloat alpha = (CGFloat)pixelData[3] / 255.0f;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}


@end

#import "SDProgressBar.h"

NSString * const SDProgressBarKeyProgress = @"progress";
NSString * const SDProgressBarKeyBarColor = @"barColor";
NSString * const SDProgressBarKeyBarOutlineColor = @"outlineColor";
NSString * const SDProgressBarKeyBarIndeterminate = @"indeterminate";

@interface SDProgressBar ()
@property (strong, nonatomic) CALayer *barLayer;
@property (strong, nonatomic) CALayer *indeterminateLayer;
@end

@implementation SDProgressBar

#pragma mark Initialisation
- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super initWithCoder:decoder];
  if (self) [self configureView];
  return self;
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) [self configureView];
  return self;
}

#pragma mark Private methods
- (void)configureView
{
  // Defaults for colours
  self.barColor = [UIColor whiteColor];
  self.outlineColor = [UIColor clearColor]; // Default no outline
  self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];

  // Create and set the fixed properties of the bar layer used to show the progress
  self.barLayer = [CALayer layer];
  self.barLayer.backgroundColor = self.barColor.CGColor;
  [self.layer addSublayer:self.barLayer];

  // Add the bar mask ready to be used to reveal the progress
  CALayer *maskLayer = [CALayer layer];
  maskLayer.anchorPoint = CGPointMake(0, 0.5);
  maskLayer.backgroundColor = [UIColor blackColor].CGColor;
  self.barLayer.mask = maskLayer;

  // Configure the outline on the main layer
  self.layer.borderColor = self.outlineColor.CGColor;

  // Create the indeterminate layer and hide it by default
  self.indeterminateLayer = [CALayer layer];
  self.indeterminateLayer.masksToBounds = YES;
  self.indeterminateLayer.opacity = 0;
  [self.layer addSublayer:self.indeterminateLayer];

  // Add a layer ready to have the striped indeterminate background inserted into it
  [self.indeterminateLayer addSublayer:[CALayer layer]];

  // KVO the progress and colour properties
  [self addObserver:self forKeyPath:SDProgressBarKeyProgress options:NSKeyValueObservingOptionNew context:nil];
  [self addObserver:self forKeyPath:SDProgressBarKeyBarColor options:NSKeyValueObservingOptionNew context:nil];
  [self addObserver:self forKeyPath:SDProgressBarKeyBarOutlineColor options:NSKeyValueObservingOptionNew context:nil];
  [self addObserver:self forKeyPath:SDProgressBarKeyBarIndeterminate options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark Cleanup
- (void)dealloc
{
  [self removeObserver:self forKeyPath:SDProgressBarKeyProgress];
  [self removeObserver:self forKeyPath:SDProgressBarKeyBarColor];
  [self removeObserver:self forKeyPath:SDProgressBarKeyBarOutlineColor];
  [self removeObserver:self forKeyPath:SDProgressBarKeyBarIndeterminate];
}

#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
  if ([keyPath isEqualToString:SDProgressBarKeyProgress]) {
    CGFloat newProgress = [[change valueForKey:NSKeyValueChangeNewKey] floatValue];
    _progress = MIN(MAX(0, newProgress), 1); // Clamp 0..1

    // Calculate the width of the mask to reveal the bar underneath
    CGRect maskBounds = self.barLayer.mask.bounds;
    maskBounds.size.width = (self.progress * self.barLayer.bounds.size.width);
    self.barLayer.mask.bounds = maskBounds;
  } else if ([keyPath isEqualToString:SDProgressBarKeyBarColor]) {
    UIColor *color = [change valueForKey:NSKeyValueChangeNewKey];
    self.barLayer.backgroundColor = color.CGColor;
    CALayer *stripeLayer = [self.indeterminateLayer.sublayers lastObject];
    stripeLayer.backgroundColor = [self indeterminatePatternColor].CGColor;
  } else if ([keyPath isEqualToString:SDProgressBarKeyBarOutlineColor]) {
    UIColor *color = [change valueForKey:NSKeyValueChangeNewKey];
    self.layer.borderColor = color.CGColor;
  } else if ([keyPath isEqualToString:SDProgressBarKeyBarIndeterminate]) {
    BOOL isIndeterminate = [[change valueForKey:NSKeyValueChangeNewKey] boolValue];
    self.barLayer.opacity = isIndeterminate ? 0 : 1;
    self.indeterminateLayer.opacity = isIndeterminate ? 1 : 0;
  }
}

#pragma mark Layout
- (void)layoutSubviews
{
  const CGFloat outlineMinWidth = 1.8;
  const CGFloat outlineMaxWidth = 3.5;
  const CGFloat outlineWidthFactor = 0.05;

  [super layoutSubviews];

  CGFloat viewHeight = self.bounds.size.height;
  CGFloat viewWidth = self.bounds.size.width;

  // Configure the outline border for the main view layer
  self.layer.cornerRadius = viewHeight / 2;
  CGFloat outlineWidth = MIN(MAX(outlineMinWidth, viewHeight * outlineWidthFactor), outlineMaxWidth);
  self.layer.borderWidth = outlineWidth;

  // Calculate the scale factors for the bar to shrink it inside the outline with a gap
  CGFloat barHorizontalScaleFactor = (viewWidth - (outlineWidth * 4)) / viewWidth;
  CGFloat barVerticalScaleFactor = (viewHeight - (outlineWidth * 4)) / viewHeight;

  // Configure the progress bar layer
  CGFloat scaledWidth = viewWidth * barHorizontalScaleFactor;
  CGFloat scaledHeight = viewHeight * barVerticalScaleFactor;
  self.barLayer.bounds = CGRectMake(0, 0, scaledWidth, scaledHeight);
  self.barLayer.position = CGPointMake(viewWidth / 2, viewHeight / 2);
  self.barLayer.cornerRadius = scaledHeight / 2;

  // Position the indeterminate layer over the top of the regular progress bar layer
  self.indeterminateLayer.bounds = self.barLayer.bounds;
  self.indeterminateLayer.position = self.barLayer.position;
  self.indeterminateLayer.cornerRadius = self.barLayer.cornerRadius;

  // Configure the stripe layer to be slightly wider and have an image generated from the height of the indeterminate bar
  CALayer *stripeLayer = [self.indeterminateLayer.sublayers lastObject]; // Only one layer in the indeterminate layer
  stripeLayer.bounds = CGRectMake(0, 0, self.indeterminateLayer.bounds.size.width + self.indeterminateLayer.bounds.size.height, self.indeterminateLayer.bounds.size.height);
  stripeLayer.position = CGPointMake((self.indeterminateLayer.bounds.size.width / 2) - (self.indeterminateLayer.bounds.size.height / 2), self.indeterminateLayer.bounds.size.height / 2);
  stripeLayer.backgroundColor = [self indeterminatePatternColor].CGColor;

  // Restart the animation as the dimensions of the image may just have changed
  [stripeLayer removeAllAnimations];
  [stripeLayer addAnimation:[self animationForIndeterminateLayer:self.indeterminateLayer] forKey:nil];

  // Configure the mask ready for animating the reveal of the bar layer
  self.barLayer.mask.position = CGPointMake(0, scaledHeight / 2);
  self.barLayer.mask.bounds = CGRectMake(0, 0, self.progress * scaledWidth, scaledHeight);
}

#pragma mark Indeterminate image helpers
- (UIColor *)indeterminatePatternColor
{
  // Prevent trying to create a colour before the indeterminate later has been laid out
  if (self.indeterminateLayer.bounds.size.height <= 0) [self layoutIfNeeded];

  // Create the colour from a striped pattern image
  CGFloat patternHeight = self.indeterminateLayer.bounds.size.height;
  UIImage *patternImage = [self imageForIndeterminateBarWithHeight:patternHeight tintedWithColor:self.barColor];
  return [UIColor colorWithPatternImage:patternImage];
}

- (UIImage *)imageForIndeterminateBarWithHeight:(CGFloat)height tintedWithColor:(UIColor *)color;
{
  NSAssert(height > 0, @"Height of the indeterminate image must be greater than zero");
  
  // Make a square image the size of the height of the indeterminate bar
  CGRect imageRect = CGRectMake(0, 0, height, height);
  UIGraphicsBeginImageContextWithOptions(imageRect.size, YES, 0);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextTranslateCTM(context, 0, imageRect.size.height);
  CGContextScaleCTM(context, 1, -1);

  // Fill the whole image with the bar colour
  CGContextSetFillColorWithColor(context, color.CGColor);
  CGContextFillRect(context, CGRectInset(imageRect, -1, -1)); // Expanded 1pt to prevent edge gaps when tiling

  // Create the path of a parallelogram to become one stripe of many
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathMoveToPoint(path, nil, 0, 0);                                                       /*  __________  */
  CGPathAddLineToPoint(path, nil, imageRect.size.width / 2, imageRect.size.height);         /*  |\    \  |  */
  CGPathAddLineToPoint(path, nil, imageRect.size.width, imageRect.size.height);             /*  | \    \ |  */
  CGPathAddLineToPoint(path, nil, imageRect.size.width / 2, 0);                             /*  |__\____\|  */
  CGPathCloseSubpath(path);
  CGContextAddPath(context, path);

  // Should the tinted area darken or lighten the primary bar colour?
  CGFloat whiteValue = round(1 - [self colorBrightnessForColor:color]);
  CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:whiteValue alpha:0.2].CGColor);
  CGContextFillPath(context);
  CGPathRelease(path);

  // Grab the image and clean up
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

- (CGFloat)colorBrightnessForColor:(UIColor *)color
{
	NSInteger numberOfColorComponents = CGColorGetNumberOfComponents([color CGColor]);
  if (numberOfColorComponents == 2) { // Grayscale
    CGFloat white = 0;
    [color getWhite:&white alpha:nil];
    return white;
  } else if (numberOfColorComponents == 4) { // RGB compatible
    CGFloat red = 0, green = 0, blue = 0;
    [color getRed:&red green:&green blue:&blue alpha:nil];
    // Using algorithm from http://www.w3.org/WAI/ER/WD-AERT/#color-contrast
    return ((red * 299) + (green * 587) + (blue * 114)) / 1000;
  } else {
    NSAssert(NO, @"Unexpected number of components in colour space");
    return -1;
  }
}

- (CABasicAnimation *)animationForIndeterminateLayer:(CALayer *)layer
{
  const CGFloat animationTimeToHeightScaleFactor = 48; // Higher numbers for faster animation
  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
  animation.duration = layer.bounds.size.height / animationTimeToHeightScaleFactor;
  animation.byValue = @(layer.bounds.size.height);
  animation.repeatCount = HUGE_VALF;
  return animation;
}

@end

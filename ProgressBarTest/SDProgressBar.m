#import "SDProgressBar.h"

@interface SDProgressBar ()
@property (strong, nonatomic) CALayer *barLayer;
@end

@interface SDProgressBar (Private)
- (void)configureView;
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
  // Create and set the fixed properties of the bar layer used to show the progress
  self.barLayer = [CALayer layer];
  self.barLayer.backgroundColor = [UIColor whiteColor].CGColor;
  [self.layer addSublayer:self.barLayer];

  // Add the bar mask ready to be used to reveal the progress
  CALayer *maskLayer = [CALayer layer];
  maskLayer.anchorPoint = CGPointMake(0, 0.5);
  maskLayer.backgroundColor = [UIColor blackColor].CGColor;
  self.barLayer.mask = maskLayer;

  // Configure the outline on the main layer
  self.layer.backgroundColor = [UIColor blackColor].CGColor;
  self.layer.borderColor = [UIColor whiteColor].CGColor;

  // KVO the progress and colour properties
  [self addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:nil];
  [self addObserver:self forKeyPath:@"barColor" options:NSKeyValueObservingOptionNew context:nil];
  [self addObserver:self forKeyPath:@"outlineColor" options:NSKeyValueObservingOptionNew context:nil];
  [self addObserver:self forKeyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark KVO methods
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if ([keyPath isEqualToString:@"progress"]) {
    CGFloat newProgress = [[change valueForKey:NSKeyValueChangeNewKey] floatValue];
    _progress = MIN(MAX(0, newProgress), 1); // Clamp between 0..1

    // Calculate the width of the mask to reveal the bar underneath
    CGRect maskBounds = self.barLayer.mask.bounds;
    maskBounds.size.width = (self.progress * self.barLayer.bounds.size.width);
    self.barLayer.mask.bounds = maskBounds;
  } else if ([keyPath isEqualToString:@"barColor"]) {
    UIColor *color = [change valueForKey:NSKeyValueChangeNewKey];
    self.barLayer.backgroundColor = color.CGColor;
  } else if ([keyPath isEqualToString:@"outlineColor"]) {
    UIColor *color = [change valueForKey:NSKeyValueChangeNewKey];
    self.layer.borderColor = color.CGColor;
  } else if ([keyPath isEqualToString:@"backgroundColor"]) {
    UIColor *color = [change valueForKey:NSKeyValueChangeNewKey];
    self.layer.backgroundColor = color.CGColor;
  }
}

#pragma mark View layout
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

  // Configure the mask ready for animating the reveal of the bar layer
  self.barLayer.mask.position = CGPointMake(0, scaledHeight / 2);
  self.barLayer.mask.bounds = CGRectMake(0, 0, self.progress * scaledWidth, scaledHeight);
}

#pragma mark Dealloc
- (void)dealloc
{
  [self removeObserver:self forKeyPath:@"progress"];
  [self removeObserver:self forKeyPath:@"barColor"];
  [self removeObserver:self forKeyPath:@"outlineColor"];
  [self removeObserver:self forKeyPath:@"backgroundColor"];
}

@end

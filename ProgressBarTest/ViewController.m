#import "ViewController.h"

@implementation ViewController

#pragma mark View lifecycle
- (void)viewDidLoad
{
  [super viewDidLoad];

  [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(fireTimer:) userInfo:nil repeats:YES];
}

#pragma mark Timer
- (void)fireTimer:(NSTimer *)timer
{
  const NSInteger steps = 10;
  static NSInteger count = 0;
  count = ++count % (steps + 1);
  
  for (SDProgressBar *bar in self.progressBars) {
    bar.progress = (CGFloat)count / steps;
  }
}

#pragma mark Actions
- (IBAction)randomiseColoursButtonTapped:(id)sender
{
  for (SDProgressBar *bar in self.progressBars) {
    UIColor *randomColour = [self randomColor];
    bar.outlineColor = randomColour;
    bar.barColor = randomColour;
  }
}

- (IBAction)indeterminateSwitchValueChanged:(id)sender
{
  for (SDProgressBar *bar in self.progressBars) {
    bar.indeterminate = !bar.indeterminate;
  }
}

#pragma mark Helpers
- (UIColor *)randomColor
{
  CGFloat redValue = ((CGFloat)(arc4random() % 100)) / 100;
  CGFloat greenValue = ((CGFloat)(arc4random() % 100)) / 100;
  CGFloat blueValue = ((CGFloat)(arc4random() % 100)) / 100;
  return [UIColor colorWithRed:redValue green:greenValue blue:blueValue alpha:1];
}

@end

#import "ViewController.h"

@implementation ViewController

@synthesize progressBars = _progressBars;

#pragma mark - View lifecycle
- (void)viewDidLoad
{
  [super viewDidLoad];

  [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(fireTimer:) userInfo:nil repeats:YES];
}

- (UIColor *)randomColor
{
  CGFloat redValue = ((CGFloat)(arc4random() % 100)) / 100;
  CGFloat greenValue = ((CGFloat)(arc4random() % 100)) / 100;
  CGFloat blueValue = ((CGFloat)(arc4random() % 100)) / 100;
  return [UIColor colorWithRed:redValue green:greenValue blue:blueValue alpha:1];
}

- (void)viewDidUnload
{
  self.progressBars = nil;
  [super viewDidUnload];
}

- (void)fireTimer:(NSTimer *)timer
{
  const NSInteger steps = 10;
  static NSInteger count = 0;
  count = ++count % (steps + 1);
  
  for (SDProgressBar *bar in self.progressBars) {
    bar.progress = (CGFloat)count / steps;
  }
}

- (IBAction)randomiseColoursButtonTapped:(id)sender
{
  for (SDProgressBar *bar in self.progressBars) {
    bar.backgroundColor = [self randomColor];
    bar.outlineColor = [self randomColor];
    bar.barColor = [self randomColor];
  }
}

@end

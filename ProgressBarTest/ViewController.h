#import "SDProgressBar.h"

@interface ViewController : UIViewController

@property (strong, nonatomic) IBOutletCollection(SDProgressBar) NSArray *progressBars;

- (IBAction)randomiseColoursButtonTapped:(id)sender;

@end

@interface SDProgressBar : UIView

@property (assign, nonatomic) CGFloat progress;
@property (assign, nonatomic) BOOL indeterminate;
@property (strong, nonatomic) UIColor *barColor;
@property (strong, nonatomic) UIColor *outlineColor;

@end

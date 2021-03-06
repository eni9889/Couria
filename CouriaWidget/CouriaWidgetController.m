#import "CouriaWidgetController.h"
#import <QuartzCore/QuartzCore.h>

NSString *CouriaLocalizedString(NSString *string)
{
    return [[NSBundle bundleWithPath:@"/Library/WeeLoader/Plugins/CouriaWidget.bundle"]localizedStringForKey:string value:string table:nil];
}

@interface CouriaWidgetScrollView : UIScrollView

@property(copy) void (^highlightedBlock)(BOOL highlighted);
@property(copy) void (^actionBlock)(NSInteger index);

@end

@interface CouriaWidgetController () <UIScrollViewDelegate>

@property(retain) NSArray *applications;
@property(strong, nonatomic) UIView *view;
@property(strong, nonatomic) UIImageView *backgroundView;
@property(strong, nonatomic) CouriaWidgetScrollView *mainView;
@property(strong, nonatomic) UILabel *label;

@end

@implementation CouriaWidgetController

- (void)loadPlaceholderView
{
    _applications = [[NSClassFromString(@"Couria")sharedInstance]message:WidgetApplicationsMessage info:nil][ApplicationsKey];
    
    _view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, self.viewHeight)];
    _view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    CALayer *layer = _view.layer;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowRadius = 0;
    layer.shadowOffset = CGSizeZero;
    layer.shadowOpacity = 0;
    NSInteger scale = round([UIScreen mainScreen].scale);
    UIImage *backgroundImage = [(scale == 1 ? [UIImage imageWithData:[NSData dataWithContentsOfFile:@"/Library/WeeLoader/Plugins/CouriaWidget.bundle/WeeAppBackground.png"] scale:scale] : [UIImage imageWithData:[NSData dataWithContentsOfFile:@"/Library/WeeLoader/Plugins/CouriaWidget.bundle/WeeAppBackground@2x.png"] scale:scale])resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    _backgroundView = [[UIImageView alloc]initWithFrame:CGRectInset(_view.bounds, 2, 0)];
    _backgroundView.image = backgroundImage;
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth;
    _backgroundView.userInteractionEnabled = YES;
    _label = [[UILabel alloc]initWithFrame:_backgroundView.bounds];
    _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth;
    _label.backgroundColor = [UIColor clearColor];
    _label.text = _applications.count > 0 ? CouriaLocalizedString(@"TAP_TO_COMPOSE") : CouriaLocalizedString(@"NO_AVAILABLE_APPLICATIONS");
    _label.font = [UIFont boldSystemFontOfSize:16];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.textColor = [UIColor lightTextColor];
    _label.shadowColor = [UIColor blackColor];
    _label.shadowOffset = CGSizeMake(0, 1);
    _mainView = [[CouriaWidgetScrollView alloc]initWithFrame:_backgroundView.bounds];
    _mainView.delegate = self;
    _mainView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth;
    _mainView.scrollEnabled = _applications.count > 1;
    _mainView.pagingEnabled = YES;
    _mainView.alwaysBounceHorizontal = YES;
    _mainView.alwaysBounceVertical = NO;
    _mainView.showsHorizontalScrollIndicator = NO;
    _mainView.showsVerticalScrollIndicator = NO;
    [_backgroundView addSubview:_label];
    [_backgroundView addSubview:_mainView];
    [_view addSubview:_backgroundView];
    
    [_applications enumerateObjectsUsingBlock:^(NSString *identifier, NSUInteger index, BOOL *stop) {
        UIImageView *icon = [[UIImageView alloc]initWithImage:[UIImage _applicationIconImageForBundleIdentifier:identifier format:0 scale:[UIScreen mainScreen].scale]];
        [_mainView addSubview:icon];
        [icon sizeToFit];
    }];
    
    _mainView.highlightedBlock = ^(BOOL highlighted) {
        layer.shadowOpacity = highlighted * 0.7;
    };
    __weak NSArray *weakApplications = _applications;
    _mainView.actionBlock = ^(NSInteger index) {
        if (index < weakApplications.count) {
            [[NSClassFromString(@"Couria")sharedInstance]presentControllerForApplication:weakApplications[index] user:nil];
        }
    };
}

- (float)viewHeight
{
	return 37;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat period = scrollView.bounds.size.width;
    CGFloat x = scrollView.contentOffset.x;
    _label.alpha = 0.5 * cos(2*M_PI/period * x) + 0.5;    
}

@end

@implementation CouriaWidgetScrollView

- (void)layoutSubviews
{
    [super layoutSubviews];
    NSArray *views = self.subviews;
    CGSize viewSize = self.bounds.size;
    self.contentSize = CGSizeMake(viewSize.width * views.count, viewSize.height);
    [views enumerateObjectsUsingBlock:^(UIView *view, NSUInteger index, BOOL *stop) {
        view.center = CGPointMake(18 + viewSize.width * index, 18);
    }];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    if (_highlightedBlock) {
        _highlightedBlock(YES);
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    if (_highlightedBlock) {
        _highlightedBlock(YES);
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    if (_highlightedBlock) {
        _highlightedBlock(NO);
    }
    if (_actionBlock) {
        _actionBlock(round(self.contentOffset.x / self.frame.size.width));
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    if (_highlightedBlock) {
        _highlightedBlock(NO);
    }
}

@end

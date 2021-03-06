#import "CouriaImageView.h"

@implementation CouriaImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [_image drawInRect:rect];
}

@end

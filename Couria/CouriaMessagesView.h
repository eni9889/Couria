#import <UIKit/UIKit.h>

@class CouriaTheme;
@protocol CouriaMessagesViewDelegate;

@interface CouriaMessagesView : UITableView

- (id)initWithFrame:(CGRect)frame delegate:(id<CouriaMessagesViewDelegate>)delegate theme:(CouriaTheme *)theme;
- (void)setApplication:(NSString *)applicationIdentifier user:(NSString *)userIdentifier;
- (void)refreshData;
- (void)scrollToBottomAnimated:(BOOL)animated;

@end

@protocol CouriaMessagesViewDelegate <NSObject>

- (void)messagesView:(CouriaMessagesView *)messagesView didSelectMessage:(id<CouriaMessage>)message;

@end

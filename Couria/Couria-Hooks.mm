#import "CaptainHook/CaptainHook.h"
#import "CouriaController.h"

#pragma mark - Native

CHDeclareClass(SBBannerController)
CHOptimizedMethod(1, self, void, SBBannerController, _handleBannerTapGesture, UITapGestureRecognizer *, gestureRecognizer)
{
    BBBulletin *bulletin = self.currentBannerItem.seedBulletin;
    if (CouriaCanHandleBulletin(bulletin)) {
        CouriaHandleBulletin(bulletin);
    } else {
        CHSuper(1, SBBannerController, _handleBannerTapGesture, gestureRecognizer);
    }
}

CHDeclareClass(SBBulletinListController)
CHOptimizedMethod(2, self, void, SBBulletinListController, tableView, UITableView *, tableView, didSelectRowAtIndexPath, NSIndexPath *, indexPath)
{
    BBBulletin *bulletin = [self _bulletinAtIndexPath:indexPath];
    if (CouriaCanHandleBulletin(bulletin)) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        CouriaHandleBulletin(bulletin);
    } else {
        CHSuper(2, SBBulletinListController, tableView, tableView, didSelectRowAtIndexPath, indexPath);
    }
}
CHOptimizedMethod(1, self, void, SBBulletinListController, positionListViewAtY, CGFloat, y)
{
    CHSuper(1, SBBulletinListController, positionListViewAtY, y);
    CouriaController *currentController = CouriaCurrentController();
    if (currentController != nil) {
        [currentController.view endEditing:YES];
    }
}

CHDeclareClass(SBAlertItemsController)
CHOptimizedMethod(1, self, void, SBAlertItemsController, activateAlertItem, SBAlertItem *, alertItem)
{
    if ([alertItem isKindOfClass:NSClassFromString(@"SBBulletinModalAlert")]) {
        BBBulletin *bulletin = CHIvar(alertItem, _bulletin, BBBulletin *);
        if (!CouriaIsHandling() && CouriaCanHandleBulletin(bulletin)) {
            CouriaHandleBulletin(bulletin);
            return;
        }
    }
    CHSuper(1, SBAlertItemsController, activateAlertItem, alertItem);
}

CHDeclareClass(SBBulletinLockBar)
CHOptimizedMethod(0, self, void, SBBulletinLockBar, unlock)
{
    BBBulletin *bulletin = nil;
    SBAwayListActionContext *actionContext = nil;
    id delegate = CHIvar(self, _delegate, id);
    if ([delegate isKindOfClass:NSClassFromString(@"SBAwayBulletinCell")]) {
        SBAwayBulletinCell *bulletinCell = (SBAwayBulletinCell *)delegate;
        actionContext = bulletinCell.actionContext;
    }
    /*else if ([delegate isKindOfClass:NSClassFromString(@"SBAwayView")]) {
        SBAwayView *awayView = (SBAwayView *)delegate;
        actionContext = awayView.bulletinController.visibleActionContext;
    }*/
    if (actionContext != nil) {
        NSString *bulletinID = actionContext.bulletinID;
        SBAwayBulletinListController *bulletinController = [NSClassFromString(@"SBAwayController")sharedAwayController].awayView.bulletinController;
        bulletin = [[bulletinController _listItemContainingBulletinID:bulletinID]bulletinWithID:bulletinID];
    }
    if (CouriaCanHandleBulletin(bulletin)) {
        [self slideBack:YES];
        CouriaHandleBulletin(bulletin);
    } else {
        CHSuper(0, SBBulletinLockBar, unlock);
    }
}

static NSString *ApplicationIdentifierToOpen;
CHDeclareClass(SBAwayController)
CHMethod(1, void, SBAwayController, couria_unlockAndOpenApplication, NSString *, applicationIdentifier)
{
    ApplicationIdentifierToOpen = [applicationIdentifier retain];
    [[NSClassFromString(@"SBAwayController")sharedAwayController]unlockWithSound:NO];
}
CHOptimizedMethod(3, self, void, SBAwayController, willAnimateToggleDeviceLockWithStyle, NSInteger, style, toVisibility, BOOL, visibility, withDuration, double, duration)
{
    CHSuper(3, SBAwayController, willAnimateToggleDeviceLockWithStyle, style, toVisibility, visibility, withDuration, duration);
    if (visibility == NO) {
        ApplicationIdentifierToOpen = nil;
    }
}
CHOptimizedMethod(3, self, void, SBAwayController, _finishUnlockWithSound, BOOL, sound, unlockSource, NSInteger, source, isAutoUnlock, BOOL, autoUnlock)
{
    CHSuper(3, SBAwayController, _finishUnlockWithSound, sound, unlockSource, source, isAutoUnlock, autoUnlock);
    if (ApplicationIdentifierToOpen != nil) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
            [[UIApplication sharedApplication]launchApplicationWithIdentifier:ApplicationIdentifierToOpen suspended:NO];
            ApplicationIdentifierToOpen = nil;
        });
    }
}

static BBServer *BulletinBoardServer;
CHDeclareClass(BBServer)
CHClassMethod(0, BBServer *, BBServer, sharedInstance)
{
    return BulletinBoardServer;
}
CHOptimizedMethod(0, self, void, BBServer, _loadAllDataProviderPluginBundles)
{
    CHSuper(0, BBServer, _loadAllDataProviderPluginBundles);
    BulletinBoardServer = [self retain];
}
CHOptimizedMethod(3, self, void, BBServer, publishBulletin, BBBulletin *, bulletin, destinations, NSInteger, destinations, alwaysToLockScreen, BOOL, alwaysToLockScreen)
{
    CHSuper(3, BBServer, publishBulletin, bulletin, destinations, destinations, alwaysToLockScreen, alwaysToLockScreen);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        CouriaHandleNewBulletin(bulletin);
    });
}

CHDeclareClass(UIWindow)
CHOptimizedMethod(1, self, void, UIWindow, sendEvent, UIEvent *, event)
{
    CHSuper(1, UIWindow, sendEvent, event);
    SBAwayController *awayController = [NSClassFromString(@"SBAwayController")sharedAwayController];
    if (awayController.isLocked) {
        if (CouriaIsHandling()) {
            [awayController restartDimTimer:60];
        }
    }
}

CHDeclareClass(SBUIController)
CHOptimizedMethod(0, self, BOOL, SBUIController, clickedMenuButton)
{
    CouriaController *currentController = CouriaCurrentController();
    if (currentController != nil) {
        [currentController dismiss];
        return YES;
    } else {
        return CHSuper(0, SBUIController, clickedMenuButton);
    }
}

CHDeclareClass(SpringBoard);
CHOptimizedMethod(5, self, void, SpringBoard, _openURLCore, NSURL *, url, display, id, display, animating, BOOL, animating, sender, id, sender, additionalActivationFlags, id, flags)
{
    [CouriaCurrentController() dismiss];
    CHSuper(5, SpringBoard, _openURLCore, url, display, display, animating, animating, sender, sender, additionalActivationFlags, flags);
}

CHDeclareClass(UIPopoverController)
CHOptimizedMethod(1, self, void, UIPopoverController, _updateDimmingViewTransformForInterfaceOrientationOfHostingWindow, UIWindow *, hostingWindow)
{
    if (!(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && CouriaIsHandling())) {
        CHSuper(1, UIPopoverController, _updateDimmingViewTransformForInterfaceOrientationOfHostingWindow, hostingWindow);
    }
}

#pragma mark - Ayra

CHDeclareClass(AyraCenterDataSource)
CHOptimizedMethod(2, self, UITableViewCell *, AyraCenterDataSource, tableView, UITableView *, tableView, cellForRowAtIndexPath, NSIndexPath *, indexPath)
{
    AyraCenterListCell *cell = (AyraCenterListCell *)CHSuper(2, AyraCenterDataSource, tableView, tableView, cellForRowAtIndexPath, indexPath);
    return cell;
}
CHOptimizedMethod(1, self, void, AyraCenterDataSource, didDeleteRowAtIndexPath, NSIndexPath *, indexPath)
{
    BBBulletin *bulletin = CHIvar(self, bulletins, NSArray *)[indexPath.row];
    if (CouriaCanHandleBulletin(bulletin)) {
        CouriaMarkRead(bulletin.sectionID, CouriaGetUserIdentifier(bulletin));
        return;
    }
    CHSuper(1, AyraCenterDataSource, didDeleteRowAtIndexPath, indexPath);
}
CHOptimizedMethod(1, self, void, AyraCenterDataSource, didLaunchRowAtIndexPath, NSIndexPath *, indexPath)
{
    BBBulletin *bulletin = CHIvar(self, bulletins, NSArray *)[indexPath.row];
    if (CouriaCanHandleBulletin(bulletin)) {
        CouriaHandleBulletin(bulletin);
        return;
    }
    CHSuper(1, AyraCenterDataSource, didLaunchRowAtIndexPath, indexPath);
}

#pragma mark - IntelliScreenX

CHDeclareClass(IntelliScreenXDefaultHandler)
CHOptimizedMethod(0, self, int, IntelliScreenXDefaultHandler, buttonCount)
{
    if (CouriaCanHandleBulletin(self.currentBulletin)) {
        return 3;
    }
    return CHSuper(0, IntelliScreenXDefaultHandler, buttonCount);
}
CHOptimizedMethod(1, self, NSString *, IntelliScreenXDefaultHandler, titleForButton, int, index)
{
    if (CouriaCanHandleBulletin(self.currentBulletin)) {
        switch (index) {
            case 0:
                return CouriaLocalizedString(@"REPLY");
            case 1:
                return CouriaLocalizedString(@"READ");
            case 2:
                return CouriaLocalizedString(@"OPEN");
            default:
                return nil;
        }
    }
    return CHSuper(1, IntelliScreenXDefaultHandler, titleForButton, index);

}
CHOptimizedMethod(1, self, UIImage *, IntelliScreenXDefaultHandler, imageForButton, int, index)
{
    if (CouriaCanHandleBulletin(self.currentBulletin)) {
        switch (index) {
            case 0:
                return self.replyImage;
            case 1:
                return self.unreadImage;
            case 2:
                return self.openImage;
            default:
                return nil;
        }
    }
    return CHSuper(1, IntelliScreenXDefaultHandler, imageForButton, index);
}
CHOptimizedMethod(1, self, void, IntelliScreenXDefaultHandler, buttonClicked, UIButton *, button)
{
    if (CouriaCanHandleBulletin(self.currentBulletin)) {
        switch (button.tag) {
            case 0:
                CouriaHandleBulletin(self.currentBulletin);
                break;
            case 1:
                CouriaMarkRead(self.currentBulletin.sectionID, CouriaGetUserIdentifier(self.currentBulletin));
                break;
            case 2:
                CouriaOpenApp(self.currentBulletin.sectionID);
                break;
            default:
                break;
        }
        return;
    }
    CHSuper(1, IntelliScreenXDefaultHandler, buttonClicked, button);
}

#pragma mark - LockInfo

CHDeclareClass(LIBulletinListController)
CHOptimizedMethod(2, self, void, LIBulletinListController, tableView, UITableView *, tableView, didSelectRowAtIndexPath, NSIndexPath *, indexPath)
{
    BBBulletin *bulletin = [self _bulletinAtIndexPath:indexPath];
    if (CouriaCanHandleBulletin(bulletin)) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        CouriaHandleBulletin(bulletin);
        return;
    }
    CHSuper(2, LIBulletinListController, tableView, tableView, didSelectRowAtIndexPath, indexPath);
}

#pragma mark - Velox

CHDeclareClass(NotificationsFolderView)
CHOptimizedMethod(2, self, void, NotificationsFolderView, tableView, UITableView *, tableView, didSelectRowAtIndexPath, NSIndexPath *, indexPath)
{
    NSMutableArray *notifications = CHIvar(self, notifications, NSMutableArray *);
    if (notifications.count > indexPath.row) {
        BBBulletin *bulletin = notifications[indexPath.row];
        if (CouriaCanHandleBulletin(bulletin)) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            CouriaHandleBulletin(bulletin);
            return;
        }
    }
    CHSuper(2, NotificationsFolderView, tableView, tableView, didSelectRowAtIndexPath, indexPath);
}

CHConstructor
{
	@autoreleasepool {
        NSString *application = [NSBundle mainBundle].bundleIdentifier;
        if ([application isEqualToString:@"com.apple.springboard"]) {
            CHLoadLateClass(SBBannerController);
            CHHook(1, SBBannerController, _handleBannerTapGesture);
            CHLoadLateClass(SBBulletinListController);
            CHHook(2, SBBulletinListController, tableView, didSelectRowAtIndexPath);
            CHHook(1, SBBulletinListController, positionListViewAtY);
            CHLoadLateClass(SBAlertItemsController);
            CHHook(1, SBAlertItemsController, activateAlertItem);
            CHLoadLateClass(SBBulletinLockBar);
            CHHook(0, SBBulletinLockBar, unlock);
            CHLoadLateClass(SBAwayController);
            CHHook(1, SBAwayController, couria_unlockAndOpenApplication);
            CHHook(3, SBAwayController, willAnimateToggleDeviceLockWithStyle, toVisibility, withDuration);
            CHHook(3, SBAwayController, _finishUnlockWithSound, unlockSource, isAutoUnlock);
            CHLoadLateClass(BBServer);
            CHHook(0, BBServer, sharedInstance);
            CHHook(0, BBServer, _loadAllDataProviderPluginBundles);
            CHHook(3, BBServer, publishBulletin, destinations, alwaysToLockScreen);
            CHLoadLateClass(UIWindow);
            CHHook(1, UIWindow, sendEvent);
            CHLoadLateClass(SBUIController);
            CHHook(0, SBUIController, clickedMenuButton);
            CHLoadLateClass(SpringBoard);
            CHHook(5, SpringBoard, _openURLCore, display, animating, sender, additionalActivationFlags);
            CHLoadLateClass(UIPopoverController);
            CHHook(1, UIPopoverController, _updateDimmingViewTransformForInterfaceOrientationOfHostingWindow);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
                CHLoadLateClass(AyraCenterDataSource);
                CHHook(2, AyraCenterDataSource, tableView, cellForRowAtIndexPath);
                CHHook(1, AyraCenterDataSource, didDeleteRowAtIndexPath);
                CHHook(1, AyraCenterDataSource, didLaunchRowAtIndexPath);
                CHLoadLateClass(IntelliScreenXDefaultHandler);
                CHHook(0, IntelliScreenXDefaultHandler, buttonCount);
                CHHook(1, IntelliScreenXDefaultHandler, titleForButton);
                CHHook(1, IntelliScreenXDefaultHandler, imageForButton);
                CHHook(1, IntelliScreenXDefaultHandler, buttonClicked);
                CHLoadLateClass(LIBulletinListController);
                CHHook(2, LIBulletinListController, tableView, didSelectRowAtIndexPath);
                CHLoadLateClass(NotificationsFolderView);
                CHHook(2, NotificationsFolderView, tableView, didSelectRowAtIndexPath);
            });
        }
	}
}

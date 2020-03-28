#import "PLPermissionRequestor.h"
#import <PLMediaStreamingKit/PLMediaStreamingKit.h>

@implementation PLPermissionRequestor

- (instancetype)initWithPermissionGranted:(void (^)())permissionGranted
                         withNoPermission:(void (^)())noPermission
{
    if (self = [self init]) {
        _permissionGranted = permissionGranted;
        _noPermission = noPermission;
    }
    return self;
}

- (void)checkAndRequestPermission
{
    PLAuthorizationStatus status = [PLMediaStreamingSession cameraAuthorizationStatus];

    if (PLAuthorizationStatusNotDetermined == status) {
        [PLMediaStreamingSession requestCameraAccessWithCompletionHandler:^(BOOL granted) {
            granted ? _permissionGranted() : _noPermission();
        }];
    } else if (PLAuthorizationStatusAuthorized == status) {
        _permissionGranted();
    } else {
        _noPermission();
    }
}

@end

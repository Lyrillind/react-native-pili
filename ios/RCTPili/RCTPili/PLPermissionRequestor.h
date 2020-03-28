#import <Foundation/Foundation.h>

@interface PLPermissionRequestor : NSObject

@property (nonatomic, strong) void (^permissionGranted)();
@property (nonatomic, strong) void (^noPermission)();

- (instancetype)initWithPermissionGranted:(void (^)())permissionGranted
                         withNoPermission:(void (^)())noPermission;
- (void)checkAndRequestPermission;

@end

//
//  RCTStreaming.m
//  RCTPili
//
//  Created by guguyanhua on 16/5/26.
//  Copyright © 2016年 pili. All rights reserved.
//

#import "RCTStreaming.h"
#import "RCTBridgeModule.h"
#import "UIView+React.h"
#import "RCTEventDispatcher.h"
#import "PLPermissionRequestor.h"


@implementation RCTStreaming{
    RCTEventDispatcher *_eventDispatcher;
    BOOL _started;
    BOOL _muted;
    BOOL _focus;
    NSString *_camera;
}

const char *stateNames[] = {
    "Unknow",
    "Connecting",
    "Connected",
    "Disconnecting",
    "Disconnected",
    "Error"
};

const char *networkStatus[] = {
    "Not Reachable",
    "Reachable via WiFi",
    "Reachable via CELL"
};




- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
    if ((self = [super init])) {
        [PLStreamingEnv initEnv];
        _eventDispatcher = eventDispatcher;
        _started = YES;
        _muted = NO;
        _focus = NO;
        _camera = @"back";

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        self.internetReachability = [Reachability reachabilityForInternetConnection];
        [self.internetReachability startNotifier];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleInterruption:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:[AVAudioSession sharedInstance]];

        self.sessionQueue = dispatch_queue_create("pili.queue.streaming", DISPATCH_QUEUE_SERIAL);
    }

    return self;
};

- (void) setRtmpURL:(NSString *)rtmpURL
{
    _rtmpURL = rtmpURL;
    [self setSourceAndProfile];
}

- (void)setProfile:(NSDictionary *)profile{
    _profile = profile;
    [self setSourceAndProfile];
}

- (void) setSourceAndProfile{
    if(self.profile && self.rtmpURL){

      NSDictionary *video = self.profile[@"video"];
      NSDictionary *audio = self.profile[@"audio"];

      int *fps = [video[@"fps"] integerValue];
      int *bps = [video[@"bps"] integerValue];
      int *maxFrameInterval = [video[@"maxFrameInterval"] integerValue];

      CGRect screenRect = [[UIScreen mainScreen] bounds];
      CGFloat screenWidth = screenRect.size.width;
      CGFloat screenHeight = screenRect.size.height;
      CGSize videoSize = CGSizeMake(screenWidth, screenHeight);

      PLVideoCaptureConfiguration *videoCaptureConfiguration = [PLVideoCaptureConfiguration defaultConfiguration];
      PLVideoStreamingConfiguration *videoStreamingConfiguration = [[PLVideoStreamingConfiguration alloc] initWithVideoSize:videoSize expectedSourceVideoFrameRate:fps videoMaxKeyframeInterval:maxFrameInterval averageVideoBitRate:bps videoProfileLevel:AVVideoProfileLevelH264Baseline31];

      PLAudioCaptureConfiguration *audioCaptureConfiguration = [PLAudioCaptureConfiguration defaultConfiguration];
      PLAudioStreamingConfiguration *audioStreamingConfiguration = [PLAudioStreamingConfiguration defaultConfiguration];

      // 推流 session
      self.session = [[PLMediaStreamingSession alloc] initWithVideoCaptureConfiguration:videoCaptureConfiguration audioCaptureConfiguration:audioCaptureConfiguration videoStreamingConfiguration:videoStreamingConfiguration audioStreamingConfiguration:audioStreamingConfiguration stream:nil];
      self.session.delegate = self;

      PLPermissionRequestor *permission = [[PLPermissionRequestor alloc] init];
      permission.noPermission = ^{};
      permission.permissionGranted = ^{
          UIView *previewView = self.session.previewView;
          dispatch_async(dispatch_get_main_queue(), ^{
              [self addSubview:previewView];

              if(_focus){
                  [self.session setSmoothAutoFocusEnabled:_focus];
                  [self.session setTouchToFocusEnable:_focus];
              }

              if(_muted){
                  [self setMuted:_muted];
              }

              [self setCamera:_camera];

              [self startSession];
          });
      };
      [permission checkAndRequestPermission];

    }
}

- (void)setStarted:(BOOL) started {
    if(started != _started){
        if(started){
            [self startSession];
            _started = started;
        }else{
            [self stopSession];
            _started = started;
        }
    }
}

-(void)setMuted:(BOOL) muted {
    _muted = muted;
    [self.session setMuted:muted];
}

-(void)setFocus:(BOOL) focus {
    _focus = focus;
    [self.session setSmoothAutoFocusEnabled:focus];
    [self.session setTouchToFocusEnable:focus];
}

-(void)setZoom:(NSNumber*) zoom {
    self.session.videoZoomFactor = [zoom integerValue];
}

-(void)setCamera:(NSString*)camera{
    if([camera isEqualToString:@"front"] || [camera isEqualToString:@"back"]){
        if(![camera isEqualToString:_camera]){
            _camera = camera;
            [self.session toggleCamera];
        }
    }

}


- (void)streamingSessionSendingBufferDidFull:(id)session {
    NSString *log = @"Buffer is full";
    NSLog(@"%@", log);
}

- (void)streamingSession:(id)session sendingBufferDidDropItems:(NSArray *)items {
    NSString *log = @"Frame dropped";
    NSLog(@"%@", log);
}



- (void)stopSession {
    dispatch_async(self.sessionQueue, ^{
        [self.session stopStreaming];
    });
}

- (void)startSession {
    dispatch_async(self.sessionQueue, ^{
        NSURL *streamURL = [NSURL URLWithString:self.rtmpURL];
        [self.session startStreamingWithPushURL:streamURL feedback:^(PLStreamStartStateFeedback feedback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (PLStreamStartStateSuccess == feedback) {
                    NSLog(@"success ");
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"错误" message:@"推流失败了" delegate:nil cancelButtonTitle:@"知道啦" otherButtonTitles:nil] show];
                    self.onIOError(@{@"onIOError": self.reactTag});
                }
            });
        }];
    });
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session streamStatusDidUpdate:(PLStreamStatus *)status {
    NSString *log = [NSString stringWithFormat:@"Stream Status: %@", status];
    NSLog(@"%@", log);
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session streamStateDidChange:(PLStreamState)state {
    NSString *log = [NSString stringWithFormat:@"Stream State: %s", stateNames[state]];
    NSLog(@"%@", log);

    switch (state) {
        case PLStreamStateUnknow:
            self.onReady(@{@"onLoading": self.reactTag});
            break;
        case PLStreamStateConnecting:
            self.onConnecting(@{@"onConnecting": self.reactTag});
            break;
        case PLStreamStateConnected:
            self.onStreaming(@{@"onStreaming": self.reactTag});
            break;
        case PLStreamStateDisconnecting:
            break;
        case PLStreamStateDisconnected:
            self.onDisconnected(@{@"onDisconnected": self.reactTag});
            self.onShutdown(@{@"onShutdown": self.reactTag});
            break;
        case PLStreamStateError:
            self.onIOError(@{@"onIOError": self.reactTag});
            break;
        default:
            break;
    }

}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session didDisconnectWithError:(NSError *)error {
    NSString *log = [NSString stringWithFormat:@"Stream State: Error. %@", error];
    NSLog(@"%@", log);
    [self startSession];
}

- (void)reachabilityChanged:(NSNotification *)notif{
    Reachability *curReach = [notif object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    NetworkStatus status = [curReach currentReachabilityStatus];

    if (NotReachable == status) {
        // 对断网情况做处理
        [self stopSession];
    }

    NSString *log = [NSString stringWithFormat:@"Networkt Status: %s", networkStatus[status]];
    NSLog(@"%@", log);
}

- (void)handleInterruption:(NSNotification *)notification {
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        NSLog(@"Interruption notification");

        if ([[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] isEqualToNumber:[NSNumber numberWithInt:AVAudioSessionInterruptionTypeBegan]]) {
            NSLog(@"InterruptionTypeBegan");
        } else {
            // the facetime iOS 9 has a bug: 1 does not send interrupt end 2 you can use application become active, and repeat set audio session acitve until success.  ref http://blog.corywiles.com/broken-facetime-audio-interruptions-in-ios-9
            NSLog(@"InterruptionTypeEnded");
            AVAudioSession *session = [AVAudioSession sharedInstance];
            [session setActive:YES error:nil];
        }
    }
}
@end

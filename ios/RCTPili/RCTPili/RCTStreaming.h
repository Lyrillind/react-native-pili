//
//  RCTStreaming.h
//  RCTPili
//
//  Created by guguyanhua on 16/5/26.
//  Copyright © 2016年 pili. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCTView.h"
#import <PLMediaStreamingKit/PLMediaStreamingKit.h>
#import "Reachability.h"
#import <asl.h>

@class RCTEventDispatcher;

@interface RCTStreaming : UIView<PLMediaStreamingSessionDelegate,PLStreamingSendingBufferDelegate>

@property (nonatomic, strong) PLMediaStreamingSession  *session;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) Reachability *internetReachability;
@property (nonatomic, strong) NSDictionary  *profile;
@property (nonatomic, strong) NSString *rtmpURL;

@property (nonatomic, copy) RCTBubblingEventBlock onReady;
@property (nonatomic, copy) RCTBubblingEventBlock onConnecting;
@property (nonatomic, copy) RCTBubblingEventBlock onStreaming;
@property (nonatomic, copy) RCTBubblingEventBlock onShutdown;
@property (nonatomic, copy) RCTBubblingEventBlock onIOError;
@property (nonatomic, copy) RCTBubblingEventBlock onDisconnected;

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher NS_DESIGNATED_INITIALIZER;

@end

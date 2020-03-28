//
//  RCTStreamingManager.m
//  RCTPili
//
//  Created by guguyanhua on 16/5/26.
//  Copyright © 2016年 pili. All rights reserved.
//

#import "RCTStreamingManager.h"
#import "RCTStreaming.h"

@implementation RCTStreamingManager
RCT_EXPORT_MODULE();

@synthesize bridge = _bridge;

- (UIView *)view
{
    return [[RCTStreaming alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_VIEW_PROPERTY(rtmpURL, NSString);
RCT_EXPORT_VIEW_PROPERTY(profile, NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(started, BOOL);
RCT_EXPORT_VIEW_PROPERTY(muted, BOOL);
RCT_EXPORT_VIEW_PROPERTY(zoom, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(focus, BOOL);
RCT_EXPORT_VIEW_PROPERTY(camera, NSString);

RCT_EXPORT_VIEW_PROPERTY(onReady, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onConnecting, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onStreaming, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onShutdown, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onIOError, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onDisconnected, RCTBubblingEventBlock);



@end

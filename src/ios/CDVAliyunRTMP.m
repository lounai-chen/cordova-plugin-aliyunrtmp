//
//  CDVWechat.m
//  cordova-plugin-aliyunrtmp
//
//  Created by Steve Cai on 04/13/17.
//
//

#import "CDVAliyunRTMP.h"
#import <Cordova/CDV.h>
#import "AlivcLiveVideo.h"
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

#import <AliyunPlayerSDK/AliyunPlayerSDK.h>
#import <AliyunPlayerSDK/AliVcMediaPlayer.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVAudioSession.h>

@interface CDVAliyunRTMP ()<AlivcLiveSessionDelegate,AliVcAccessKeyProtocol>

@property (nonatomic, strong) AlivcLiveSession *liveSession;
@property (nonatomic, strong) NSString *url;

@property (nonatomic, strong) AliVcMediaPlayer* player;
@property (nonatomic, strong) UIView *mShowView;

@end

@implementation CDVAliyunRTMP{
}

NSString* startCallbackID;

NSString* pushStatusString;
NSString* playStatusString;

#pragma mark "API"
- (void)pluginInitialize {
    [self Init];
}

- (void)Init {
    
}



- (void)start:(CDVInvokedUrlCommand *)command
{
    [self Init];
    
    startCallbackID=command.callbackId;
    
    
    
    NSString* _streamUrl=[command.arguments objectAtIndex:0];
    
    _url=_streamUrl;
    
    if(_streamUrl!=nil && [_streamUrl length]>0 ){
        AlivcLConfiguration *configuration = [[AlivcLConfiguration alloc] init];
        configuration.url = _url;
        configuration.videoMaxBitRate = 1;//1500 * 1000;
        configuration.videoBitRate = 1;//600 * 1000;
        configuration.videoMinBitRate =1;// 400 * 1000;
        configuration.audioBitRate = 64 * 1000;
        configuration.videoSize = CGSizeMake(50, 50);// 横屏状态宽高不需要互换
        configuration.fps = 20;//20;
        configuration.preset = AVCaptureSessionPresetiFrame960x540;
        //configuration.screenOrientation = _isScreenHorizontal;
        
        configuration.reconnectTimeout = 5;
        
        self.liveSession = [[AlivcLiveSession alloc] initWithConfiguration:configuration];
        self.liveSession.delegate = self;
        
        [self.liveSession alivcLiveVideoStartPreview];
        [self.liveSession alivcLiveVideoConnectServer];
        
        //[self startCallBackSuccess:@"0"];
        
        
    }else{
        [self startCallBackError:@"-1~no url"];
    }
    
    
    
}

- (void)startCallBackSuccess:(NSString *) msg{
    CDVPluginResult* pluginResult=nil;
    pluginResult=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:msg];
    NSLog(@"start have success");
    [self.commandDelegate sendPluginResult:pluginResult callbackId:startCallbackID];
    NSLog(msg,nil);
}

- (void)startCallBackError:(NSString *) msg{
    CDVPluginResult* pluginResult=nil;
    pluginResult=[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:msg];
    NSLog(@"start have error");
    [self.commandDelegate sendPluginResult:pluginResult callbackId:startCallbackID];
    NSLog(msg,nil);
}

- (void)alivcLiveVideoLiveSession:(AlivcLiveSession *)session error:(NSError *)error{
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        NSString *msg = [NSString stringWithFormat:@"%zd %@",error.code, error.localizedDescription];
    //        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Live Error" message:msg delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"重新连接", nil];
    //        alertView.delegate = self;
    //        [alertView show];
    //    });
    
    pushStatusString=[NSString stringWithFormat:@"%zd|%@",error.code,error.localizedDescription];// error.code+ @"|网络重连失败, 直播已停止";
    [self startCallBackError:pushStatusString];
    [self stop:nil];
}

- (void)alivcLiveVideoReconnectTimeout:(AlivcLiveSession*)session {
    
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"重连超时（此处根据实际情况决定，默认重连时长5s，可更改，建议开发者在此处重连）" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    //
    //        [alertView show];
    //    });
    pushStatusString=@"-56|网络重连失败, 直播已停止";
    [self startCallBackError:@"-56|网络重连失败, 直播已停止"];
    [self stop:nil];
    
}

- (void)alivcLiveVideoLiveSessionConnectSuccess:(AlivcLiveSession *)session {
    [self startCallBackSuccess:@"0~connect success"];
}


- (void)alivcLiveVideoLiveSessionNetworkSlow:(AlivcLiveSession *)session{
    // 注意：一定要套 主线程 完成UI操作
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        self.textView.text = @"网速太慢";
    //    });
    pushStatusString=@"-55|当前网络状态极差，已无法正常流畅直播";
    [self startCallBackError:@"-55|当前网络状态极差，已无法正常流畅直播"];
    [self stop:nil];
}


- (void)alivcLiveVideoOpenAudioSuccess:(AlivcLiveSession *)session {
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"YES" message:@"麦克风打开成功" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    //        [alertView show];
    //    });
    //[self startCallBackSuccess:@"1~microphone open success"];
}

- (void)alivcLiveVideoOpenVideoSuccess:(AlivcLiveSession *)session {
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"YES" message:@"摄像头打开成功" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    //        [alertView show];
    //    });
    //[self startCallBackSuccess:@"2~camera open success"];
}


- (void)alivcLiveVideoLiveSession:(AlivcLiveSession *)session openAudioError:(NSError *)error {
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"麦克风获取失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    //        [alertView show];
    //    });
    pushStatusString=@"-33|麦克风获取失败";
    [self startCallBackError:@"-33|麦克风获取失败"];
    [self stop:nil];
}

- (void)alivcLiveVideoLiveSession:(AlivcLiveSession *)session openVideoError:(NSError *)error {
    
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"摄像头获取失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    //        [alertView show];
    //    });
    //pushStatusString=@"-33|麦克风获取失败";
    //[self startCallBackError:@"-33|麦克风获取失败"];
    //[self stop:nil];
}

- (void)alivcLiveVideoLiveSession:(AlivcLiveSession *)session encodeAudioError:(NSError *)error {
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"音频编码初始化失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    //        [alertView show];
    //    });
    pushStatusString=@"-32|音频编码初始化失败";
    [self startCallBackError:@"-32|音频编码初始化失败"];
    [self stop:nil];
    
}

- (void)alivcLiveVideoLiveSession:(AlivcLiveSession *)session encodeVideoError:(NSError *)error {
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"视频编码初始化失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    //        [alertView show];
    //    });
    pushStatusString=@"-31|视频编码初始化失败";
    [self startCallBackError:@"-31|视频编码初始化失败"];
    [self stop:nil];
}

- (void)alivcLiveVideoLiveSession:(AlivcLiveSession *)session bitrateStatusChange:(ALIVC_LIVE_BITRATE_STATUS)bitrateStatus {
    
    //    //dispatch_async(dispatch_get_main_queue(), ^{
    //    //    NSLog(@"升降码率:%ld", bitrateStatus);
    //    //});
}

- (void)stop:(CDVInvokedUrlCommand *)command
{
    [self.liveSession alivcLiveVideoDisconnectServer];
    
    [self.liveSession alivcLiveVideoStopPreview];
    [self.liveSession.previewView removeFromSuperview];
    self.liveSession = nil;
    
}

- (void)play:(CDVInvokedUrlCommand *)command
{
    [self Init];
    
    startCallbackID=command.callbackId;
    NSString* _streamUrl=[command.arguments objectAtIndex:0];
    
    
    if(_streamUrl!=nil && [_streamUrl length]>0 ){
        
        [AliVcMediaPlayer setAccessKeyDelegate:self];
        
        self.mShowView = [[UIView alloc] init];
        //新建播放器
        self.player = [[AliVcMediaPlayer alloc] init];
        //创建播放器，传入显示窗口
        [self.player create:self.mShowView];
        //注册准备完成通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(OnVideoPrepared:) name:AliVcMediaPlayerLoadDidPreparedNotification object:self.player];
        //注册错误通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(OnVideoError:) name:AliVcMediaPlayerPlaybackErrorNotification object:self.player];
						
							
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(OnVideoFinish:) name:AliVcMediaPlayerPlaybackDidFinishNotification object:self.player];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(OnVideoEndCaching:) name:AliVcMediaPlayerEndCachingNotification object:self.player];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(OnVideoSeekingFinish:) name:AliVcMediaPlayerSeekingDidFinishNotification object:self.player];
        
        NSURL *url=[NSURL URLWithString:_streamUrl];
        
        //传入播放地址，初始化视频，准备播放
        [self.player prepareToPlay:url];
        //开始播放
        [self.player play];
        
        
        
        //[self startCallBackSuccess:@"0"];
        
        
    }else{
        [self startCallBackError:@"-1~no url"];
    }
    
    
}
NSString* accessKeyID = @"xxxxxx";
NSString* accessKeySecret = @"xxxxxx";
-(AliVcAccesskey*)getAccessKeyIDSecret
{
    AliVcAccesskey* accessKey = [[AliVcAccesskey alloc] init];
    accessKey.accessKeyId = accessKeyID;
    accessKey.accessKeySecret = accessKeySecret;
    return accessKey;
}

-(void) OnVideoPrepared:(NSNotification *)notification
{
    //收到完成通知后，获取视频的相关信息，更新界面相关信息
    //[self.playSlider setMinimumValue:0];
    //[self.playSlider setMaximumValue:player.duration];
    [self startCallBackSuccess:@"0"];
}
-(void)OnVideoError:(NSNotification *)notification
{
    //AliVcMovieErrorCode error_code = self.player.errorCode;
    playStatusString=[NSString stringWithFormat:@"1|播放失败,可能直播还未开始或网络连接问题, 请稍候重试."];
    [self startCallBackError:@"播放失败,可能直播还未开始或网络连接问题, 请稍候重试."];
    [self.player stop];
}
-(void)OnVideoEndCaching:(NSNotification *)notification
{
    //AliVcMovieErrorCode error_code = self.player.errorCode;
    playStatusString=[NSString stringWithFormat:@"2|缓冲已经结束"];
    [self startCallBackError:@"缓冲已经结束"];
    //[self.player stop];
}
-(void)OnVideoFinish:(NSNotification *)notification
{
    //AliVcMovieErrorCode error_code = self.player.errorCode;
    playStatusString=[NSString stringWithFormat:@"3|播放失败,可能直播还未开始或网络连接问题, 请稍候重试."];
    [self startCallBackError:@"播放失败,可能直播还未开始或网络连接问题, 请稍候重试."];
    [self.player stop];
}
-(void)OnVideoSeekingFinish:(NSNotification *)notification
{
    //AliVcMovieErrorCode error_code = self.player.errorCode;
    playStatusString=[NSString stringWithFormat:@"4|播放失败,可能直播还未开始或网络连接问题, 请稍候重试."];
    [self startCallBackError:@"播放失败,可能直播还未开始或网络连接问题, 请稍候重试."];
    [self.player stop];
}

- (void)playstop:(CDVInvokedUrlCommand *)command
{
    [self.player stop];
    self.player=Nil;
    
}

- (void)checkpushstatus:(CDVInvokedUrlCommand *)command
{
    NSString *ret=nil;
    if(self.liveSession!=nil
       &&self.liveSession.dumpDebugInfo.connectStatus==AlivcLConnectStatusSuccess){
        ret=[NSString stringWithFormat:@"0|%@",pushStatusString];// @"0|playing";
    }else{
        ret=[NSString stringWithFormat:@"-1|%@",pushStatusString];// @"0|playing";
    }
    CDVPluginResult* pluginResult=nil;
    pluginResult=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:ret];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

    
}
- (void)checkplaystatus:(CDVInvokedUrlCommand *)command
{
    
    NSString *ret=nil;
    if(self.player!=nil&&self.player.isPlaying){
        ret=[NSString stringWithFormat:@"0|%@",playStatusString];// @"0|playing";
    }else{
        ret=[NSString stringWithFormat:@"-1|%@",playStatusString];// @"0|playing";
    }
    CDVPluginResult* pluginResult=nil;
    pluginResult=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:ret];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}
@end

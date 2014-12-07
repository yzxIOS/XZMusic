//
//  XZMusicPlayingView.m
//  XZMusic
//
//  Created by xiazer on 14/12/1.
//  Copyright (c) 2014年 xiazer. All rights reserved.
//

#import "XZMusicPlayingView.h"
#import "XZGlobalManager.h"
#import "XZMusicDownloadCenter.h"
#import "XZMusicFileManager.h"

static void *kStatusKVOKey = &kStatusKVOKey;
static void *kDurationKVOKey = &kDurationKVOKey;
static void *kBufferingRatioKVOKey = &kBufferingRatioKVOKey;


@interface XZMusicPlayingView ()
@property(nonatomic, strong) XZMusicLrcView *lrcView;
@property(nonatomic, strong) XZSongModel *songModel;
@property(nonatomic, strong) NSTimer *timer;
@end

@implementation XZMusicPlayingView

- (XZMusicPlayingTimeProgress *)timeProgress{
    if (!_timeProgress) {
        _timeProgress = [[XZMusicPlayingTimeProgress alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 100)];
    }
    return _timeProgress;
}

- (XZPlayingRollView *)playingRollView{
    if (!_playingRollView) {
        _playingRollView = [[XZPlayingRollView alloc] initWithFrame:CGRectMake(0, 50, ScreenWidth, 300)];
        _playingRollView.rollViewDelegate = self;
    }
    return _playingRollView;
}
- (XZMusicLrcView *)lrcView{
    if (!_lrcView) {
        _lrcView = [[XZMusicLrcView alloc] initWithFrame:CGRectMake(0, 50 + 300, ScreenWidth, ScreenHeight-64-50-300-80)];
    }
    return _lrcView;
}
- (XZPlayMoreFuncView *)playingMoreView{
    if (!_playingMoreView) {
        _playingMoreView = [[XZPlayMoreFuncView alloc] initWithFrame:CGRectMake(0, ScreenHeight-64-80, ScreenWidth, 80)];
        _playingMoreView.funcViewDelegate = self;
    }
    return _playingMoreView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self){
        self.backgroundColor = [UIColor clearColor];
        
        [self initData];
        [self initUI];
    }
    return self;
}

- (void)initData{
}

- (void)initUI{
    [self addSubview:self.timeProgress];
    [self addSubview:self.lrcView];
    [self addSubview:self.playingRollView];
    [self addSubview:self.playingMoreView];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(musicPlaying) userInfo:nil repeats:YES];
}

- (void)musicPlaying{
    if ([XZMusicFileManager isHasMusicOrLrc:NO songModel:self.songModel]) {
        int time = self.audioPlayer.currentTime;
        [self.lrcView moveLrcWithTime:time];
        [self updateProgress:time];
    }
}

#pragma mark - method
- (void)playMusic:(XZPlaySongModel *)songMode{
    [self emptyAudio];
    
    self.audioPlayer = [DOUAudioStreamer streamerWithAudioFile:songMode];
    [self.audioPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:kStatusKVOKey];
    [self.audioPlayer addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:kDurationKVOKey];
    [self.audioPlayer addObserver:self forKeyPath:@"bufferingRatio" options:NSKeyValueObservingOptionNew context:kBufferingRatioKVOKey];
    
    [self.audioPlayer play];
    [self.playingRollView setRollPlayingPlayStatus:XZPlayingRollViewActionTypeForPlaying];
}

- (void)emptyAudio {
    if (self.audioPlayer) {
        [self.audioPlayer pause];
        [self.audioPlayer removeObserver:self forKeyPath:@"status"];
        [self.audioPlayer removeObserver:self forKeyPath:@"duration"];
        [self.audioPlayer removeObserver:self forKeyPath:@"bufferingRatio"];
        self.audioPlayer = nil;
    }
}

- (void)showLrcWithPath:(NSString *)lrcPath{
    [self.lrcView initLrcViewWithPath:lrcPath];
}


- (void)updateProgress:(int)playingTime{
    [self.timeProgress updatePlayingTime:playingTime];
    [self.timeProgress updateProgress:playingTime];
}

- (void)congfigPlaying:(XZSongModel *)songModel{
    self.songModel = songModel;
    
    [self.timeProgress initTimeProgressData:songModel.time];
    [self.playingRollView configRooViewData:songModel.songPicBig];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
        if (context == kStatusKVOKey) {
            [self performSelector:@selector(updatePlayingStatus)
                         onThread:[NSThread mainThread]
                       withObject:nil
                    waitUntilDone:NO];
        }
        else if (context == kDurationKVOKey) {
            [self performSelector:@selector(musicPlaying)
                         onThread:[NSThread mainThread]
                       withObject:nil
                    waitUntilDone:NO];
        }
        else if (context == kBufferingRatioKVOKey) {
            [self performSelector:@selector(updateBufferingStatus)
                         onThread:[NSThread mainThread]
                       withObject:nil
                    waitUntilDone:NO];
        }
        else {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
}

- (void)downloadMusic {
    NSString *identify = [[NSProcessInfo processInfo] globallyUniqueString];
    __weak XZMusicPlayingView *this =self;
    
    [[XZMusicDownloadCenter shareInstance] downloadMusicWithMusicId:[NSString stringWithFormat:@"%lld",self.songModel.songId] format:self.songModel.format musicUrlStr:self.songModel.songLink identify:identify downloadType:XZMusicDownloadtypeForMusic downloadBlock:^(XZMusicDownloadResponse *response) {
        DLog(@"response---->>%ld/%f/%@",response.downloadStatus,response.progress,response.downloadIdentify);
        
        if (response.downloadStyle == XZMusicdownloadStyleForMusic) {
            if (response.downloadStatus == XZMusicDownloadSuccess) {
                DLog(@"music下载=========下载成功");
                [this.playingMoreView showCircleProgress:1.0];
            }else if (response.downloadStatus == XZMusicDownloadIng) {
                DLog(@"music下载=========正在下载中...");
                DLog(@"response.progress --->>%f",response.progress);
                [this.playingMoreView showCircleProgress:response.progress];
            }else if (response.downloadStatus == XZMusicDownloadFail) {
                DLog(@"music下载=========下载失败");
            }else if (response.downloadStatus == XZMusicDownloadNetError) {
                DLog("music下载=========网络错误");
            }
        }
    }];
}

#pragma mark - playingKVO
- (void)updatePlayingStatus {
    switch ([self.audioPlayer status]) {
        case DOUAudioStreamerPlaying:
            
            break;
        case DOUAudioStreamerPaused:
            
            break;
        case DOUAudioStreamerIdle:
            
            break;
        case DOUAudioStreamerFinished:
            
            break;
        case DOUAudioStreamerBuffering:
            
            break;
        case DOUAudioStreamerError:
            
            break;
            
        default:
            break;
    }
}

- (void)updateBufferingStatus {
    
}

#pragma mark - XZPlayingRollViewDelegate
- (void)playingRollViewAction:(enum XZPlayingRollViewActionType)actionType{
    if (actionType == XZPlayingRollViewActionTypeForPlaying) {
        [self.audioPlayer play];
        [self.playingRollView setRollPlayingPlayStatus:XZPlayingRollViewActionTypeForPlaying];
    }else {
        [self.audioPlayer pause];
        [self.playingRollView setRollPlayingPlayStatus:XZPlayingRollViewActionTypeForPause];
    }
}

#pragma mark - XZPlayMoreFuncViewDelegate
- (void)funcViewAction:(enum XZPlayMoreFuncViewActionType)actionType {
    DLog(@"actionType--->>%ld",actionType);
    if (actionType == XZPlayMoreFuncViewActionTypeForDown) {
        [self downloadMusic];
    }
}

@end
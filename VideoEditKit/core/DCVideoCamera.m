//
//  DCVideoCamera.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "DCVideoCamera.h"

@interface DCVideoCamera()<AVAudioPlayerDelegate>

@property (nonatomic, assign) BOOL torchIsOn;
@property (nonatomic, assign) BOOL isFrontCamera;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, assign) NSTimeInterval previousPlayTimeStamp;
@property (nonatomic, assign) NSTimeInterval currentPlayTimeStamp;
@property (nonatomic, assign) float audioPlayStart;
@property (nonatomic, assign) NSTimeInterval lastTimeInterval;
@property (nonatomic, assign) BOOL audioFinished;
@property (nonatomic, assign) float currentMusicTime;
@property (nonatomic, assign) BOOL  newAudio;

@end

@implementation DCVideoCamera

- (instancetype) initWithPreset:(NSString *)sessionPreset
{
    self = [super initWithSessionPreset:sessionPreset cameraPosition:AVCaptureDevicePositionFront];
    if (self)
    {
        self.torchIsOn = NO;
        self.isFrontCamera = YES;
        self.horizontallyMirrorRearFacingCamera = NO;
        self.horizontallyMirrorFrontFacingCamera = YES;
        self.outputImageOrientation = UIInterfaceOrientationPortrait;
        self.currentPlayTimeStamp = 0.0f;
        self.previousPlayTimeStamp = 0.0f;
        self.lastTimeInterval = 0.0f;
        self.currentMusicTime = 0.f;
        self.newAudio = NO;
        self.currentMusicTime = 0.f;
        self.newAudio = NO;
        _cameraZoom = 1.0f;
    }
    return self;
}

- (instancetype) init
{
    
    self = [self initWithPreset:AVCaptureSessionPreset1280x720];
    if (self)
    {
        
    }
    return self;
}

- (instancetype) initWithAudioUrl:(NSURL *) url
{
    self = [self init];
    if(self != nil)
    {
        if( url != nil)
        {
            [self setAduioUrl:url];
        }
    }
    return self;
}

- (instancetype) initWithAudioLocalPath:(NSString *) localPath
{
    self = [self init];
    if(self != nil)
    {
        if( localPath != nil)
        {
            [self setAduioLocalPath:localPath];
        }
    }
    return self;
}

- (void) setAduioUrl:(NSURL *) url
{
    if(url != nil)
    {
        NSError *error;
        if (self.audioPlayer){
            self.audioPlayer.delegate = nil;
            self.audioPlayer = nil;
        }
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        self.audioFinished = NO;
        self.audioPlayer.delegate = self;
        self.audioPlayer.enableRate = YES;
        [self.audioPlayer prepareToPlay];
        self.newAudio = YES;
    }
}

- (void) setPlayRate:(CGFloat) rate{
    if(self.audioPlayer != nil){
        if(!self.audioPlayer.enableRate){
            self.audioPlayer.enableRate = YES;
        }
        self.audioPlayer.rate = rate;
    }
}

- (void) setAduioLocalPath:(NSString *) localPath
{
    if(localPath != nil)
    {
        NSURL *url = [NSURL fileURLWithPath:localPath];
        [self setAduioUrl:url];
    }
}

- (void) setAudioLoopCount:(NSInteger) loopCount
{
    if(loopCount < 0)
    {
        self.audioPlayer.numberOfLoops = NSIntegerMax;
    }else{
        self.audioPlayer.numberOfLoops = loopCount;
    }
}

- (void) stopCapture
{
    
    [super stopCameraCapture];
}

- (void) stopBackground
{
    if([self.audioPlayer isPlaying])
    {
        self.audioPlayer.volume = 0.0f;
        [self.audioPlayer stop];
    }
    self.previousPlayTimeStamp = self.currentPlayTimeStamp;
    self.currentPlayTimeStamp = self.audioPlayer.currentTime;
}

- (void) pauseBackground
{
    if([self.audioPlayer isPlaying])
    {
        [self.audioPlayer pause];
    }
    self.previousPlayTimeStamp = self.currentPlayTimeStamp;
    self.currentPlayTimeStamp = self.audioPlayer.currentTime;
}


- (NSTimeInterval) currentTime
{
    if (self.newAudio)
    {
        self.currentMusicTime = 0.f;
        self.newAudio = NO;
    }
    if (!self.audioFinished)
    {
        if (fabs(self.currentMusicTime - self.audioPlayer.currentTime) < self.audioPlayer.duration - 0.1f)
        {
            self.currentMusicTime = self.audioPlayer.currentTime;
        }
        
    }else
    {
        self.currentMusicTime = 0.f;
    }
    return self.audioFinished?self.audioPlayer.duration:self.currentMusicTime;
}

- (void) playBackgroundAtTime:(NSTimeInterval) time
{
    if((self.audioPlayer != nil)&& (![self.audioPlayer isPlaying]))
    {
        self.audioFinished = NO;
        [self.audioPlayer play];
        self.audioPlayer.currentTime = time;
    }
}

- (void) playPreviousBackground
{
    if((self.audioPlayer != nil)&& (![self.audioPlayer isPlaying]))
    {
        [self.audioPlayer playAtTime:self.previousPlayTimeStamp];
    }
}

- (void) playBackground
{
    if((self.audioPlayer != nil)&& (![self.audioPlayer isPlaying]) && !self.audioFinished)
    {
        [self.audioPlayer play];
        self.audioPlayer.volume = 1.0f;
        self.lastTimeInterval = self.audioPlayer.deviceCurrentTime;
        if (self.audioPlayer.rate != 1.0) {
            self.audioFinished = NO;
            self.audioPlayer.currentTime = self.currentPlayTimeStamp;
        }
    }
}

- (void) startCapture{
    
    [super startCameraCapture];
}

- (void) setFrameRate:(int32_t)frameRate{
    
    [super setFrameRate:frameRate];
}

- (void) frontCamera:(BOOL) isFront{
    if(isFront){
        if(!self.isFrontCamera){
            [self changeCameraPosition:AVCaptureDevicePositionFront];
            self.isFrontCamera = YES;
        }
    }else{
        if(self.isFrontCamera){
            [self changeCameraPosition:AVCaptureDevicePositionBack];
            AVCaptureConnection *connect = [self videoCaptureConnection];
            if(connect.isVideoMirrored){
                connect.videoMirrored = NO;
            }
            self.isFrontCamera = NO;
        }
    }
}

- (void)changeCameraPosition:(AVCaptureDevicePosition)position{
    [super switchCameraTo:position];
}


-(BOOL) isFlashOn
{
    return self.torchIsOn;
}

- (void)turnFlashOn: (bool) on
{
#if 0
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch] && [device hasFlash]){
        [device lockForConfiguration:nil];
        if (on) {
            [device setTorchMode:AVCaptureTorchModeOn];
            [device setFlashMode:AVCaptureFlashModeOn];
            self.torchIsOn = YES;
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
            [device setFlashMode:AVCaptureFlashModeOff];
            self.torchIsOn = NO;
        }
        [device unlockForConfiguration];
    }
#endif
    AVCaptureDevice *device = self.inputCamera;
    if ([device hasTorch]){
        [device lockForConfiguration:nil];
        if (on) {
            [device setTorchMode:AVCaptureTorchModeOn];
            self.torchIsOn = YES;
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
            self.torchIsOn = NO;
        }
        [device unlockForConfiguration];
    }
}

- (BOOL)canSupportFlashOn;{
    return [self.inputCamera hasTorch];
}

- (BOOL)focusAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = self.inputCamera;
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            [device setFocusPointOfInterest:point];
            [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            [device unlockForConfiguration];
            return YES;
        }
    }
    return NO;
}


- (void) setCameraZoom:(CGFloat)cameraZoom{
    _cameraZoom = cameraZoom;
    _cameraZoom = (self.cameraZoom < 1.0f) ? 1.0f: self.cameraZoom;
    _cameraZoom = (self.cameraZoom > 10.0f) ? 1.0f :self.cameraZoom;
    AVCaptureDevice *device = self.inputCamera;
    NSError *error;
    if ([device lockForConfiguration:&error])
    {
        device.videoZoomFactor = _cameraZoom;
        [device unlockForConfiguration];
    }
}

- (BOOL)exposureAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = self.inputCamera;
    if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
    {
        NSError *error;
        if ([device lockForConfiguration:&error])
        {
            [device setExposurePointOfInterest:point];
            [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            [device unlockForConfiguration];
            return YES;
        }
    }
    return NO;
}

- (void)continuousFocusAtPoint:(CGPoint)point
{
    AVCaptureDevice *device =self.inputCamera;
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
    {
        NSError *error;
        if ([device lockForConfiguration:&error])
        {
            [device setFocusPointOfInterest:point];
            [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            [device unlockForConfiguration];
        }
    }
}


- (void)setCameraEVValue:(CGFloat)value
{
    AVCaptureDevice *device = self.inputCamera;
    NSError *error;
    if ([device lockForConfiguration:&error])
    {
        [device setExposureTargetBias:value completionHandler:^(CMTime syncTime)
         {
             
         }];
        [device unlockForConfiguration];
    }
}

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
                                           deviceInput:(AVCaptureDeviceInput*)deviceInput
                                           previewSize:(CGSize)frameSize
{
    CGPoint pointOfInterest = CGPointMake(0.5f, 0.5f);
    
    if( deviceInput.device.position == AVCaptureDevicePositionFront)
    {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }
    
    CGRect cleanAperture;
    for (AVCaptureInputPort *port in [deviceInput ports])
    {
        if ([port mediaType] == AVMediaTypeVideo)
        {
            cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
            CGSize apertureSize = cleanAperture.size;
            CGPoint point = viewCoordinates;
            
            CGFloat apertureRatio = apertureSize.height / apertureSize.width;
            CGFloat viewRatio = frameSize.width / frameSize.height;
            CGFloat xc = .5f;
            CGFloat yc = .5f;
            
            // Scale, switch x and y, and reverse x
            if (viewRatio > apertureRatio) {
                CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2; // Account for cropped height
                yc = (frameSize.width - point.x) / frameSize.width;
            } else {
                CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2); // Account for cropped width
                xc = point.y / frameSize.height;
            }
            
            pointOfInterest = CGPointMake(xc, yc);
            break;
        }
    }
    return pointOfInterest;
}


- (void) setFocusAtPoint:(CGPoint) point{
    [self focusAtPoint:point];
    [self exposureAtPoint:point];
}

- (void) setFocusAtPoint:(CGPoint) point previewSize:(CGSize) size{
    
    CGPoint foucsPoint = [self convertToPointOfInterestFromViewCoordinates:point deviceInput:[self currentVideoInput] previewSize :size];
    [self focusAndExposureAtPoint:foucsPoint];
}


- (void) faceFocusAtPoint:(CGPoint) point previewSize:(CGSize) size{
    CGPoint foucsPoint = [self convertToPointOfInterestFromViewCoordinates:point deviceInput:[self currentVideoInput] previewSize :size];
    [self faceFocusAtPoint:foucsPoint];
}


- (void) setAudioPlayOffset:(float)offset{
    if (self.audioPlayer) {
        self.audioFinished = NO;
        self.audioPlayer.currentTime = offset;
    }
    self.audioPlayStart = offset;
}

-(void)dealloc{
    NSLog(@"dealloc %s, %s",__FILE__ ,__FUNCTION__);
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    
    self.audioFinished = flag;
    
    if (!flag)
    {
        if(self.playStatusDelegate != nil)
        {
            [self.playStatusDelegate backgroundDecodeError];
        }
        return;
    }
    
    if (flag)
    {
        self.currentMusicTime = 0.f;
    }
    
    if(self.playStatusDelegate != nil)
    {
        [self.playStatusDelegate backgroundPlayEnd];
    }
}

- (NSTimeInterval) currentPlayTime
{
    return self.audioPlayer.deviceCurrentTime - self.lastTimeInterval;
}

@end

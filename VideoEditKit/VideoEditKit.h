//
//  VideoEditKit.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/1.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 Core Process
*/
#import <VideoEditKit/DCVideoCamera.h>
#import <VideoEditKit/DCVideoPreview.h>
#import <VideoEditKit/DCSpecialEffectsView.h>
#import <VideoEditKit/DCMovieAssetExport.h>
#import <VideoEditKit/DCEffectController.h>

/**
 * 文件转码导出
 */

#import <VideoEditKit/HAVVideoExport.h>

/**
 *基础美颜
 */
#import <VideoEditKit/HGPUBeauty.h>
#import <VideoEditKit/HGPUBeautyFilterController.h>

/**
 *基础滤镜
 */
#import <VideoEditKit/HAVLutImageFilter.h>
#import <VideoEditKit/HAVGPUImageLutFilter.h>
#import <VideoEditKit/HAVGPULightLutFilter.h>
#import <VideoEditKit/HAVLutImageFilterController.h>

/**
 *Gif
 */
#import <VideoEditKit/HAVGifFilter.h>
#import <VideoEditKit/HAVGifFilterController.h>

/**水印*/
#import <VideoEditKit/HWaterMark.h>
#import <VideoEditKit/HWaterMarkFilter.h>
#import <VideoEditKit/HWatermarkExport.h>

/**
 *手指画
 */
#import <VideoEditKit/HAVScrawAndTextFilter.h>
#import <VideoEditKit/HAVScrawAndTextFilterController.h>

/**分屏*/
#import <VideoEditKit/HAVSpliteFilter.h>
#import <VideoEditKit/HAVSpliteFilterController.h>

/**粒子*/
#import <VideoEditKit/HAVParticleFilter.h>
#import <VideoEditKit/HAVParticleFilterController.h>

/**射线抠图*/
#import <VideoEditKit/HCutOutFilter.h>
#import <VideoEditKit/HCutOutFilterController.h>

/**
 *视频特效
 */

#import <VideoEditKit/HAVSpecialEffectsController.h>
#import <VideoEditKit/HAVVideoEffect.h>
#import <VideoEditKit/HAVVideoEffectFilter.h>
#import <VideoEditKit/HAVVideoEffectFilterController.h>
#import <VideoEditKit/HAVVideoEffectManager.h>
#import <VideoEditKit/HAVVideoEffectProgramManager.h>

/*
 *裁剪
 */

#import <VideoEditKit/HCropFilter.h>


/**
 视频处理 头文件
 **/
#import <VideoEditKit/AVAsset+MetalData.h>
#import <VideoEditKit/AVURLAsset+MetalData.h>
#import <VideoEditKit/HAVAudioPlayer.h>
#import <VideoEditKit/HAVAlignment.h>
#import <VideoEditKit/HAVAudioItem.h>
#import <VideoEditKit/HAVAudioRender.h>
#import <VideoEditKit/HAVAudioTrack.h>
#import <VideoEditKit/HAVDataSourceDelegate.h>
#import <VideoEditKit/HAVFileManager.h>
#import <VideoEditKit/HAVGPUImageMovie.h>
#import <VideoEditKit/HAVGPUImageMovieMix.h>
#import <VideoEditKit/HAVImageGenerator.h>
#import <VideoEditKit/HAVMetadata.h>
#import <VideoEditKit/HAVMetadataRetreiver.h>
#import <VideoEditKit/HAVMovieFileReader.h>
#import <VideoEditKit/HAVMutiTracksPlayerItem.h>
#import <VideoEditKit/HAVPlayer.h>
#import <VideoEditKit/HAVPlayerItem.h>
#import <VideoEditKit/HAVQuickSpeedImageMovie.h>
#import <VideoEditKit/HAVSynthesis.h>
#import <VideoEditKit/HAVVideoClip.h>
#import <VideoEditKit/HAVVideoSize.h>
#import <VideoEditKit/HAVVideoTrack.h>
#import <VideoEditKit/HAVVideoTrackItem.h>
#import <VideoEditKit/HAVMovieReader.h>


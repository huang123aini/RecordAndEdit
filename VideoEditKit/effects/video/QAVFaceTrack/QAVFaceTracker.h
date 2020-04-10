
#import <GPUKit/GPUKit.h>
#import "QAVFaceTrackObject.h"

@interface QAVFaceTracker : NSObject

+ (QAVFaceTracker *) getInstance;

+ (void) release;

- (void) reset;

- (QAVFaceTrackObject *) getFaceTackObject:(CGSize)size withPixelBuffer:(uint8_t *) buffer position:(AVCaptureDevicePosition)position;

@end

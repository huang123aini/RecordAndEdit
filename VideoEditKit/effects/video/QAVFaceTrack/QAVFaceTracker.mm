
#import "CMOrientation.h"
#import "QAVFaceTracker.h"
//#import "st_mobile_common.h"
//#import "st_mobile_object.h"

static QAVFaceTracker *tracker;

@interface QAVFaceTracker ()
{
  //  st_handle_t _hTracker;
}

@property (nonatomic, strong) CMOrientation *orientation;

@end

@implementation QAVFaceTracker

+ (QAVFaceTracker *) getInstance
{
    if(tracker == nil)
    {
        tracker = [[self alloc] init];
    }
    return tracker;
}
- (instancetype) init
{
    self = [super init];
    if(self != nil)
    {
        //_hTracker = NULL;
        self.orientation = [CMOrientation getInstance];
    }
    return self;
}

- (void) reset
{
    
}

- (void)destoryFaceTrack
{
//    if (_hTracker != NULL) {
//        st_mobile_object_tracker_destroy(_hTracker);
//        _hTracker = NULL;
//    }
}

+ (void) release{
    if(tracker != nil){
        [tracker destoryFaceTrack];
    }
}


- (BOOL) initFaceTrack:(CGSize) size{
    
    [self destoryFaceTrack];
    
//    st_result_t iRet = st_mobile_object_tracker_create(&_hTracker);
//
//    if (ST_OK != iRet || _hTracker == NULL) {
//
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"通用物体跟踪SDK初始化失败，可能是SDK权限过期或与绑定包名不符" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
//
//        [alert show];
//    }
    return NO;
}

- (QAVFaceTrackObject *) getFaceTackObject:(CGSize)size withPixelBuffer:(uint8_t *) buffer position:(AVCaptureDevicePosition)position{
    return nil;
}
@end

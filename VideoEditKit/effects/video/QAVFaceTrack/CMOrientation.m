

#import "CMOrientation.h"
#import <CoreMotion/CoreMotion.h>

static CMOrientation *mInstance;

@interface CMOrientation ()

@property (nonatomic,assign) BOOL enable;
@property (nonatomic,strong) CMMotionManager *motionManager;
@property (nonatomic,assign) UIInterfaceOrientation orientation;

@end

@implementation CMOrientation

+(instancetype) getInstance{
    if(mInstance == nil){
        mInstance = [[CMOrientation alloc] init];
    }
    return mInstance;
}

- (instancetype) init{
    self = [super init];
    if(self){
        self.enable = YES;
        [self initializeMotionManager];
    }
    return self;
}

- (void) setOrientation:(UIInterfaceOrientation)orientation{
    _orientation = orientation;
}

- (UIInterfaceOrientation) getOrientation{
    if(self.enable){
        return _orientation;
    }
    return  UIInterfaceOrientationPortrait;
}

- (void) setEnable:(BOOL) enable{
    _enable = enable;
}

- (void)initializeMotionManager{
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = .2;
    self.motionManager.gyroUpdateInterval = .2;
    __weak typeof(self) weakSelf = self;
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                                 if (!error) {
                                                     UIInterfaceOrientation orientationNew;
                                                     CMAcceleration acceleration = accelerometerData.acceleration;
                                                     if (acceleration.x >= 0.75) {
                                                         orientationNew = UIInterfaceOrientationLandscapeLeft;
                                                     }
                                                     else if (acceleration.x <= -0.75) {
                                                         orientationNew = UIInterfaceOrientationLandscapeRight;
                                                     }
                                                     else if (acceleration.y <= -0.75) {
                                                         orientationNew = UIInterfaceOrientationPortrait;
                                                     }
                                                     else if (acceleration.y >= 0.75) {
                                                         orientationNew = UIInterfaceOrientationPortraitUpsideDown;
                                                     }
                                                     else {
                                                         return;
                                                     }
                                                     
                                                     if (orientationNew == weakSelf.orientation)
                                                         return;
                                                     weakSelf.orientation = orientationNew;
                                                 }
                                                 
                                             }];

}
@end

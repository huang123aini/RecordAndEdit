//
//  HAVVideoEffectProgramManager.h
//  VideoEditKit
//
//  Created by huangshiping on 2019/12/10.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAVVideoEffect.h"
@interface HAVVideoEffectProgramManager : NSObject

- (instancetype) init;

- (void) bindProgram:(HAVVideoEffect *) effect withSharedId:(NSInteger) shaderId;

- (GLProgram *) createProgramWithString:(NSString*) shaderString;

@end

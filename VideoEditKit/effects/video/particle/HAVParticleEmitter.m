//
//  HAVParticleEmitter.m
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import "HAVParticleEmitter.h"
#import "NSData+Compression.h"
#import "HAVParticleShader.h"

enum kParticlePositionType {
    kParticlePositionTypeFree = 0,
    kParticlePositionTypeRelative = 1,
    kParticlePositionTypeGrouped = 2,
};
typedef struct {
    GLKVector2 vertex;
    GLKVector2 texture;
    GLKVector4 color;
} TexturedColoredVertex;

typedef struct {
    TexturedColoredVertex bl;
    TexturedColoredVertex br;
    TexturedColoredVertex tl;
    TexturedColoredVertex tr;
} ParticleQuad;

NSString *const kGPUImageParticalFragmentShaderString = SHADER_STRING
(
 precision lowp float;
 varying vec4 varInColor;
 varying vec2 varTexCoord;
 uniform sampler2D inputImageTexture;
 uniform int u_opacityModifyRGB;
 vec4 color;
void main()
{
    if (u_opacityModifyRGB == 1) {
        color = vec4(varInColor.r * varInColor.a,
                     varInColor.g * varInColor.a,
                     varInColor.b * varInColor.a,
                     varInColor.a);
    } else {
        color = varInColor;
    }
    vec4 textureColor = texture2D(inputImageTexture, varTexCoord);
    textureColor = vec4(textureColor.rgb / (textureColor.a > 0.0?textureColor.a:1.0), textureColor.a);
    gl_FragColor =  color * textureColor;
}
);

NSString *const kGPUImageParticalVertexShaderString = SHADER_STRING
(
 attribute vec4 inPosition;
 attribute vec4 inColor;
 attribute vec2 inTexCoord;
 varying lowp vec4 varInColor;
 varying mediump vec2 varTexCoord;
 uniform mat4  mVPMatrix;
 
 void main() {
     varInColor = inColor;
     varTexCoord = inTexCoord;
     gl_Position = mVPMatrix * inPosition;
 }
 );


static const GLKVector2 SystemResolution = {540.0f, 960.0f};
// Macro which returns a random value between -1 and 1
#define RANDOM_MINUS_1_TO_1() ((random() / (GLfloat)0x3fffffff )-1.0f)

// Macro which returns a random number between 0 and 1
#define RANDOM_0_TO_1() ((random() / (GLfloat)0x7fffffff ))

// Macro which converts degrees into radians
#define DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) / 180.0 * M_PI)

// Macro that allows you to clamp a value within the defined bounds
#define CLAMP(X, A, B) ((X < A) ? A : ((X > B) ? B : X))

@interface HAVParticleEmitter(){
    int emitterType;
    
    GLKVector2 sourcePosition, sourcePositionVariance;
    GLfloat angle, angleVariance;
    GLfloat speed, speedVariance;
    GLfloat radialAcceleration, tangentialAcceleration;
    GLfloat radialAccelVariance, tangentialAccelVariance;
    GLKVector2 gravity;
    GLfloat particleLifespan, particleLifespanVariance;
    GLKVector4 startColor, startColorVariance;
    GLKVector4 finishColor, finishColorVariance;
    GLfloat startParticleSize, startParticleSizeVariance;
    GLfloat finishParticleSize, finishParticleSizeVariance;
    GLuint maxParticles;
    GLint particleCount;
    GLfloat emissionRate;
    GLfloat emitCounter;
    GLfloat elapsedTime;
    GLfloat duration;
    GLfloat rotationStart, rotationStartVariance;
    GLfloat rotationEnd, rotationEndVariance;
    GLint positionType;
    int yCoordFlipped;
    BOOL absolutePosition;
    GLuint vertexArrayName;
    
    int atlasRow,atlasCol,frameRate;
    
    int blendFuncSource, blendFuncDestination;
    
    BOOL _opacityModifyRGB;
    
    //////////////////// Particle ivars only used when a maxRadius value is provided.  These values are used for
    //////////////////// the special purpose of creating the spinning portal emitter
    GLfloat maxRadius;                        // Max radius at which particles are drawn when rotating
    GLfloat maxRadiusVariance;                // Variance of the maxRadius
    GLfloat radiusSpeed;                    // The speed at which a particle moves from maxRadius to minRadius
    GLfloat minRadius;                        // Radius from source below which a particle dies
    GLfloat minRadiusVariance;                // Variance of the minRadius
    GLfloat rotatePerSecond;                // Numeber of degress to rotate a particle around the source pos per second
    GLfloat rotatePerSecondVariance;        // Variance in degrees for rotatePerSecond
    
    //////////////////// Particle Emitter iVars
    BOOL active;
    BOOL useTexture;
    GLint particleIndex;        // Stores the number of particles that are going to be rendered
    GLint vertexIndex;         // Stores the index of the vertices being used for each particle
    
    ///////////////////// Render
    GLuint verticesID;            // Holds the buffer name of the VBO that stores the color and vertices info for the particles
    GLuint indicesID;

    ParticleQuad *quads;        // Array holding quad information for each particle;
    GLushort *indices;          // Array holding an index reference into an array of quads for rendering
    GLuint inPositionAttrib,   // Shader program attributes and uniforms
    inColorAttrib,
    inTexCoordAttrib,
    textureUniform,
    mvpMatrixUniform,
    u_opacityModifyRGB;
    GLKVector2 GLKVector2Resolution;
    GLuint textureID;
}

@property (nonatomic, strong) UIImage *textImage;
@property (nonatomic, strong) NSString *configFile;
@property (nonatomic, strong) NSMutableArray *particles;

- (BOOL)addParticle;

- (void)initParticle:(HAVParticle*)particle;

- (void)setupArrays;

- (void)setupShaders;

- (void)parseParticleConfig:(NSDictionary*)aConfig withFilePath:(NSString *) filePath;

@end

@implementation HAVParticleEmitter

@synthesize sourcePosition;
@synthesize active;
@synthesize particleCount;
@synthesize duration;

- (void)dealloc {
    
    // Release the memory we are using for our vertex and particle arrays etc
    // If vertices or particles exist then free them
    if (quads)
        free(quads);
    
    self.particles = nil;

    if (indices)
        free(indices);
    
    // Release the VBOs created
    glDeleteBuffers(1, &verticesID);
    glDeleteBuffers(1, &indicesID);
    
    // delete the texture
    if(textureID > 0){
        glDeleteTextures(1, &textureID);
    }
}

// Initialises a particle emitter using configuration read from a file
- (instancetype) initParticleEmitterWithFile:(NSString*)filePath{
    self = [super init];
    if(self != nil){
        self.configFile = filePath;
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
        if(dict != nil){
            GLKVector2Resolution = SystemResolution;
            [self parseParticleConfig:dict withFilePath:filePath];
            [self setupArrays];
            [self setupShaders];
            [self usePrograma];
            GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, GLKVector2Resolution.x, 0, GLKVector2Resolution.y, 1, -1);
            projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1, -1.0, 1);
            projectionMatrix = GLKMatrix4Translate(projectionMatrix, 0, -GLKVector2Resolution.y, 0);
            glUniformMatrix4fv(mvpMatrixUniform, 1, GL_FALSE, projectionMatrix.m);
        }
    }
    return self;
}

- (void)initParticle:(HAVParticle*)particle{
    // Init the position of the particle.  This is based on the source position of the particle emitter
    // plus a configured variance.  The RANDOM_MINUS_1_TO_1 macro allows the number to be both positive
    // and negative
    if(particle.startPos.x != 0.0f && particle.startPos.y != 0.0f){
        GLKVector2 position = {0, 0};
        position.x = particle.startPos.x + sourcePositionVariance.x * RANDOM_MINUS_1_TO_1();
        position.y = particle.startPos.y + sourcePositionVariance.y * RANDOM_MINUS_1_TO_1();
        particle.position = position;
    }else{
        GLKVector2 position = {0, 0};
        position.x = sourcePosition.x + sourcePositionVariance.x * RANDOM_MINUS_1_TO_1();
        position.y = sourcePosition.y + sourcePositionVariance.y * RANDOM_MINUS_1_TO_1();
        particle.position = position;

        GLKVector2 startPos;
        startPos.x = sourcePosition.x;
        startPos.y = sourcePosition.y;
        particle.startPos = startPos;
    }
    // Init the direction of the particle.  The newAngle is calculated using the angle passed in and the
    // angle variance.
    GLfloat newAngle = GLKMathDegreesToRadians(angle + angleVariance * RANDOM_MINUS_1_TO_1());
    
    // Create a new GLKVector2 using the newAngle
    GLKVector2 vector = GLKVector2Make(cosf(newAngle), sinf(newAngle));
    
    // Calculate the vectorSpeed using the speed and speedVariance which has been passed in
    GLfloat vectorSpeed = speed + speedVariance * RANDOM_MINUS_1_TO_1();
    
    // The particles direction vector is calculated by taking the vector calculated above and
    // multiplying that by the speed
    particle.direction = GLKVector2MultiplyScalar(vector, vectorSpeed);
    
    // Calculate the particles life span using the life span and variance passed in
    particle.timeToLive = MAX(0, particleLifespan + particleLifespanVariance * RANDOM_MINUS_1_TO_1());
    float startRadius = maxRadius + maxRadiusVariance * RANDOM_MINUS_1_TO_1();
    float endRadius = minRadius + minRadiusVariance * RANDOM_MINUS_1_TO_1();
    
    // Set the default diameter of the particle from the source position
    particle.radius = startRadius;
    particle.radiusDelta = (endRadius - startRadius) / particle.timeToLive;
    particle.angle = GLKMathDegreesToRadians(angle + angleVariance * RANDOM_MINUS_1_TO_1());
    particle.degreesPerSecond = GLKMathDegreesToRadians(rotatePerSecond + rotatePerSecondVariance * RANDOM_MINUS_1_TO_1());
    
    particle.radialAcceleration = radialAcceleration + radialAccelVariance * RANDOM_MINUS_1_TO_1();
    particle.tangentialAcceleration = tangentialAcceleration + tangentialAccelVariance * RANDOM_MINUS_1_TO_1();
    
    // Calculate the particle size using the start and finish particle sizes
    GLfloat particleStartSize = startParticleSize + startParticleSizeVariance * RANDOM_MINUS_1_TO_1();
    GLfloat particleFinishSize = finishParticleSize + finishParticleSizeVariance * RANDOM_MINUS_1_TO_1();
    particle.particleSizeDelta = ((particleFinishSize - particleStartSize) / particle.timeToLive);
    particle.particleSize = MAX(0, particleStartSize);
    // Calculate the color the particle should have when it starts its life.  All the elements
    // of the start color passed in along with the variance are used to calculate the star color
    GLKVector4 start = {0, 0, 0, 0};
    start.r = startColor.r + startColorVariance.r * RANDOM_MINUS_1_TO_1();
    start.g = startColor.g + startColorVariance.g * RANDOM_MINUS_1_TO_1();
    start.b = startColor.b + startColorVariance.b * RANDOM_MINUS_1_TO_1();
    start.a = startColor.a + startColorVariance.a * RANDOM_MINUS_1_TO_1();
    
    // Calculate the color the particle should be when its life is over.  This is done the same
    // way as the start color above
    GLKVector4 end = {0, 0, 0, 0};
    end.r = finishColor.r + finishColorVariance.r * RANDOM_MINUS_1_TO_1();
    end.g = finishColor.g + finishColorVariance.g * RANDOM_MINUS_1_TO_1();
    end.b = finishColor.b + finishColorVariance.b * RANDOM_MINUS_1_TO_1();
    end.a = finishColor.a + finishColorVariance.a * RANDOM_MINUS_1_TO_1();
    
    // Calculate the delta which is to be applied to the particles color during each cycle of its
    // life.  The delta calculation uses the life span of the particle to make sure that the
    // particles color will transition from the start to end color during its life time.  As the game
    // loop is using a fixed delta value we can calculate the delta color once saving cycles in the
    // update method
    
    particle.color = start;
    GLKVector4 color = {0, 0, 0, 0};
    color.r = ((end.r - start.r) / particle.timeToLive);
    color.g = ((end.g - start.g) / particle.timeToLive);
    color.b = ((end.b - start.b) / particle.timeToLive);
    color.a = ((end.a - start.a) / particle.timeToLive);
    particle.deltaColor = color;
    // Calculate the rotation
    GLfloat startA = rotationStart + rotationStartVariance * RANDOM_MINUS_1_TO_1();
    GLfloat endA = rotationEnd + rotationEndVariance * RANDOM_MINUS_1_TO_1();
    particle.rotation = startA;
    particle.rotationDelta = (endA - startA) / particle.timeToLive;
    

    particle.originPosition = particle.position;
    particle.originDirection = particle.direction;
}

// Renders the particles for this emitter to the screen
- (void)renderParticles{
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    glUniform1i(textureUniform, 5);
    
    // Bind to the verticesID VBO and popuate it with the necessary vertex, color and texture informaiton
    glBindBuffer(GL_ARRAY_BUFFER, verticesID);
    
    // Using glBufferSubData means that a copy is done from the quads array to the buffer rather than recreating the buffer which
    // would be an allocation and copy. The copy also only takes over the number of live particles. This provides a nice performance
    // boost.
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(ParticleQuad) * particleIndex, quads);
    // Make sure that the vertex attributes we are using are enabled. This is a cheap call so OK to do each frame
    glEnableVertexAttribArray(inPositionAttrib);
    glEnableVertexAttribArray(inColorAttrib);
    glEnableVertexAttribArray(inTexCoordAttrib);
    
    // Configure the vertex pointer which will use the currently bound VBO for its data
    glVertexAttribPointer(inPositionAttrib, 2, GL_FLOAT, GL_FALSE, sizeof(TexturedColoredVertex), 0);
    glVertexAttribPointer(inColorAttrib, 4, GL_FLOAT, GL_FALSE, sizeof(TexturedColoredVertex), (GLvoid*) offsetof(TexturedColoredVertex, color));
    glVertexAttribPointer(inTexCoordAttrib, 2, GL_FLOAT, GL_FALSE, sizeof(TexturedColoredVertex), (GLvoid*) offsetof(TexturedColoredVertex, texture));
    
    glEnable(GL_BLEND);
    // Set the blend function based on the configuration
    glBlendFunc(blendFuncSource, blendFuncDestination);
    // Set the opacity modifier shader parameter
    glUniform1i(u_opacityModifyRGB, _opacityModifyRGB);
    // Now that all of the VBOs have been used to configure the vertices, pointer size and color
    // use glDrawArrays to draw the points
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesID);
    glDrawElements(GL_TRIANGLES, particleIndex * 6, GL_UNSIGNED_SHORT, 0);
    glDisable(GL_BLEND);
    // Unbind the current VBO
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindVertexArrayOES(0);
}

- (NSInteger) liveParticleCount :(CGFloat) aDelta{
    NSInteger count = 0;
    for (HAVParticle *particle in self.particles){
        if(particle.timeToLive + particle.createTime >= aDelta && aDelta >=   particle.createTime){
            count ++;
        }
    }
    return count;
}

- (void)updateWithDelta:(GLfloat)aDelta{
    // If the emitter is active and the emission rate is greater than zero then emit particles
    if (active && emissionRate) {
        GLfloat rate = 1.0f/emissionRate;
        particleCount = (int) [self liveParticleCount:aDelta];
        if (particleCount < maxParticles)
            emitCounter += (aDelta - elapsedTime);

        while (particleCount < maxParticles && emitCounter > rate) {
            [self addParticleAtTime:elapsedTime];
            emitCounter -= rate;
        }

        elapsedTime = aDelta;
        if (duration != -1 && duration < elapsedTime)
            [self stopParticleEmitter];
    }
    // Reset the particle index before updating the particles in this emitter
    particleIndex = 0;
    
    // Loop through all the particles updating their location and color

    for (HAVParticle *aparticle in self.particles) {
        // Get the particle for the current particle index
        HAVParticle *currentParticle = [aparticle currentParticle:aDelta emitterType:emitterType yCoordFlipped:yCoordFlipped gravity:gravity];
        if(currentParticle != nil){
            // As we are rendering the particles as quads, we need to define 6 vertices for each particle
            GLfloat halfSize = currentParticle.particleSize * 0.5f;

            if(positionType == kParticlePositionTypeFree){
                
            }else if(positionType == kParticlePositionTypeRelative){
                
            }else if(positionType == kParticlePositionTypeGrouped){
                GLKVector2 deltaPosition =  GLKVector2Subtract(currentParticle.position, currentParticle.startPos);
                currentParticle.position = GLKVector2Add(deltaPosition, sourcePosition);
            }
            // If a rotation has been defined for this particle then apply the rotation to the vertices that define
            // the particle
            if (currentParticle.rotation) {
                float x1 = -halfSize;
                float y1 = -halfSize;
                float x2 = halfSize;
                float y2 = halfSize;
                float x = currentParticle.position.x;
                float y = currentParticle.position.y;
                float r = GLKMathDegreesToRadians(currentParticle.rotation);
                float cr = cosf(r);
                float sr = sinf(r);
                float ax = x1 * cr - y1 * sr + x;
                float ay = x1 * sr + y1 * cr + y;
                float bx = x2 * cr - y1 * sr + x;
                float by = x2 * sr + y1 * cr + y;
                float cx = x2 * cr - y2 * sr + x;
                float cy = x2 * sr + y2 * cr + y;
                float dx = x1 * cr - y2 * sr + x;
                float dy = x1 * sr + y2 * cr + y;
                
                quads[particleIndex].bl.vertex.x = ax;
                quads[particleIndex].bl.vertex.y = ay;
                quads[particleIndex].bl.color = currentParticle.color;
                
                quads[particleIndex].br.vertex.x = bx;
                quads[particleIndex].br.vertex.y = by;
                quads[particleIndex].br.color = currentParticle.color;
                
                quads[particleIndex].tl.vertex.x = dx;
                quads[particleIndex].tl.vertex.y = dy;
                quads[particleIndex].tl.color = currentParticle.color;
                
                quads[particleIndex].tr.vertex.x = cx;
                quads[particleIndex].tr.vertex.y = cy;
                quads[particleIndex].tr.color = currentParticle.color;
                
            } else {
                // Using the position of the particle, work out the four vertices for the quad that will hold the particle
                // and load those into the quads array.
                quads[particleIndex].bl.vertex.x = currentParticle.position.x - halfSize;
                quads[particleIndex].bl.vertex.y = currentParticle.position.y - halfSize;
                quads[particleIndex].bl.color = currentParticle.color;
                
                quads[particleIndex].br.vertex.x = currentParticle.position.x + halfSize;
                quads[particleIndex].br.vertex.y = currentParticle.position.y - halfSize;
                quads[particleIndex].br.color = currentParticle.color;
                
                quads[particleIndex].tl.vertex.x = currentParticle.position.x - halfSize;
                quads[particleIndex].tl.vertex.y = currentParticle.position.y + halfSize;
                quads[particleIndex].tl.color = currentParticle.color;
                
                quads[particleIndex].tr.vertex.x = currentParticle.position.x + halfSize;
                quads[particleIndex].tr.vertex.y = currentParticle.position.y + halfSize;
                quads[particleIndex].tr.color = currentParticle.color;
            }
            
            if(atlasCol > 1  || atlasRow > 1){
                int index = 0;
                GLfloat diff = aDelta - currentParticle.createTime;
                if(diff > 0){
                    index =((int)(diff * frameRate))%(atlasCol*atlasRow);
                }
                int row = index / atlasCol;
                int col = index % atlasCol;
                
                quads[particleIndex].bl.texture.x = col * 1.0f/atlasCol;
                quads[particleIndex].bl.texture.y = row * 1.0f/atlasRow;
                quads[particleIndex].br.texture.x = (col+1) * 1.0f/atlasCol ;
                quads[particleIndex].br.texture.y = quads[particleIndex].bl.texture.y;
                quads[particleIndex].tl.texture.x = quads[particleIndex].bl.texture.x;
                quads[particleIndex].tl.texture.y = (row+1) * 1.0f/atlasRow;
                quads[particleIndex].tr.texture.x = (col+1) * 1.0f/atlasCol ;
                quads[particleIndex].tr.texture.y = (row+1) * 1.0f/atlasRow;
            }
            // Update the particle and vertex counters
            particleIndex++;
            if(particleIndex >= maxParticles){
                return ;
            }
        }
    }
}


- (void) setSourcePosition:(GLKVector2)position{
//    if(self.needUpdatePosition){
        GLKVector2 resolution = GLKVector2Multiply(position, GLKVector2Make(1.0f, -1.0f));
        resolution = GLKVector2Add(resolution, GLKVector2Make(0.0f, 1.0f));
        sourcePosition = GLKVector2Multiply(GLKVector2Resolution , resolution);
//    }
}



// Stops the particle emitter
- (void)stopParticleEmitter{
    active = NO;
    elapsedTime = 0;
    emitCounter = 0;
}

// Resets the particle system
- (void)reset{
    active = YES;
    elapsedTime = 0;
    for (HAVParticle *particle in self.particles){
        particle.timeToLive = 0.0f;
    }
    emitCounter = 0;
    emissionRate = maxParticles / particleLifespan;
}

- (void)usePrograma{
    [[HAVParticleShader sharedInstance] setActiveShaderProgram];
}

- (void)setupShaders
{
    HAVParticleShader *shader = [HAVParticleShader sharedInstance];
    inPositionAttrib = shader.inPositionAttrib;
    inColorAttrib = shader.inColorAttrib;
    inTexCoordAttrib = shader.inTexCoordAttrib;
    textureUniform = shader.textureUniform;
    u_opacityModifyRGB = shader.u_opacityModifyRGB;
    mvpMatrixUniform = shader.mvpMatrixUniform;

}

- (void)setupArrays {
    // Allocate the memory necessary for the particle emitter arrays
//    particles = malloc( sizeof(Particle) * maxParticles );
    
    self.particles = [NSMutableArray array];
    quads = calloc(sizeof(ParticleQuad), maxParticles);
    indices = calloc(sizeof(GLushort), maxParticles * 6);
    // Set up the indices for all particles. This provides an array of indices into the quads array that is used during
    // rendering. As we are rendering quads there are six indices for each particle as each particle is made of two triangles
    // that are each defined by three vertices.
    for( int i=0;i< maxParticles;i++) {
        indices[i*6+0] = i*4+0;
        indices[i*6+1] = i*4+1;
        indices[i*6+2] = i*4+2;
        
        indices[i*6+5] = i*4+2;
        indices[i*6+4] = i*4+3;
        indices[i*6+3] = i*4+1;
    }

    // Set up texture coordinates for all particles as these will not change.
    for(int i=0; i<maxParticles; i++) {
        quads[i].bl.texture.x = 0;
        quads[i].bl.texture.y = 0;
        
        quads[i].br.texture.x = 1.0;
        
        if(atlasRow > 1){
            quads[i].br.texture.x = 1.0 / atlasCol;
        }
        
        quads[i].br.texture.y = 0;
        
        quads[i].tl.texture.x = 0;
        quads[i].tl.texture.y = 1.0;
        
        if(atlasCol > 1){
            quads[i].tl.texture.y = 1.0 / atlasRow;
        }

        quads[i].tr.texture.x = 1.0;
        
        if(atlasRow > 1){
            quads[i].tr.texture.x = 1.0 / atlasCol;
        }
        quads[i].tr.texture.y = 1.0;
        if(atlasCol > 1){
            quads[i].tr.texture.y = 1.0 / atlasRow;
        }
    }
    
    // If one of the arrays cannot be allocated throw an assertion as this is bad
    NSAssert(self.particles && quads, @"ERROR - ParticleEmitter: Could not allocate arrays.");
    
    // Generate the vertices VBO
    glGenBuffers(1, &verticesID);
    glBindBuffer(GL_ARRAY_BUFFER, verticesID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(ParticleQuad) * maxParticles, quads, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    //Generate the indices VBO
    glGenBuffers(1, &indicesID);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesID);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLushort) * maxParticles * 6, indices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    // By default the particle emitter is active when created
    active = YES;
    
    // Set the particle count to zero
    particleCount = 0;
    
    // Reset the elapsed time
    elapsedTime = 0;
}


- (GLuint)setupTexture:(UIImage *)image {
    CGImageRef cgImageRef = [image CGImage];
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    CGRect rect = CGRectMake(0, 0, width, height);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, cgImageRef);

    glEnable(GL_TEXTURE_2D);

    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);

    glBindTexture(GL_TEXTURE_2D, 0);
    CGContextRelease(context);
    free(imageData);

    return textureID;
}

- (void)parseParticleConfig:(NSDictionary*)aConfig withFilePath:(NSString *) filePath{
    // Load all of the values from the XML file into the particle emitter.  The functions below are using the
    if(aConfig != nil){
        emitterType = [[aConfig objectForKey:@"emitterType"] intValue];
        float x = [[aConfig objectForKey:@"sourcePositionx"] floatValue];
        float y = [[aConfig objectForKey:@"sourcePositiony"] floatValue];
        sourcePosition = GLKVector2Make(x, y);
        
        x = [[aConfig objectForKey:@"sourcePositionVariancex"] floatValue];
        y = [[aConfig objectForKey:@"sourcePositionVariancey"] floatValue];
        
        sourcePositionVariance = GLKVector2Make(x, y);
        
        speed = [[aConfig objectForKey:@"speed"] floatValue];
        
        speedVariance = [[aConfig objectForKey:@"speedVariance"] floatValue];
        
        particleLifespan = [[aConfig objectForKey:@"particleLifespan"] floatValue];
        
        particleLifespanVariance = [[aConfig objectForKey:@"particleLifespanVariance"] floatValue];
        
        angle = [[aConfig objectForKey:@"angle"] floatValue];
        
        
        angleVariance = [[aConfig objectForKey:@"angleVariance"] floatValue];
        
        x = [[aConfig objectForKey:@"gravityx"] floatValue];
        y = [[aConfig objectForKey:@"gravityy"] floatValue];
        gravity = GLKVector2Make(x, y);
        
        radialAcceleration = [[aConfig objectForKey:@"radialAcceleration"] floatValue];
        
        radialAccelVariance = [[aConfig objectForKey:@"radialAccelVariance"] floatValue];
        
        tangentialAcceleration =[[aConfig objectForKey:@"tangentialAcceleration"] floatValue];
        
        tangentialAccelVariance = [[aConfig objectForKey:@"tangentialAccelVariance"] floatValue];
        
        float r = [[aConfig objectForKey:@"startColorRed"] floatValue];
        float g = [[aConfig objectForKey:@"startColorGreen"] floatValue];
        float b = [[aConfig objectForKey:@"startColorBlue"] floatValue];
        float a = [[aConfig objectForKey:@"startColorAlpha"] floatValue];
        
        startColor = GLKVector4Make(r, g, b, a);
        
        r = [[aConfig objectForKey:@"startColorVarianceRed"] floatValue];
        g = [[aConfig objectForKey:@"startColorVarianceGreen"] floatValue];
        b = [[aConfig objectForKey:@"startColorVarianceBlue"] floatValue];
        a = [[aConfig objectForKey:@"startColorVarianceAlpha"] floatValue];
        
        startColorVariance = GLKVector4Make(r, g, b, a);
        
        r = [[aConfig objectForKey:@"finishColorRed"] floatValue];
        g = [[aConfig objectForKey:@"finishColorGreen"] floatValue];
        b = [[aConfig objectForKey:@"finishColorBlue"] floatValue];
        a = [[aConfig objectForKey:@"finishColorAlpha"] floatValue];
        
        finishColor = GLKVector4Make(r, g, b, a);
        
        r = [[aConfig objectForKey:@"finishColorVarianceRed"] floatValue];
        g = [[aConfig objectForKey:@"finishColorVarianceGreen"] floatValue];
        b = [[aConfig objectForKey:@"finishColorVarianceBlue"] floatValue];
        a = [[aConfig objectForKey:@"finishColorVarianceAlpha"] floatValue];
        
        finishColorVariance = GLKVector4Make(r, g, b, a);
        
        maxParticles = [[aConfig objectForKey:@"maxParticles"] intValue];
        
        startParticleSize = [[aConfig objectForKey:@"startParticleSize"] floatValue];
        
        startParticleSizeVariance=[[aConfig objectForKey:@"startParticleSizeVariance"] floatValue];
        
        finishParticleSize = [[aConfig objectForKey:@"finishParticleSize"] floatValue];
        
        finishParticleSizeVariance =[[aConfig objectForKey:@"finishParticleSizeVariance"] floatValue];
        
        duration = [[aConfig objectForKey:@"duration"] floatValue];
        
        blendFuncSource = [[aConfig objectForKey:@"blendFuncSource"] intValue];
        
        blendFuncDestination =[[aConfig objectForKey:@"blendFuncDestination"] intValue];
        
        maxRadius = [[aConfig objectForKey:@"maxRadius"] floatValue];
        
        maxRadiusVariance = [[aConfig objectForKey:@"maxRadiusVariance"] floatValue];
        
        minRadius = [[aConfig objectForKey:@"minRadius"] floatValue];
        
        minRadiusVariance = [[aConfig objectForKey:@"minRadiusVariance"] floatValue];
        
        rotatePerSecond = [[aConfig objectForKey:@"rotatePerSecond"] floatValue];
        
        rotatePerSecondVariance = [[aConfig objectForKey:@"rotatePerSecondVariance"] floatValue];
        
        rotationStart = [[aConfig objectForKey:@"rotationStart"] floatValue];
        
        rotationStartVariance = [[aConfig objectForKey:@"rotationStartVariance"] floatValue];
        
        rotationEnd = [[aConfig objectForKey:@"rotationEnd"] floatValue];
        
        rotationEndVariance = [[aConfig objectForKey:@"rotationEndVariance"] floatValue];
        
        yCoordFlipped = [[aConfig objectForKey:@"yCoordFlipped"] intValue];
        absolutePosition = [[aConfig objectForKey:@"absolutePosition"] boolValue];
        
        atlasRow = [[aConfig objectForKey:@"atlasRow"] intValue];
        atlasRow = atlasRow < 1 ? 1:atlasRow;
        atlasCol = [[aConfig objectForKey:@"atlasCol"] intValue];
        atlasCol = atlasCol < 1 ? 1:atlasCol;
        frameRate = [[aConfig objectForKey:@"frameRate"] intValue];
        
        positionType = [[aConfig objectForKey:@"positionType"] intValue];
        // Calculate the emission rate
        emissionRate                = maxParticles / particleLifespan;
        emitCounter                 = 0;
        
        
        // First thing to grab is the texture that is to be used for the point sprite
        
        NSString *textureFileName = [aConfig objectForKey:@"textureFileName"];
        NSString *textureData = [aConfig objectForKey:@"textureImageData"];
        if (textureFileName.length > 0 && filePath.length > 0) {
            NSData *tiffData = nil;
            NSError *error;
            
            NSString*path =  [[filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:textureFileName];
            if([[NSFileManager defaultManager] fileExistsAtPath:path]){
                tiffData = [[NSData alloc] initWithContentsOfFile:path options:NSDataReadingUncached error:&error];
                
                // Create a UIImage from the tiff data to extract colorspace and alpha info
                
            }else if(textureData.length > 0){
                tiffData = [[[NSData alloc] initWithBase64EncodedString:textureData] gzipInflate];
            }
            if(tiffData.length > 0){
                
                UIImage *image =  [UIImage imageWithData:tiffData];
                CGImageAlphaInfo info = CGImageGetAlphaInfo(image.CGImage);
                CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
                
                // Detect if the image contains alpha data
                BOOL hasAlpha = ((info == kCGImageAlphaPremultipliedLast) ||
                                 (info == kCGImageAlphaPremultipliedFirst) ||
                                 (info == kCGImageAlphaLast) ||
                                 (info == kCGImageAlphaFirst) ? YES : NO);
                
                // Detect if alpha data is premultiplied
                BOOL premultiplied = colorSpace && hasAlpha;
                //#define GL_SRC_ALPHA                                     0x0302
                //#define GL_ONE_MINUS_SRC_ALPHA                           0x0303
                // Is opacity modification required
                _opacityModifyRGB = NO;
                if (blendFuncSource == GL_ONE && blendFuncDestination == GL_ONE_MINUS_SRC_ALPHA) {
                    if (premultiplied){
                        _opacityModifyRGB = YES;
                    }else {
                        blendFuncSource = GL_SRC_ALPHA;
                        blendFuncDestination = GL_ONE_MINUS_SRC_ALPHA;
                    }
                }
                self.textImage = image;
                textureID = [self setupTexture:image];
                // Set up options for GLKTextureLoader
//                NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:
//                                          @(YES), GLKTextureLoaderOriginBottomLeft,
//                                          @(premultiplied), GLKTextureLoaderApplyPremultiplication,
//                                          nil];
//
//                //         Use GLKTextureLoader to load the tiff data into a texture
//                GLKTextureInfo *texture = [GLKTextureLoader textureWithContentsOfData:tiffData options:options error:&error];
//                textureID = texture.name;
                // Throw assersion error if loading texture failed
//                NSAssert(!error, @"Unable to load texture");
            }
        }
    }
}

- (void)parseParticleDecoder:(NSCoder *) aDecoder{
    if(aDecoder != nil){
        emitterType = (int)[aDecoder decodeIntegerForKey:@"emitterType"];
        float x = [aDecoder decodeFloatForKey:@"sourcePositionx"];
        float y = [aDecoder decodeFloatForKey:@"sourcePositiony"];
        sourcePosition = GLKVector2Make(x, y);
        
        x = [aDecoder decodeFloatForKey:@"sourcePositionVariancex"];
        y = [aDecoder decodeFloatForKey:@"sourcePositionVariancey"];
        
        sourcePositionVariance = GLKVector2Make(x, y);
        
        speed = [aDecoder decodeFloatForKey:@"speed"];
        
        speedVariance = [aDecoder decodeFloatForKey:@"speedVariance"];
        
        particleLifespan = [aDecoder decodeFloatForKey:@"particleLifespan"];
        
        particleLifespanVariance = [aDecoder decodeFloatForKey:@"particleLifespanVariance"];
        
        angle = [aDecoder decodeFloatForKey:@"angle"];
        
        angleVariance = [aDecoder decodeFloatForKey:@"angleVariance"];
        
        x = [aDecoder decodeFloatForKey:@"gravityx"];
        y = [aDecoder decodeFloatForKey:@"gravityy"];
        
        gravity = GLKVector2Make(x, y);
        
        radialAcceleration = [aDecoder decodeFloatForKey:@"radialAcceleration"];
        
        radialAccelVariance = [aDecoder decodeFloatForKey:@"radialAccelVariance"];

        tangentialAcceleration = [aDecoder decodeFloatForKey:@"tangentialAcceleration"];
        
        tangentialAccelVariance = [aDecoder decodeFloatForKey:@"tangentialAccelVariance"];
        
        float r = [aDecoder decodeFloatForKey:@"startColorRed"];
        float g = [aDecoder decodeFloatForKey:@"startColorGreen"];
        float b = [aDecoder decodeFloatForKey:@"startColorBlue"];
        float a = [aDecoder decodeFloatForKey:@"startColorAlpha"];
        
        startColor = GLKVector4Make(r, g, b, a);
        
        r = [aDecoder decodeFloatForKey:@"startColorVarianceRed"];
        g = [aDecoder decodeFloatForKey:@"startColorVarianceGreen"];
        b = [aDecoder decodeFloatForKey:@"startColorVarianceBlue"];
        a = [aDecoder decodeFloatForKey:@"startColorVarianceAlpha"];
        
        startColorVariance = GLKVector4Make(r, g, b, a);
        
        r = [aDecoder decodeFloatForKey:@"finishColorRed"];
        g = [aDecoder decodeFloatForKey:@"finishColorGreen"];
        b = [aDecoder decodeFloatForKey:@"finishColorBlue"];
        a = [aDecoder decodeFloatForKey:@"finishColorAlpha"];
        
        finishColor = GLKVector4Make(r, g, b, a);
        
        r = [aDecoder decodeFloatForKey:@"finishColorVarianceRed"];
        g = [aDecoder decodeFloatForKey:@"finishColorVarianceGreen"];
        b = [aDecoder decodeFloatForKey:@"finishColorVarianceBlue"];
        a = [aDecoder decodeFloatForKey:@"finishColorVarianceAlpha"];
        
        finishColorVariance = GLKVector4Make(r, g, b, a);
        
        maxParticles = (GLuint)[aDecoder decodeIntegerForKey:@"maxParticles"];
        
        startParticleSize = [aDecoder decodeFloatForKey:@"startParticleSize"];
        
        startParticleSizeVariance = [aDecoder decodeFloatForKey:@"startParticleSizeVariance"];
        
        finishParticleSize = [aDecoder decodeFloatForKey:@"finishParticleSize"];
        
        finishParticleSizeVariance = [aDecoder decodeFloatForKey:@"finishParticleSizeVariance"];
        
        duration = [aDecoder decodeFloatForKey:@"duration"];
        
        blendFuncSource = [aDecoder decodeIntForKey:@"blendFuncSource"];
        
        blendFuncDestination = [aDecoder decodeIntForKey:@"blendFuncDestination"];
        
        maxRadius = [aDecoder decodeFloatForKey:@"maxRadius"];
        
        maxRadiusVariance = [aDecoder decodeFloatForKey:@"maxRadiusVariance"];
        
        minRadius = [aDecoder decodeFloatForKey:@"minRadius"];
        
        minRadiusVariance = [aDecoder decodeFloatForKey:@"minRadiusVariance"];
        
        rotatePerSecond = [aDecoder decodeFloatForKey:@"rotatePerSecond"];
        
        rotatePerSecondVariance = [aDecoder decodeFloatForKey:@"rotatePerSecondVariance"];
        
        rotationStart = [aDecoder decodeFloatForKey:@"rotationStart"];
        
        rotationStartVariance = [aDecoder decodeFloatForKey:@"rotationStartVariance"];
        
        rotationEnd = [aDecoder decodeFloatForKey:@"rotationEnd"];
        
        rotationEndVariance = [aDecoder decodeFloatForKey:@"rotationEndVariance"];
        
        yCoordFlipped = [aDecoder decodeIntForKey:@"yCoordFlipped"];
        absolutePosition = [aDecoder decodeBoolForKey:@"absolutePosition"];

        atlasRow = [aDecoder decodeIntForKey:@"atlasRow"];
        atlasRow = atlasRow < 1 ? 1:atlasRow;
        atlasCol = [aDecoder decodeIntForKey:@"atlasCol"];
        atlasCol = atlasCol < 1 ? 1:atlasCol;
        frameRate = [aDecoder decodeIntForKey:@"frameRate"];
        positionType = [aDecoder decodeIntForKey:@"positionType"];
        // Calculate the emission rate
        emissionRate                = maxParticles / particleLifespan;
        emitCounter                 = 0;
        // First thing to grab is the texture that is to be used for the point sprite
    
        NSData *tiffData = [aDecoder decodeObjectForKey:@"textureImageData"];
        if(tiffData.length > 0){
            UIImage *image =  [UIImage imageWithData:tiffData];
            CGImageAlphaInfo info = CGImageGetAlphaInfo(image.CGImage);
            CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
            
            // Detect if the image contains alpha data
            BOOL hasAlpha = ((info == kCGImageAlphaPremultipliedLast) ||
                             (info == kCGImageAlphaPremultipliedFirst) ||
                             (info == kCGImageAlphaLast) ||
                             (info == kCGImageAlphaFirst) ? YES : NO);
            
            // Detect if alpha data is premultiplied
            BOOL premultiplied = colorSpace && hasAlpha;
            
            // Is opacity modification required
            _opacityModifyRGB = NO;
            if (blendFuncSource == GL_ONE && blendFuncDestination == GL_ONE_MINUS_SRC_ALPHA) {
                if (premultiplied)
                    _opacityModifyRGB = YES;
                else {
                    blendFuncSource = GL_SRC_ALPHA;
                    blendFuncDestination = GL_ONE_MINUS_SRC_ALPHA;
                }
            }

            self.textImage = image;
            textureID = [self setupTexture:image];
//            NSError *error;
            // Set up options for GLKTextureLoader
//            NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:
//                                      @(YES), GLKTextureLoaderOriginBottomLeft,
//                                      @(premultiplied), GLKTextureLoaderApplyPremultiplication,
//                                      nil];
//
//            //         Use GLKTextureLoader to load the tiff data into a texture
//            GLKTextureInfo *texture = [GLKTextureLoader textureWithContentsOfData:tiffData options:options error:&error];
//            textureID = texture.name;
//            NSAssert(!error, @"Unable to load texture");
            // Throw assersion error if loading texture failed
        }
    }
    
}
- (BOOL)addParticle {
    // Take the next particle out of the particle pool we have created and initialize it
    HAVParticle *particle = [[HAVParticle alloc] init];
    [self initParticle:particle];
    [self.particles addObject: particle];
    // Increment the particle count
//    particleCount++;
    // Return YES to show that a particle has been created
    return YES;
}

- (BOOL)addParticleAtTime:(GLfloat) time {
    // Take the next particle out of the particle pool we have created and initialize it
    HAVParticle *particle = [[HAVParticle alloc] init];
    [self initParticle:particle];
    ///
    particle.createTime = time;
//    particle.deadTime = 0.0f;
    particle.lastUpdateTime = time;
    [self.particles addObject: particle];
    // Increment the particle count
    
    // Return YES to show that a particle has been created
    return YES;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(self != nil){
        GLKVector2Resolution = SystemResolution;
        [self parseParticleDecoder:aDecoder];
        [self setupArrays];
        [self setupShaders];
        // Set up the projection matrix to be used for the emitter, this only needs to be set once
        // which is why it is in here.
        self.particles = [aDecoder decodeObjectForKey:@"particles"];
        for (HAVParticle * particle in self.particles){
            [self initParticle:particle];
        }
        [self stopParticleEmitter];
        [self usePrograma];
        
//        runAsynchronouslyOnVideoProcessingQueue(^{
            GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, GLKVector2Resolution.x, 0, GLKVector2Resolution.y, 1, -1);
            projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1, -1.0, 1);
            projectionMatrix = GLKMatrix4Translate(projectionMatrix, 0, -GLKVector2Resolution.y, 0);
            glUniformMatrix4fv(mvpMatrixUniform, 1, GL_FALSE, projectionMatrix.m);
//        });
    }
    return self;
}

- (void) setResolution:(CGSize) size{
    
    GLKVector2Resolution = GLKVector2Make(size.width, size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, GLKVector2Resolution.x, 0, GLKVector2Resolution.y, 1, -1);
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1, -1.0, 1);
    projectionMatrix = GLKMatrix4Translate(projectionMatrix, 0, -GLKVector2Resolution.y, 0);
    glUniformMatrix4fv(mvpMatrixUniform, 1, GL_FALSE, projectionMatrix.m);
}

- (void) encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeInt:emitterType forKey:@"emitterType"];
    [aCoder encodeFloat:sourcePosition.x forKey:@"sourcePositionx"];
    [aCoder encodeFloat:sourcePosition.y forKey:@"sourcePositiony"];

    [aCoder encodeFloat:sourcePositionVariance.x forKey:@"sourcePositionVariancex"];
    [aCoder encodeFloat:sourcePositionVariance.y forKey:@"sourcePositionVariancey"];
    
    [aCoder encodeFloat:speed forKey:@"speed"];

    [aCoder encodeFloat:speedVariance forKey:@"speedVariance"];
    
    [aCoder encodeFloat:particleLifespan forKey:@"particleLifespan"];
    
    [aCoder encodeFloat:particleLifespanVariance forKey:@"particleLifespanVariance"];
    
    [aCoder encodeFloat:angle forKey:@"angle"];
    
    [aCoder encodeFloat:angleVariance forKey:@"angleVariance"];
    
    [aCoder encodeFloat:gravity.x forKey:@"gravityx"];
    [aCoder encodeFloat:gravity.y forKey:@"gravityy"];
    
    [aCoder encodeFloat:radialAcceleration forKey:@"radialAcceleration"];
    
    [aCoder encodeFloat:radialAccelVariance forKey:@"radialAccelVariance"];
    
    [aCoder encodeFloat:tangentialAcceleration forKey:@"tangentialAcceleration"];
    
    [aCoder encodeFloat:tangentialAccelVariance forKey:@"tangentialAccelVariance"];
    
    
    [aCoder encodeFloat:startColor.r forKey:@"startColorRed"];
    [aCoder encodeFloat:startColor.g forKey:@"startColorGreen"];
    [aCoder encodeFloat:startColor.b forKey:@"startColorBlue"];
    [aCoder encodeFloat:startColor.a forKey:@"startColorAlpha"];
    
    [aCoder encodeFloat:startColorVariance.r forKey:@"startColorVarianceRed"];
    [aCoder encodeFloat:startColorVariance.g forKey:@"startColorVarianceGreen"];
    [aCoder encodeFloat:startColorVariance.b forKey:@"startColorVarianceBlue"];
    [aCoder encodeFloat:startColorVariance.a forKey:@"startColorVarianceAlpha"];

    [aCoder encodeFloat:finishColor.r forKey:@"finishColorRed"];
    [aCoder encodeFloat:finishColor.g forKey:@"finishColorGreen"];
    [aCoder encodeFloat:finishColor.b forKey:@"finishColorBlue"];
    [aCoder encodeFloat:finishColor.a forKey:@"finishColorAlpha"];
    
    [aCoder encodeFloat:finishColorVariance.r forKey:@"finishColorVarianceRed"];
    [aCoder encodeFloat:finishColorVariance.g forKey:@"finishColorVarianceGreen"];
    [aCoder encodeFloat:finishColorVariance.b forKey:@"finishColorVarianceBlue"];
    [aCoder encodeFloat:finishColorVariance.a forKey:@"finishColorVarianceAlpha"];
    
    [aCoder encodeInt:maxParticles forKey:@"maxParticles"];
    
    [aCoder encodeFloat:startParticleSize forKey:@"startParticleSize"];
    
    [aCoder encodeFloat:startParticleSizeVariance forKey:@"startParticleSizeVariance"];
    
    [aCoder encodeFloat:finishParticleSize forKey:@"finishParticleSize"];
    
    [aCoder encodeFloat:finishParticleSizeVariance forKey:@"finishParticleSizeVariance"];
    
    [aCoder encodeFloat:duration forKey:@"duration"];
    
    [aCoder encodeInt:blendFuncSource forKey:@"blendFuncSource"];
    
    [aCoder encodeInt:blendFuncDestination forKey:@"blendFuncDestination"];
    
    [aCoder encodeFloat:maxRadius forKey:@"maxRadius"];
    
    [aCoder encodeFloat:maxRadiusVariance forKey:@"maxRadiusVariance"];
    
    [aCoder encodeFloat:minRadius forKey:@"minRadius"];
    
    [aCoder encodeFloat:minRadiusVariance forKey:@"minRadiusVariance"];
    
    [aCoder encodeFloat:rotatePerSecond forKey:@"rotatePerSecond"];
    
    [aCoder encodeFloat:rotatePerSecondVariance forKey:@"rotatePerSecondVariance"];
    
    [aCoder encodeFloat:rotationStart forKey:@"rotationStart"];
    
    [aCoder encodeFloat:rotationStartVariance forKey:@"rotationStartVariance"];

    [aCoder encodeFloat:rotationEnd forKey:@"rotationEnd"];

    [aCoder encodeFloat:rotationEndVariance forKey:@"rotationEndVariance"];

    [aCoder encodeInt:yCoordFlipped forKey:@"yCoordFlipped"];
    
    [aCoder encodeBool:absolutePosition forKey:@"absolutePosition"];
    
    [aCoder encodeInt:atlasRow forKey:@"atlasRow"];
    [aCoder encodeInt:atlasCol forKey:@"atlasCol"];
    [aCoder encodeInt:frameRate forKey:@"frameRate"];
    
    [aCoder encodeInt:positionType forKey:@"positionType"];
    // Calculate the emission rate
    if(self.textImage != nil){
        NSData *imageData = UIImagePNGRepresentation(self.textImage);
        if(imageData != nil){
            [aCoder encodeObject:imageData forKey:@"textureImageData"];
        }
    }
    [aCoder encodeObject:self.particles forKey:@"particles"];
}

- (GLfloat) particleMaxLiveTime{
    return particleLifespan + particleLifespanVariance;
}

@end


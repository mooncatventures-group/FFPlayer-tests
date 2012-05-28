
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#include <FFmpegDecoder/libavformat/avformat.h>
#include <FFmpegDecoder/libswscale/swscale.h>

#import <UIKit/UIKit.h>
#define kPollingInterval 1.0/30
#define OUTPUT_FILE_NAME @"screen.mov"
#define FRAME_WIDTH 320
#define FRAME_HEIGHT 480
#define TIME_SCALE 600 


@protocol CGImageBufferDelegate <NSObject>
@required
-(void)didOutputCGImageBuffer:(NSTimer *)timer;
@end
@protocol PVPixelBufferDelegate <NSObject>
@optional
-(void)didOutputPixelBuffer:(NSTimer *)timer;
@end



@interface Frames : NSObject {
    id<CGImageBufferDelegate> cgimageDelegate;
    id<PVPixelBufferDelegate> pvpixelDelegate;
    int sourceWidth, sourceHeight;
	int outputWidth, outputHeight;
    NSTimer* iTimer;
	float lastFrameTime;
	UIImage *currentImage;
	double duration;
    BOOL frameReady;	
}

- (BOOL)decodeFrame:(NSData*)frameData;
- (BOOL)isFrameReady;
- (NSData*)getDecodedFrame;
- (NSUInteger)getDecodedFrameWidth;
- (NSUInteger)getDecodedFrameHeight;
 @property (retain) id cgimageDelegate;
 @property (retain) id pvpixelDelegate;

-(void)setupCgimageSession;

-(void)setupPVimageSession;




-(void)setOutputWidth:(int)newValue;

-(void)setOutputHeight:(int)newValue;

-(CVPixelBufferRef)cvPixelBufferRef;





/* Last decoded picture as UIImage */
@property (nonatomic, readonly) UIImage *currentImage;

/* Size of video frame */
@property (nonatomic, readonly) int sourceWidth, sourceHeight;

/* Output image size. Set to the source size by default. */
@property (nonatomic) int outputWidth, outputHeight;

/* Length of video in seconds */
@property (nonatomic, readonly) double duration;

/* Initialize with movie at moviePath. Output dimensions are set to source dimensions. */
-(id)initWithVideo:(NSString *)moviePath;

/* Read the next frame from the video stream. Returns false if no frame read (video over). */
-(BOOL)stepFrame;

-(void)setupScaler;

-(void)displayNextImageBuffer:(NSTimer *)timer;

-(void)displayNextPVBuffer:(NSTimer *)timer;


/* Seek to closest keyframe near specified time */
-(void)seekTime:(double)seconds;



@end

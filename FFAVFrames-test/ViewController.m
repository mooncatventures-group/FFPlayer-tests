/* copyright Mooncatventures group 2012
 This is a test of the latest version of FFPlayer.framework
 This code is in the public domain, do as you wish
 Code is roughly based on VTMscreenRecorder from Subsequently and Furthermore */



#import "ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#include <mach/mach_time.h>



#define OUTPUT_FILE_NAME @"screen.mov"
#define FRAME_WIDTH 320
#define FRAME_HEIGHT 480
#define TIME_SCALE 600 

@interface ViewController()
-(void) startRecording;
-(void) stopRecording;
-(UIImage*) screenshot;
@end

@implementation ViewController

@synthesize startStopButton,imageView,video;

- (void)dealloc
{
    [super dealloc];
    assetWriter = nil;
    assetWriterInput = nil;
    assetWriterPixelBufferAdaptor = nil;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}



#pragma mark helpers
-(NSString*) pathToDocumentsDirectory {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return documentsDirectory;
}

-(void) writeSample  {
    
    
	if (assetWriterInput.readyForMoreMediaData) {
		// CMSampleBufferRef sample = nil;
        NSLog(@"writing samples");
        
		CVReturn cvErr = kCVReturnSuccess;
        
		
		// prepare the pixel buffer
		CVPixelBufferRef pixelBuffer = NULL;
        
        
       
        CFDataRef imageData= CGDataProviderCopyData(CGImageGetDataProvider(imageView.image.CGImage));
		NSLog (@"copied image data");
		cvErr = CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
											 FRAME_WIDTH,
											 FRAME_HEIGHT,
											 kCVPixelFormatType_32BGRA,
											 (void*)CFDataGetBytePtr(imageData),
											 CGImageGetBytesPerRow(imageView.image.CGImage),
											 NULL,
											 NULL,
											 NULL,
											 &pixelBuffer);
		NSLog (@"CVPixelBufferCreateWithBytes returned %d", cvErr);
      
       		CFAbsoluteTime thisFrameWallClockTime = CFAbsoluteTimeGetCurrent();
		CFTimeInterval elapsedTime = thisFrameWallClockTime - firstFrameWallClockTime;
		NSLog (@"elapsedTime: %f", elapsedTime);
		CMTime presentationTime =  CMTimeMake(elapsedTime * TIME_SCALE, TIME_SCALE);
		
		// write the sample
        BOOL appended = [assetWriterPixelBufferAdaptor  appendPixelBuffer:pixelBuffer withPresentationTime:presentationTime];
        CVPixelBufferRelease(pixelBuffer);
        CFRelease(imageData);
		if (appended) {
			NSLog (@"appended sample at time %lf", CMTimeGetSeconds(presentationTime));
		} else {
			NSLog (@"failed to append");
			[self stopRecording];
			self.startStopButton.selected = NO;
		}
	}
}

-(void) startRecording {
	
    //	// create the AVComposition
    //	[mutableComposition release];
    //	mutableComposition = [[AVMutableComposition alloc] init];
    
    
    movieURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%llu.mov", NSTemporaryDirectory(), mach_absolute_time()]];
    
	
	NSError *movieError = nil;
	assetWriter = [[AVAssetWriter alloc] initWithURL:movieURL 
                                            fileType: AVFileTypeQuickTimeMovie 
                                               error: &movieError];
	NSDictionary *assetWriterInputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
											  AVVideoCodecH264, AVVideoCodecKey,
											  [NSNumber numberWithInt:FRAME_WIDTH], AVVideoWidthKey,
											  [NSNumber numberWithInt:FRAME_HEIGHT], AVVideoHeightKey,
											  nil];
	assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType: AVMediaTypeVideo
														  outputSettings:assetWriterInputSettings];
	assetWriterInput.expectsMediaDataInRealTime = YES;
	[assetWriter addInput:assetWriterInput];
	
	assetWriterPixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor  alloc]
									 initWithAssetWriterInput:assetWriterInput
									 sourcePixelBufferAttributes:nil];
	[assetWriter startWriting];
	
	firstFrameWallClockTime = CFAbsoluteTimeGetCurrent();
	[assetWriter startSessionAtSourceTime:kCMTimeZero];
	startSampleing=YES;
    
}

-(void) stopRecording {
	
	
	[assetWriter finishWriting];
	NSLog (@"finished writing");
    [self saveMovieToCameraRoll];
    startSampleing=NO;
}

- (void)saveMovieToCameraRoll
{
    // save the movie to the camera roll
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	NSLog(@"writing \"%@\" to photos album", movieURL);
	[library writeVideoAtPathToSavedPhotosAlbum:movieURL
								completionBlock:^(NSURL *assetURL, NSError *error) {
									if (error) {
										NSLog(@"assets library failed (%@)", error);
									}
									else {
										[[NSFileManager defaultManager] removeItemAtURL:movieURL error:&error];
										if (error)
											NSLog(@"Couldn't remove temporary movie file \"%@\"", movieURL);
									}
									movieURL = nil;
								}];
}


#pragma mark - View lifecycle

/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.video = [[Frames alloc] initWithVideo:@"rtsp://184.72.239.149/vod/mp4://BigBuckBunny_175k.mov"];
    self.video.cgimageDelegate = self;
    // set output image size
	video.outputWidth = 320;
	video.outputHeight = 480;
    startSampleing = NO;
    [video setupCgimageSession];
  	// print some info about the video
	NSLog(@"video duration: %f",video.duration);
	NSLog(@"video size: %d x %d", video.sourceWidth, video.sourceHeight);
    //  [imageView setTransform:CGAffineTransformMakeRotation(M_PI/2)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)didOutputCGImageBuffer:(NSTimer *)timer {
    [video stepFrame];
  	imageView.image = video.currentImage;
    if (startSampleing) 
        [self writeSample];
    
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark event handlers
-(IBAction) handleStartStopTapped: (id) sender {
	if (self.startStopButton.selected) {
		[self stopRecording];
		self.startStopButton.selected = NO;
	} else {
		[self startRecording];
		self.startStopButton.selected = YES;
	}
}

@end

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <AVCaptureAudioDataOutputSampleBufferDelegate>
{
    AVCaptureSession*   _session;
    
    IBOutlet        UIImageView*    _imageView_1;
    IBOutlet        UIImageView*    _imageView_2;
}

@property (weak, nonatomic) IBOutlet UILabel *label_1;
@property (weak, nonatomic) IBOutlet UILabel *label_2;

@end

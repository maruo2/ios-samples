#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

static int shakeCount = 0;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.label_1.transform = CGAffineTransformMakeRotation(90.0f * M_PI / 180.0f);
    self.label_2.transform = CGAffineTransformMakeRotation(90.0f * M_PI / 180.0f);

    [self setLabel];
    
    // ビデオキャプチャデバイスの取得
    AVCaptureDevice*    device;
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // デバイス入力の取得
    AVCaptureDeviceInput*   deviceInput;
    deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:NULL];
    
    // ビデオデータ出力の作成
    NSMutableDictionary*        settings;
    AVCaptureVideoDataOutput*   dataOutput;
    settings = [NSMutableDictionary dictionary];
    [settings setObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                 forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    dataOutput.videoSettings = settings;
    [dataOutput setSampleBufferDelegate:(id)self queue:dispatch_get_main_queue()];
    
    // セッションの作成
    _session = [[AVCaptureSession alloc] init];
    [_session addInput:deviceInput];
    [_session addOutput:dataOutput];
    _session.sessionPreset = AVCaptureSessionPresetMedium;
    
    // セッションの開始
    [_session startRunning];
    
}

-(void)viewDidLayoutSubviews
{
    self.label_1.frame = CGRectMake(290, 20, self.label_1.frame.size.height, _imageView_1.frame.size.height);
    self.label_2.frame = CGRectMake(290, _imageView_1.frame.size.height + 20, self.label_2.frame.size.height, _imageView_2.frame.size.height);
    

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    NSLog(@"come-shake!!!!");
    shakeCount++;

    [self setLabel];
}
- (void)setLabel
{
    NSString* str = @"";
    switch (shakeCount % 5) {
        case 0:
            str = @"x1.0 Normal (shake it !)";
            break;
        case 1:
            str = @"x1.2 Normal (shake it !)";
            break;
        case 2:
            str = @"x1.5 Normal (shake it !)";
            break;
        case 3:
            str = @"x1.5 Monochrome (shake it !)";
            break;
        case 4:
            str = @"x1.5 SepiaTone (shake it !)";
            break;
            
        default:
            break;
    }
    self.label_1.text = str;
    self.label_2.text = str;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // イメージバッファの取得
    CVImageBufferRef    buffer;
    buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // イメージバッファのロック
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    // イメージバッファ情報の取得
    uint8_t*    base;
    size_t      width, height, bytesPerRow;
    base = CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    // ビットマップコンテキストの作成
    CGColorSpaceRef colorSpace;
    CGContextRef    cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(
                                      base, width, height, 8, bytesPerRow, colorSpace,
                                      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    // 画像の作成
    CGImageRef  cgImage;
    UIImage*    image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage scale:1.0f
                          orientation:UIImageOrientationRight];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    
    // イメージバッファのアンロック
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    
    // 画像の切り抜き（等比対応）
    // ***********
    // 切り抜き元となる画像を用意する。
    UIImage *srcImage = image;
    int imageW = srcImage.size.width;
    int imageH = srcImage.size.height;
    
    // 切り抜く位置を指定するCGRectを作成する。
    int baseWidth = 284;
    int baseHeight = 320;
    CGFloat scale = 1.0;
    switch (shakeCount % 5) {
        case 0:
            scale = 1.0;
            break;
        case 1:
            scale = 0.75;
            break;
        case 2:
            scale = 0.5;
            break;
        case 3:
            scale = 0.5;
            break;
        case 4:
            scale = 0.5;
            break;
            
        default:
            break;
    }

    int scaleWidth = baseWidth * scale;
    int scaleHeight = baseHeight * scale;
    int posX = (imageW - scaleWidth) / 2;
    int posY = (imageH - scaleHeight) / 2;
    CGRect trimArea = CGRectMake(posX, posY, scaleWidth, scaleHeight);
    
    // 切り抜いた画像を作成する。
    CGImageRef srcImageRef = [srcImage CGImage];
    CGImageRef trimmedImageRef = CGImageCreateWithImageInRect(srcImageRef, trimArea);
    UIImage *trimmedImage = [UIImage imageWithCGImage:trimmedImageRef scale:1.0F orientation:UIImageOrientationRight];
    CGImageRelease(trimmedImageRef);

    // 画像の加工
    CIImage* filteredImage = [[CIImage alloc] initWithCGImage:trimmedImage.CGImage];
    CIFilter* filter = nil;
    if ((shakeCount % 5) == 3)
    {
        filter = [CIFilter filterWithName:@"CIMinimumComponent"];   // モノクロ
    }
    else if ((shakeCount % 5) == 4)
    {
        filter = [CIFilter filterWithName:@"CISepiaTone"];    // セピア
    }
    [filter setValue:filteredImage forKey:@"inputImage"];
    filteredImage = filter.outputImage;
    
    CIContext* ci = [CIContext contextWithOptions:nil];
    CGImageRef imageRef = [ci createCGImage:filteredImage fromRect:[filteredImage extent]];
    UIImage* outputImage = [UIImage imageWithCGImage:imageRef scale:1.0F orientation:UIImageOrientationRight];
    CGImageRelease(imageRef);
    
    // 画像の表示
    if ((shakeCount % 5) == 0 || (shakeCount % 5) == 1 || (shakeCount % 5) == 2)
    {
        _imageView_1.image = trimmedImage;
        _imageView_2.image = trimmedImage;
    }
    else
    {
        _imageView_1.image = outputImage;
        _imageView_2.image = outputImage;
    }
}

@end

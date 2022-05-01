#import <Cephei/HBPreferences.h>
#import <UIKit/UIKit.h>
#import <MediaRemote/MediaRemote.h>
#import "HBLog.h"

@interface AVSystemController : NSObject {}
+ (id)sharedAVSystemController ;
- (BOOL)changeActiveCategoryVolumeBy:(float)arg1 ;
- (BOOL)getActiveCategoryVolume:(float*)arg1 andName:(id*)arg2 ;
- (BOOL)setActiveCategoryVolumeTo:(float)arg1 ;
@end

@interface SpringBoard : UIApplication
- (id)startTimer;
- (id)dismissAlert;
- (id)tappedOutsideOfAlert:(UITapGestureRecognizer *)recognizer;
- (id)stopPlayback;
- (void)_simulateLockButtonPress;
@end

@interface BluetoothManager
+ (id)sharedInstance;
- (BOOL)enabled;
- (void)setEnabled:(BOOL)enabled;
- (void)setPowered:(BOOL)powered;
@end


// Preferences
BOOL enabled;
BOOL turnOffScreen;
BOOL turnOffBluetooth;
NSInteger interval;
NSInteger activeAfter;
HBPreferences* preferences;

// Other
static UIAlertController* sleepSecondsRemainingAlertController;
static NSTimer* _timer;
static NSTimer *changeTextTimer;
static int secondsLeft = 10;
static float volumeBeforeLowering;


void alert(NSString* title, NSString* message) {
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title message: message preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction* dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
	[alertController addAction:dismissAction];
	[[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alertController animated:YES completion:nil];	
}

static void disableBluetooth() {
	[[%c(BluetoothManager) sharedInstance] setEnabled:NO];
	[[%c(BluetoothManager) sharedInstance] setPowered:NO]; // I don't know what this does. 
	// They seem to do the exact same thing. 
	// Discussed it on Theos discord server - no one knows.
}

%hook SpringBoard
	%new	
	-(void)startTimer {
		if (_timer) {
			[_timer invalidate];
			_timer = nil;
		}
		_timer = [NSTimer scheduledTimerWithTimeInterval: interval * 60 target:self selector:@selector(timerRan:) userInfo:nil repeats:NO];
	}

	-(void)applicationDidFinishLaunching:(id)application {
		%orig;
		[preferences registerPreferenceChangeBlock:^{
			HBLogDebug(@"test");
			if (_timer) {
				[_timer invalidate];
				_timer = nil;
			}
			if (enabled) {
				[self startTimer];
			}
		}];
	}

	%new
	-(void)timerRan:(NSTimer*) timer {
		HBLogDebug(@"%@ timerRan", timer);
		NSDateComponents* components = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:[NSDate date]]; 

		NSInteger hour= [components hour];
		NSInteger minute = [components minute];
		NSInteger totalMinutes = hour * 60 + minute;

		if (activeAfter <= totalMinutes && totalMinutes <= activeAfter + 240 /* people's min sleep time is 4 hours, right ...? */) {
			NSArray* titles = [NSArray 
				arrayWithObjects: @"Still Watching?", @"You still there?", @"Fall asleep already...", @"Go to bed", @"Hey, you. You\'re finally asleep. You were trying to watch vids all night, right?", 
				nil
			];
			MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_get_main_queue(), ^(Boolean isPlaying) {
				if (isPlaying) {
					secondsLeft = 10;
					NSString* categoryName; // I don't use it
					[[%c(AVSystemController) sharedAVSystemController] getActiveCategoryVolume:&volumeBeforeLowering andName:&categoryName];

					sleepSecondsRemainingAlertController = [UIAlertController 
						alertControllerWithTitle:titles[arc4random_uniform(titles.count)] 
						message: @"The playback will stop in 10 seconds. You can also tap outside of this message to close it." 
						preferredStyle: UIAlertControllerStyleAlert
					];

					changeTextTimer = [NSTimer scheduledTimerWithTimeInterval:1
						target: self
						selector:@selector(sleepSecondsRemainingTimerRan:)
						userInfo:nil
						repeats:YES
					];

					UIAlertAction* dismissAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action){
						[changeTextTimer invalidate];
						[[%c(AVSystemController) sharedAVSystemController] setActiveCategoryVolumeTo: volumeBeforeLowering];
					}];
					[sleepSecondsRemainingAlertController addAction:dismissAction];
					[[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:sleepSecondsRemainingAlertController animated:YES completion: ^{
						// Create a "tap anywhere to dismiss" feature
						UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutsideOfAlert:)];
						[[[[sleepSecondsRemainingAlertController view] superview] subviews][0] addGestureRecognizer: tapGestureRecognizer ];
					}];	
				}
			});
		}
		[self startTimer];
	}

	%new
	-(void)tappedOutsideOfAlert:(UITapGestureRecognizer *)recognizer { [self dismissAlert]; }

	%new
	-(void)dismissAlert {
		[changeTextTimer invalidate];
		[[[[UIApplication sharedApplication] keyWindow] rootViewController] dismissViewControllerAnimated:YES completion: ^{
			[[%c(AVSystemController) sharedAVSystemController] setActiveCategoryVolumeTo: volumeBeforeLowering];
		}];
	}
	
	%new
	-(void)stopPlayback {
		MRMediaRemoteSendCommand(MRMediaRemoteCommandPause, nil);
		[self dismissAlert ];
		if (turnOffScreen) {
			[(SpringBoard *)[%c(SpringBoard) sharedApplication] _simulateLockButtonPress];
		}
		if (turnOffBluetooth) {
			disableBluetooth();
		}
	}

	%new
	-(void)sleepSecondsRemainingTimerRan:(NSTimer*) timer {
		HBLogDebug(@"%i sleepSecondsRemainingTimerRan", secondsLeft);
		secondsLeft -= 1;
		[[%c(AVSystemController) sharedAVSystemController] changeActiveCategoryVolumeBy: volumeBeforeLowering / -10];
		if (secondsLeft <= 0) {
			[self stopPlayback];
			return;
		}
		NSString* messagetmp = @"The playback will stop in ";
		[sleepSecondsRemainingAlertController setMessage:[messagetmp stringByAppendingString:[NSString stringWithFormat:@"%i seconds. You can also tap outside of this message to close it.", secondsLeft]]];
	}

%end

%ctor {
	preferences = [[HBPreferences alloc] initWithIdentifier:@"ovh.exerhythm.stillwatchingPreferences"];
	[preferences registerBool: &enabled default:YES forKey:@"enabled"];
	[preferences registerBool: &turnOffScreen default:YES forKey:@"turnOffScreen"];
	[preferences registerBool: &turnOffBluetooth default:YES forKey:@"turnOffBluetooth"];
	[preferences registerInteger: &interval default:30 forKey:@"interval"];
	[preferences registerInteger: &activeAfter default:0 forKey:@"activeAfter"];
}
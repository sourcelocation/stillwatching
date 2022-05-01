#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SWPRootListController.h"
#import <CepheiPrefs/HBRootListController.h>
#import <Cephei/HBRespringController.h>

@implementation SWPRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

@end

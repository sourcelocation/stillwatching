#import "XXXTimeIntervalPickerCell.h"

@implementation XXXTimeIntervalPickerCell {
  UIAlertController *_alert;
  UIPickerView *_timePicker;
  NSInteger _hours;
  NSInteger _minutes;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)identifier
                    specifier:(PSSpecifier *)specifier {
  self = [super initWithStyle:style
              reuseIdentifier:identifier
                    specifier:specifier];

  // Convert seconds to hours, minutes, seconds and set time labal
  if (self) {
    NSInteger totalSeconds = [[specifier performGetter] integerValue];
    _minutes = totalSeconds % 60;
    _hours = totalSeconds / 60;

    self.detailTextLabel.text = [NSString
        stringWithFormat:@"%02ld:%02ld", (long)_hours, (long)_minutes];
  }

  return self;
}

- (void)presentAlert {
  if (!_alert) {
    _alert = [UIAlertController
        alertControllerWithTitle:@"Active after"
                         message:@""
                  preferredStyle:UIAlertControllerStyleActionSheet];
    [_alert addAction:[UIAlertAction actionWithTitle:@"Done"
                                               style:UIAlertActionStyleCancel
                                             handler:nil]];

    _timePicker = [[UIPickerView alloc] init];
    _timePicker.dataSource = self;
    _timePicker.delegate = self;
    _timePicker.showsSelectionIndicator = YES;
    _timePicker.translatesAutoresizingMaskIntoConstraints = NO;

    [_timePicker selectRow:_hours inComponent:0 animated:YES];
    [_timePicker selectRow:_minutes inComponent:1 animated:YES];

    _alert.view.clipsToBounds = YES;
    [_alert.view addSubview:_timePicker];

    [NSLayoutConstraint activateConstraints:@[
      [_alert.view.widthAnchor constraintEqualToAnchor:_timePicker.widthAnchor],
      [_alert.view.heightAnchor constraintEqualToAnchor:_timePicker.heightAnchor
                                               constant:100],

      [_timePicker.centerXAnchor
          constraintEqualToAnchor:_alert.view.centerXAnchor],
      [_timePicker.centerYAnchor
          constraintEqualToAnchor:_alert.view.centerYAnchor
                         constant:-25],
    ]];
  }

  // Alderis
  // https://github.com/hbang/Alderis/blob/138dfd16028caf6bebb0e9c611ea44934696d878/lcpshim/HBColorPickerTableCell.m#L86-L87
  UIViewController *rootViewController =
      self._viewControllerForAncestor
          ?: [UIApplication sharedApplication].keyWindow.rootViewController;
  [rootViewController presentViewController:_alert animated:YES completion:nil];
}

#pragma mark - UIPickerViewDelegate Methods

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
  switch (component) {
  case 0:
    _hours = row;
    break;

  case 1:
    _minutes = row;
    break;
  }

  // Update time label, save value
  self.detailTextLabel.text =
      [NSString stringWithFormat:@"%02ld:%02ld", (long)_hours, (long)_minutes];
  [self.specifier
      performSetterWithValue:[NSNumber numberWithInt:(_hours * 60) + _minutes]];
}

// Add hour, min, or sec string to numbers
- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view {
  if (!view) {
    UILabel *columnLabel = [[UILabel alloc] init];
    columnLabel.text = [NSString
        stringWithFormat:@"%lu", (long)row];
    columnLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightRegular];
    columnLabel.textAlignment = NSTextAlignmentCenter;
    return columnLabel;
  }

  ((UILabel *)view).text = [NSString stringWithFormat:@"%lu", (long)row];
  return view;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
    numberOfRowsInComponent:(NSInteger)component {
  return (component == 0) ? 24 : 60;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView
    rowHeightForComponent:(NSInteger)component {
  return 30;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
  [super setSelected:selected animated:animated];

  if (selected) {
    [self presentAlert];
  }
}

// Set label tint color
- (void)tintColorDidChange {
  [super tintColorDidChange];

  self.textLabel.textColor = self.tintColor;
  self.textLabel.highlightedTextColor = self.tintColor;
}

- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
  [super refreshCellContentsWithSpecifier:specifier];

  if ([self respondsToSelector:@selector(tintColor)]) {
    self.textLabel.textColor = self.tintColor;
    self.textLabel.highlightedTextColor = self.tintColor;
  }
}
@end

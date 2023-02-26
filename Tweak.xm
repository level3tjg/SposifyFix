#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <substrate.h>

@protocol SPTPlayer
@required
- (void)seekTo:(CGFloat)arg1;
@end

@interface SPTNowPlayingModel
@property id<SPTPlayer> player;
@end

@interface UIColor ()
+ (instancetype)colorWithHexString:(NSString *)hexString;
@end

@interface SettingsUsecase : NSObject
@property NSUserDefaults *userDefaults;
@property BOOL CanvasChoiceButtonEnabled;
@property BOOL TrueShuffleEnabled;
@property BOOL RealtimeLyricsPopupEnabled;
@property BOOL FloatingBarEnabled;
@property BOOL FloatingBarColorExtractionEnabled;
@property BOOL FloatingBarSmallCoverArtEnabled;
+ (instancetype)sharedUsecase;
@end

@interface LyricsLine {
  CGFloat startTime;
}
@end

@interface LyricsLineSet {
  NSArray<LyricsLine *> *lyricsLines;
  NSInteger syncType;
}
@end

@interface ColorLyricsModel {
  LyricsLineSet *lyricsLineSet;
}
@end

@interface SettingsViewController
    : UIViewController <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate>
@end

SPTNowPlayingModel *nowPlayingModel;

%hook SPTFreeTierPlaylistFeatureProperties
- (BOOL)enableWeightedShufflePlayback {
  return [[%c(SettingsUsecase) sharedUsecase] TrueShuffleEnabled] ? NO
                                                                             : %orig;
}
%end

%hook SingalongTestManagerImplementation
- (BOOL)isFeatureEnabled {
  return [[%c(SettingsUsecase) sharedUsecase] RealtimeLyricsPopupEnabled]
             ? YES
             : %orig;
}
%end

%hook SPTNowPlayingTestManagerImplementation
- (BOOL)isFloatingNowPlayingBarEnabled {
  return [[%c(SettingsUsecase) sharedUsecase] FloatingBarEnabled] || %orig;
}
- (BOOL)isFloatingNowPlayingColorExtractionEnabled {
  return [[%c(SettingsUsecase) sharedUsecase] FloatingBarColorExtractionEnabled] ||
         %orig;
}
- (BOOL)isFloatingNowPlayingBarSmallCoverArtEnabled {
  return [[%c(SettingsUsecase) sharedUsecase] FloatingBarSmallCoverArtEnabled] ||
         %orig;
}
- (BOOL)isContentLayerTabEnabled {
  return [[%c(SettingsUsecase) sharedUsecase] CanvasChoiceButtonEnabled] ||
         %orig;
}
%end

%hook SettingsViewController
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return %orig;
}
- (NSInteger)tableView:(UITableView *)tableVIew numberOfRowsInSection:(NSInteger)section {
  if (section == 2) return %orig + 2;
  return %orig;
}
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSInteger section = indexPath.section;
  NSInteger row = indexPath.row;
  UITableViewCell *cell;
  if (indexPath.section == 2) {
    if (row == 3) {
      cell = %orig;
      cell.textLabel.text = @"Canvas Tab";
    }

    if (row >= 4) row++;

    NSInteger numberOfRows = [(SettingsViewController *)self tableView:tableView
                                                 numberOfRowsInSection:indexPath.section];

    if (row >= numberOfRows - 2) {
      cell = [[UITableViewCell alloc] initWithStyle:0 reuseIdentifier:@"SubCell"];
      UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
      cell.accessoryView = toggle;
      cell.textLabel.font = [UIFont fontWithName:@"CircularSpUI-Book" size:16.0];
      cell.textLabel.textColor = [UIColor colorWithHexString:@"#ffffff"];
      cell.backgroundColor = [UIColor colorWithHexString:@"#121212"];
      SEL targetSelector = NULL;
      if (row == numberOfRows - 2) {
        cell.textLabel.text = @"Floating Bar";
        toggle.on = [[%c(SettingsUsecase) sharedUsecase] FloatingBarEnabled];
        targetSelector = @selector(FloatingBarSwitchChanged:);
      } else if (row == numberOfRows - 1) {
        cell.textLabel.text = @"Floating Bar Color Extraction";
        toggle.on =
            [[%c(SettingsUsecase) sharedUsecase] FloatingBarColorExtractionEnabled];
        targetSelector = @selector(FloatingBarColorExtractionSwitchChanged:);
      } else if (row == numberOfRows) {
        cell.textLabel.text = @"Floating Bar Small Cover Art";
        toggle.on =
            [[%c(SettingsUsecase) sharedUsecase] FloatingBarSmallCoverArtEnabled];
        targetSelector = @selector(FloatingBarSmallCoverArtSwitchChanged:);
      }
      [toggle addTarget:self action:targetSelector forControlEvents:UIControlEventValueChanged];
    }
  }
  if (!cell)
    cell = %orig(tableView, [NSIndexPath indexPathForRow:row inSection:section]);
  if (![cell.textLabel.font.fontName isEqualToString:@"CircularSpUI-Book"])
    cell.textLabel.font = [UIFont fontWithName:@"CircularSp-Book" size:16.0];
  return cell;
}
- (void)tableView:(UITableView *)tableView
    willDisplayHeaderView:(UITableViewHeaderFooterView *)headerView
               forSection:(NSInteger)section {
  %orig;
  if (![headerView.textLabel.font.fontName isEqualToString:@"CircularSpUIm40-Bold"])
    headerView.textLabel.font = [UIFont fontWithName:@"CircularSp-Bold" size:24.0];
}
%new
- (void)FloatingBarSwitchChanged:(UISwitch *)sender {
  [[%c(SettingsUsecase) sharedUsecase] setFloatingBarEnabled:sender.on];
}
%new
- (void)FloatingBarColorExtractionSwitchChanged:(UISwitch *)sender {
  [[%c(SettingsUsecase) sharedUsecase] setFloatingBarColorExtractionEnabled:sender.on];
}
%new
- (void)FloatingBarSmallCoverArtSwitchChanged:(UISwitch *)sender {
  [[%c(SettingsUsecase) sharedUsecase] setFloatingBarSmallCoverArtEnabled:sender.on];
}
%end

%hook SettingsUsecase
%new
- (BOOL)FloatingBarEnabled {
  return [self.userDefaults boolForKey:@"FloatingBar_Enabled"];
}
%new
- (void)setFloatingBarEnabled:(BOOL)enabled {
  [self.userDefaults setBool:enabled forKey:@"FloatingBar_Enabled"];
}
%new
- (BOOL)FloatingBarColorExtractionEnabled {
  return [self.userDefaults boolForKey:@"FloatingBarColorExtraction_Enabled"];
}
%new
- (void)setFloatingBarColorExtractionEnabled:(BOOL)enabled {
  [self.userDefaults setBool:enabled forKey:@"FloatingBarColorExtraction_Enabled"];
}
%new
- (BOOL)FloatingBarSmallCoverArtEnabled {
  return [self.userDefaults boolForKey:@"FloatingBarSmallCoverArt_Enabled"];
}
%new
- (void)setFloatingBarSmallCoverArtEnabled:(BOOL)enabled {
  [self.userDefaults setBool:enabled forKey:@"FloatingBarSmallCoverArt_Enabled"];
}
%end

%hook SPTNowPlayingModel
+ (id)alloc {
  nowPlayingModel = %orig;
  return nowPlayingModel;
}
%end

%hook UITableView
- (BOOL)allowsSelection {
  if ([self.dataSource
          isMemberOfClass:NSClassFromString(@"SingalongFeatureImpl.TableViewDataSource")]) {
    ColorLyricsModel *lyricsModel =
        MSHookIvar<ColorLyricsModel *>(self.dataSource, "colorLyricsModel");
    LyricsLineSet *lineSet = MSHookIvar<LyricsLineSet *>(lyricsModel, "lyricsLineSet");
    if (MSHookIvar<NSInteger>(lineSet, "syncType") == 0) return YES;
  }
  return %orig;
}
%end

%hook TableViewDataSource
- (id)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (!MSHookIvar<BOOL>(self, "isShareModeEnabled")) {
    ColorLyricsModel *lyricsModel = MSHookIvar<ColorLyricsModel *>(self, "colorLyricsModel");
    LyricsLineSet *lineSet = MSHookIvar<LyricsLineSet *>(lyricsModel, "lyricsLineSet");
    LyricsLine *line = MSHookIvar<NSArray *>(lineSet, "lyricsLines")[indexPath.row];
    [nowPlayingModel.player seekTo:MSHookIvar<CGFloat>(line, "startTime") / 1000];
  }
  return %orig;
}
%end

void add_image(const struct mach_header *mh, intptr_t vmaddr_slide) {
  Dl_info dlinfo;
  if (dladdr(mh, &dlinfo) && strstr(dlinfo.dli_fname, "Sposify.dylib")) {
    // clang-format off
    %init(_ungrouped,
        // clang-format on
        SingalongTestManagerImplementation =
            NSClassFromString(@"SingalongFeatureImpl.TestManagerImplementation"),
        TableViewDataSource = NSClassFromString(@"SingalongFeatureImpl.TableViewDataSource"),
        SettingsViewController = (__bridge Class)dlsym(dlopen(dlinfo.dli_fname, RTLD_LAZY),
                                                       "OBJC_CLASS_$_SettingsViewController"));
  }
}

%ctor {
  _dyld_register_func_for_add_image(add_image);
}

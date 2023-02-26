#include "UIImage+Icon.h"

@implementation UIImage (Icon)
+ (instancetype)imageForSPTIcon:(enum SPTIcon)icon size:(CGSize)size {
  return [self encore_imageForIcon:icon size:size];
}
+ (instancetype)imageForSPTIcon:(enum SPTIcon)icon
                           size:(CGSize)size
                          color:(UIColor *)iconColor {
  return [self encore_imageForIcon:icon size:size color:iconColor];
}
@end
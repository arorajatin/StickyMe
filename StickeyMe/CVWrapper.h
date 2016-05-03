//
//  CVWrapper.h
//  StickeyMe
//
//  Created by Jatin Arora on 02/03/16.
//  Copyright © 2016 Jatin Arora. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface CVWrapper : NSObject

+ (UIImage *)processImageWithImage:(UIImage *)image;

+ (UIImage*) detectedSquaresInImage:(UIImage*) image
                          tolerance:(CGFloat)  tolerance
                          threshold:(NSInteger)threshold
                             levels:(NSInteger)levels
                           accuracy:(NSInteger)accuracy;

+ (NSArray<UIImage *> *) detectedMultipleStickeyImages:(UIImage*) image
                                             tolerance:(CGFloat)  tolerance
                                             threshold:(NSInteger)threshold
                                                levels:(NSInteger)levels
                                              accuracy:(NSInteger)accuracy;

@end

//
//  CVWrapper.m
//  StickeyMe
//
//  Created by Jatin Arora on 02/03/16.
//  Copyright © 2016 Jatin Arora. All rights reserved.
//

#import "CVSquares.hpp"
#import "CVWrapper.h"
#import <opencv2/opencv.hpp>
#import "UIImage+OpenCV.h"

@implementation CVWrapper

+ (UIImage *)processImageWithImage:(UIImage *)image {
    
    
    return nil;
    
}

+ (UIImage*) detectedSquaresInImage:(UIImage*) image
                          tolerance:(CGFloat)  tolerance
                          threshold:(NSInteger)threshold
                             levels:(NSInteger)levels
                           accuracy:(NSInteger)accuracy
{
    UIImage* result = nil;
    
    //convert from UIImage to cv::Mat openCV image format
    //this is a category on UIImage
    cv::Mat matImage = [image CVMat];
    
    
    //call the c++ class static member function
    //we want this function signature to exactly
    //mirror the form of the calling method
    matImage = CVSquares::detectedSquaresInImage (matImage, tolerance, (float)threshold, (int)levels, (int)accuracy);
    
    
    //convert back from cv::Mat openCV image format
    //to UIImage image format (category on UIImage)
    result = [UIImage imageFromCVMat:matImage];
    
    return result;
}

+ (NSArray<UIImage *> *) detectedMultipleStickeyImages:(UIImage*) image
                                           tolerance:(CGFloat)  tolerance
                                           threshold:(NSInteger)threshold
                                              levels:(NSInteger)levels
                                            accuracy:(NSInteger)accuracy
{
    NSMutableArray<UIImage *> *result = [[NSMutableArray alloc] init];
    
    //convert from UIImage to cv::Mat openCV image format
    //this is a category on UIImage
    cv::Mat matImage = [image CVMat];
    
    
    //call the c++ class static member function
    //we want this function signature to exactly
    //mirror the form of the calling method
    
    std::vector<cv::Mat> allStickies = CVSquares::detectedMultipleSquaresInImage(matImage, (float)tolerance, (int)threshold, (int)levels, (int)accuracy);
    
    for (int i=0; i<allStickies.size(); i++) {
        
        //convert back from cv::Mat openCV image format
        //to UIImage image format (category on UIImage)
                
        UIImage *image  = [UIImage imageFromCVMat:allStickies[i]];
        
        if (image) {
            [result addObject:image];
        }
        
    }

    return result;
}


@end

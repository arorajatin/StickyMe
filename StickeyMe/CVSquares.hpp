//
//  CVSquares.hpp
//  StickeyMe
//
//  Created by Jatin Arora on 02/03/16.
//  Copyright © 2016 Jatin Arora. All rights reserved.
//

#ifndef CVSquares_hpp
#define CVSquares_hpp

#include <stdio.h>

class CVSquares
{
    
public:
    
    //static is used for making these methods class methods rather than instance methods
    
    static std::vector<cv::Mat> detectedMultipleSquaresInImage (cv::Mat image, float tol, int threshold, int levels, int acc);
    
    static cv::Mat detectedSquaresInImage (cv::Mat image, float tol, int threshold, int levels, int accuracy);
    
};

#endif /* CVSquares_hpp */

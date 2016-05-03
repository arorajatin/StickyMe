//
//  CVSquares.cpp
//  OpenCVClient
//
//  Original code from sample distributed with openCV source.
//  Modifications (c) new foundry Limited. All rights reserved.
//
//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#include "CVSquares.hpp"
#include <iostream>
#include <set>

using namespace std;
using namespace cv;

static int thresh = 50, N = 11;
static float tolerance = 0.01;
static int accuracy = 0;
static int duplicateTolerance = 35;

//adding declarations at top of file to allow public function (was main{}) at top
static void findSquares(  const Mat& image,   vector<vector<Point> >& squares );
static void drawSquares( Mat& image, vector<vector<Point> >& squares );
std::vector<cv::Point> sortSquarePointsClockwise( std::vector<cv::Point> square );
static void removeDuplicateSquares(vector<vector<Point>>&squares);

static void manageSquares(  const Mat& image, vector<cv::Mat> &finalImages, vector<vector<Point> >& squares );


//Sorting

struct sortX
{
    inline bool operator() (const Point& point1, const Point& point2)
    {
        if (point1.x == point2.x) {
            
            return point1.y < point2.y;
            
        }
        
        return point1.x < point2.x;
    }
};

struct sortY
{
    inline bool operator() (const Point& point1, const Point& point2)
    {
        if (point1.y == point2.y) {
            
            return point1.x < point2.x;
            
        }
        
        return point1.y < point2.y;
    }
};


//this public function performs the role of
//main{} in the original file
cv::Mat CVSquares::detectedSquaresInImage (cv::Mat image, float tol, int threshold, int levels, int acc)
{
    vector<vector<Point> > squares;
    
    if( image.empty() )
    {
        cout << "CVSquares.m: Couldn't load " << endl;
    }
    
    tolerance = tol;
    thresh = threshold;
    N = levels;
    accuracy = acc;
    findSquares(image, squares);
    drawSquares(image, squares);
    
    
    
    return image;
}

vector<cv::Mat> CVSquares::detectedMultipleSquaresInImage (cv::Mat image, float tol, int threshold, int levels, int acc)
{
    vector<vector<Point> > squares;
    
    vector<cv::Mat> finalImages;
    
    if( image.empty() )
    {
        cout << "CVSquares.m: Couldn't load " << endl;
    }
    
    tolerance = tol;
    thresh = threshold;
    N = levels;
    accuracy = acc;
    findSquares(image, squares);
    removeDuplicateSquares(squares);
    manageSquares(image, finalImages, squares);
    
    return finalImages;
}

static void removeDuplicateSquares(vector<vector<Point>>&squares) {
    
    set<int> duplicateIndexes;
    vector<vector<Point>> filteredSquares;
    
    for (int i=0; i<squares.size() ; i++) {
        /**
         Step 1:
         Sort accroding to x
         **/
        
        
        std::sort(squares[i].begin(), squares[i].end(), sortX());
        
        /**
         Step 2:
         Get the extreme corners x and make them consistent i.e. x1 = x0 & x2 = x3
         **/
        
        squares[i][1].x = squares[i][0].x;
        squares[i][2].x = squares[i][3].x;
    }
    
    for (int i=0; i<squares.size() ; i++) {
     
        //This is duplicate square, kindly ignore and move on to the next square
        
        if (duplicateIndexes.find(i) != duplicateIndexes.end()) {
            continue;
        } else {
            filteredSquares.insert(filteredSquares.end(), squares[i]);
        }
        
        //Calculate the bottomLeft & its extrapolated point & check if any of the squares fall under its ambit
        
        Point bottomLeftPoint = squares[i][0].y > squares[i][1].y ? squares[i][1] : squares[i][0];
//        Point bottomLeftPointExtrapolated = Point(bottomLeftPoint.x + bottomLeftPoint.x/2, bottomLeftPoint.y + bottomLeftPoint.y/2);
        
        for (int j=i+1; j<squares.size(); j++) {
            
            if (duplicateIndexes.find(j) != duplicateIndexes.end()) {
                continue;
            }
            
            Point otherBottomLeftPoint = squares[j][0].y > squares[j][1].y ? squares[j][1] : squares[j][0];
//            Point topRightPoint = squares[j][2].y > squares[j][3].y ? squares[j][2] : squares[j][3];
            
            if (fabs(bottomLeftPoint.x - otherBottomLeftPoint.x) <= duplicateTolerance && fabs(bottomLeftPoint.y - otherBottomLeftPoint.y) <= duplicateTolerance) {
                duplicateIndexes.insert(j);
            }
            
            /**
             TODO :: Figure out reliable duplicate matching algo
             
             if ((otherBottomLeftPoint.x > bottomLeftPoint.x && otherBottomLeftPoint.y > bottomLeftPoint.y
                && otherBottomLeftPoint.x < bottomLeftPointExtrapolated.x && otherBottomLeftPoint.y < bottomLeftPointExtrapolated.y) ||
                ((topRightPoint.x > bottomLeftPoint.x && topRightPoint.y > bottomLeftPoint.y
                  && topRightPoint.x < bottomLeftPointExtrapolated.x && topRightPoint.y < bottomLeftPointExtrapolated.y) )) {
                
                duplicateIndexes.insert(j);
                
            }**/
        }
    }
    
    //Overwrite the original squares array with the filtered array
    
    squares = filteredSquares;
}


static void manageSquares(const Mat& image, vector<cv::Mat> &finalImages, vector<vector<Point> >& squares ) {
    
    for (int i=0; i < squares.size(); i++) {
        
        /**
         Step 1:
         Sort accroding to x
         **/
        
        
        std::sort(squares[i].begin(), squares[i].end(), sortX());
        
        /**
         Step 2:
         Get the extreme corners x and make them consistent i.e. x1 = x0 & x2 = x3
         **/
        
        squares[i][1].x = squares[i][0].x;
        squares[i][2].x = squares[i][3].x;
        
        /**
         Step 3:
         Sort accroding to y
         **/
        
        std::sort(squares[i].begin(), squares[i].end(), sortY());
        
        /**
         Step 4:
         Get the extreme corners y and make them consistent i.e. y1 = y0 & y2 = y3
         **/
        
        squares[i][1].y = squares[i][0].y;
        squares[i][2].y = squares[i][3].y;
        
        /**
         Step 5:
         Sort accroding to x again to be able to calculate length, width and extreme left bottom point
         **/
        
        std::sort(squares[i].begin(), squares[i].end(), sortX());
        
        /**
         Step 6:
         Calculate the length, width & bottom left bottom
         **/
        
        Point topLeftPoint = squares[i][0];
        float length = abs(squares[i][1].x - squares[i][2].x);
        float width = abs(squares[i][0].y - squares[i][1].y);
        
        float maxLength = length + topLeftPoint.x > image.cols ? image.cols - topLeftPoint.x : length;
        float maxWidth = width + topLeftPoint.y > image.rows ? image.rows - topLeftPoint.y : width;
        
        cv::Mat cutOutImage;
        Mat(image, Rect(topLeftPoint.x, topLeftPoint.y, maxLength, maxWidth)).copyTo(cutOutImage);
        
        finalImages.push_back(cutOutImage);
    }
        
}


static double angle( Point pt1, Point pt2, Point pt0 )
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

// returns sequence of squares detected on the image.
// the sequence is stored in the specified memory storage
//static void findSquares( const Mat& image, vector<vector<Point> >& squares )

static void findSquares(  const Mat& image,   vector<vector<Point> >& squares )

{
    squares.clear();
    
    Mat pyr, timg, gray0(image.size(), CV_8U), gray;
    
    // down-scale and upscale the image to filter out the noise
    pyrDown(image, pyr, Size(image.cols/2, image.rows/2));
    pyrUp(pyr, timg, image.size());
    vector<vector<Point> > contours;
    
    // find squares in every color plane of the image
    int planes = 1;
    int canny = 0;
    if (accuracy) {
        planes = 4;
        canny = 1;
    }
    for( int c = 0; c < planes; c++ )
    {
        int ch[] = {c, 0};
        mixChannels(&timg, 1, &gray0, 1, ch, 1);
        
        // try several threshold levels
        for( int l = 0; l < N; l++ )
        {
            // hack: use Canny instead of zero threshold level.
            // Canny helps to catch squares with gradient shading
            if( l == 0 && canny == 1 )
            {
                // apply Canny. Take the upper threshold from slider
                // and set the lower to 0 (which forces edges merging)
                Canny(gray0, gray, 0, thresh, 5);
                // dilate canny output to remove potent5ial
                // holes between edge segments
                dilate(gray, gray, Mat(), Point(-1,-1));
            }
            else
            {
                // apply threshold if l!=0:
                //     tgray(x,y) = gray(x,y) < (l+1)*255/N ? 255 : 0
                gray = gray0 >= (l+1)*255/N;
            }
            
            // find contours and store them all as a list
            findContours(gray, contours, RETR_LIST, CHAIN_APPROX_SIMPLE);
            
            vector<Point> approx;
            
            // test each contour
            for( size_t i = 0; i < contours.size(); i++ )
            {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                approxPolyDP(Mat(contours[i]), approx, arcLength(Mat(contours[i]), true)*0.02, true);
                
                // square contours should have 4 vertices after approximation
                // relatively large area (to filter out noisy contours)
                // and be convex.
                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                if( approx.size() == 4 &&
                   fabs(contourArea(Mat(approx))) > 1000 &&
                   isContourConvex(Mat(approx)) )
                {
                    double maxCosine = 0;
                    
                    for( int j = 2; j < 5; j++ )
                    {
                        // find the maximum cosine of the angle between joint edges
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    
                    // if cosines of all angles are small
                    // (all angles are ~90 degree) then write quandrange
                    // vertices to resultant sequence
                    
                    if( maxCosine < tolerance )
                        squares.push_back(approx);
                }
            }
        }
    }
}


// the function draws all the squares in the image
//static void drawSquares( Mat& image, const vector<vector<Point> >& squares )
static void drawSquares( Mat& image, vector<vector<Point> >& squares )
{
    for( size_t i = 0; i < squares.size(); i++ )
    {
        const Point* p = &squares[i][0];
        int n = (int)squares[i].size();
        
        vector<Point> vec = squares[i];
        
        sortSquarePointsClockwise(vec);
        
        Point minPoint = vec[0];
        
        polylines(image, &p, &n, 1, true, Scalar(0,255,0), 3, LINE_AA);
    }
    
    //imshow(wndname, image);.
}


// Helper
cv::Point getCenter( std::vector<cv::Point> points ) {
    
    cv::Point center = cv::Point( 0.0, 0.0 );
    
    for( size_t i = 0; i < points.size(); i++ ) {
        center.x += points[ i ].x;
        center.y += points[ i ].y;
    }
    
    center.x = center.x / points.size();
    center.y = center.y / points.size();
    
    return center;
    
}

// Helper;
// 0----1
// |    |
// |    |
// 3----2
std::vector<cv::Point> sortSquarePointsClockwise( std::vector<cv::Point> square ) {
    
    cv::Point center = getCenter( square );
    
    std::vector<cv::Point> sorted_square;
    for( size_t i = 0; i < square.size(); i++ ) {
        if ( (square[i].x - center.x) < 0 && (square[i].y - center.y) < 0 ) {
            switch( i ) {
                case 0:
                    sorted_square = square;
                    break;
                case 1:
                    sorted_square.push_back( square[1] );
                    sorted_square.push_back( square[2] );
                    sorted_square.push_back( square[3] );
                    sorted_square.push_back( square[0] );
                    break;
                case 2:
                    sorted_square.push_back( square[2] );
                    sorted_square.push_back( square[3] );
                    sorted_square.push_back( square[0] );
                    sorted_square.push_back( square[1] );
                    break;
                case 3:
                    sorted_square.push_back( square[3] );
                    sorted_square.push_back( square[0] );
                    sorted_square.push_back( square[1] );
                    sorted_square.push_back( square[2] );
                    break;
            }
            break;
        }
    }
    
    return sorted_square;
    
}

// Helper
float distanceBetweenPoints( cv::Point p1, cv::Point p2 ) {
    
    if( p1.x == p2.x ) {
        return abs( p2.y - p1.y );
    }
    else if( p1.y == p2.y ) {
        return abs( p2.x - p1.x );
    }
    else {
        float dx = p2.x - p1.x;
        float dy = p2.y - p1.y;
        return sqrt( (dx*dx)+(dy*dy) );
    }
}

cv::Mat getPaperAreaFromImage( cv::Mat image, std::vector<cv::Point> square )
{
    
    // declare used vars
    int paperWidth  = 210; // in mm, because scale factor is taken into account
    int paperHeight = 297; // in mm, because scale factor is taken into account
    cv::Point2f imageVertices[4];
    float distanceP1P2;
    float distanceP1P3;
    bool isLandscape = true;
    int scaleFactor;
    cv::Mat paperImage;
    cv::Mat paperImageCorrected;
    cv::Point2f paperVertices[4];
    
    // sort square corners for further operations
    square = sortSquarePointsClockwise( square );
    
    // rearrange to get proper order for getPerspectiveTransform()
    imageVertices[0] = square[0];
    imageVertices[1] = square[1];
    imageVertices[2] = square[3];
    imageVertices[3] = square[2];
    
    // get distance between corner points for further operations
    distanceP1P2 = distanceBetweenPoints( imageVertices[0], imageVertices[1] );
    distanceP1P3 = distanceBetweenPoints( imageVertices[0], imageVertices[2] );
    
    // calc paper, paperVertices; take orientation into account
    if ( distanceP1P2 > distanceP1P3 ) {
        scaleFactor =  ceil( lroundf(distanceP1P2/paperHeight) ); // we always want to scale the image down to maintain the best quality possible
        paperImage = cv::Mat( paperWidth*scaleFactor, paperHeight*scaleFactor, CV_8UC3 );
        paperVertices[0] = cv::Point( 0, 0 );
        paperVertices[1] = cv::Point( paperHeight*scaleFactor, 0 );
        paperVertices[2] = cv::Point( 0, paperWidth*scaleFactor );
        paperVertices[3] = cv::Point( paperHeight*scaleFactor, paperWidth*scaleFactor );
    }
    else {
        isLandscape = false;
        scaleFactor =  ceil( lroundf(distanceP1P3/paperHeight) ); // we always want to scale the image down to maintain the best quality possible
        paperImage = cv::Mat( paperHeight*scaleFactor, paperWidth*scaleFactor, CV_8UC3 );
        paperVertices[0] = cv::Point( 0, 0 );
        paperVertices[1] = cv::Point( paperWidth*scaleFactor, 0 );
        paperVertices[2] = cv::Point( 0, paperHeight*scaleFactor );
        paperVertices[3] = cv::Point( paperWidth*scaleFactor, paperHeight*scaleFactor );
    }
    
    cv::Mat warpMatrix = getPerspectiveTransform( imageVertices, paperVertices );
    cv::warpPerspective(image, paperImage, warpMatrix, paperImage.size(), cv::INTER_LINEAR, cv::BORDER_CONSTANT );
    
    // we want portrait output
    if ( isLandscape ) {
        cv::transpose(paperImage, paperImageCorrected);
        cv::flip(paperImageCorrected, paperImageCorrected, 1);
        return paperImageCorrected;
    }
    
    return paperImage;
    
}



//int main(int /*argc*/, char** /*argv*/)
/*
 {
 static const char* names[] = { "pic1.png", "pic2.png", "pic3.png",
 "pic4.png", "pic5.png", "pic6.png", 0 };
 help();
 namedWindow( wndname, 1 );
 vector<vector<Point> > squares;
 
 for( int i = 0; names[i] != 0; i++ )
 {
 Mat image = imread(names[i], 1);
 if( image.empty() )
 {
 cout << "Couldn't load " << names[i] << endl;
 continue;
 }
 
 findSquares(image, squares);
 drawSquares(image, squares);
 
 int c = waitKey();
 if( (char)c == 27 )
 break;
 }
 
 return 0;
 
 }
 */




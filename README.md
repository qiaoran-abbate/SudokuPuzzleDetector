# SudokuPuzzleDetector
Detecting Sudoku Puzzle on new-papers using computer vision. 
Download all files including TEST IMAGE, and double click to run "SudokuProject_Li_Qiaoran_MAIN.m" with Matlab. 

# Introduction
This report is written to summarize Sudoku project for class CSCI 631. There are five sections to this report, which are General Algorithm, Challenges and Solutions, Improved OCR Confidence, Possible Feature Improvement, and Conclusion. In General Algorithm, you will find the overall flow and design of the program. In Challenges and Solutions, you will find the roadblocks I’ve encountered in the project and how I solved them. In Improved OCR Confidence, I will explain in detail how I got the program to work perfectly for all input images. In Future Improvement, I noted two areas that can be improved when the need arises.  Lastly, I summarized, what I’ve learned from the project and the course in general. 

# General Algorithm 
The general algorithm of this project can be briefly described in the following steps: 
1.	Read in file 
2.	Convert to black and white image using a median filter
    ![Binarization](https://github.com/qiaoranli/SudokuPuzzleDetector/blob/master/doc_images/1.png)
3.  Remove noise using morphology
    ![Morphology](https://github.com/qiaoranli/SudokuPuzzleDetector/blob/master/doc_images/2.png)
4.	Find the largest blob in the region and remove everything else
    ![Detecting Blobs](https://github.com/qiaoranli/SudokuPuzzleDetector/blob/master/doc_images/3.png)
5.	Rotate the image using Hough transform 
6.	Calculate the closest outline of the sudoku 
7.	Outline the sudoku square on the original image (linear interpolation) 
    ![Linear interpolation](https://github.com/qiaoranli/SudokuPuzzleDetector/blob/master/doc_images/4.png)
8.	Perform projective transformation using the corner point of the sudoku
9.	Crop the sudoku square out of the image
    ![Harris Corners](https://github.com/qiaoranli/SudokuPuzzleDetector/blob/master/doc_images/5.png)
10.	Clear the border 
    ![Clear Border](https://github.com/qiaoranli/SudokuPuzzleDetector/blob/master/doc_images/6.png)
11.	Skeletonizing the cropped image
    ![Skeletonization](https://github.com/qiaoranli/SudokuPuzzleDetector/blob/master/doc_images/7.png)
12.	Find the blobs and centrodes on the cropped image 
    ![Centrode](https://github.com/qiaoranli/SudokuPuzzleDetector/blob/master/doc_images/8.png)
13.	For each blob:
    * Calculate the overlap rate with each template (0 -9) image,
    * Pick the max response rate as the matching number 
    * If the DOC is below a certain threshold, then check for Euler number of the value of the centroid to improve result     
14.	Print out the result
#
    4     0     0     0     2     3     0     7     0
    0     0     3     0     0     0     4     0     6
    9     0     0     0     7     4     2     0     0
    0     6     0     5     0     0     0     9     8
    0     0     8     0     6     0     7     0     0
    2     9     0     0     0     8     0     6     0
    0     0     2     3     9     0     0     0     7
    6     0     4     0     0     0     5     0     0
    0     3     0     4     5     0     6     0     0
#


# Challenges and Solutions
## Finding suitable method to convert to black and white image  
Since some of the test images are sitting on black or white background, the regular im2bw function won’t work so well. In this case, my solution is using a median as the level, and anything above it will be white, while anything below it will be black. This solved the problem of the black and white background. 

#
    %% convert image to black and white 
    I = imOriginal;
    % create the function
    makebw = @(I) im2bw(I.data,median(double(I.data(:)))/1.3/255);
    % process the image block by block
    I = ~blockproc(I,[92 92],makebw); 
    imshow(I);

#

## Finding the right noise removal techniques 
Removing the noise was a little tricky. Some Sudoku square’s outlines are very close to other lines; thus, we need to separate them. Some Sudoku square’s outline has gaps; thus we need to fill them. After trying a few combinations, here is the solution I’ve found: 

#
    % disolve small noise in the background 
    I = bwareaopen(I,100);
    % Clear the border 
    I = imclearborder(I);
    % make sure close parallel lines are not touching each other 
    I = imopen(I,strel('disk', 3));
    % make sure gaps within a line are filled 
    I = imclose(I,strel('disk', 3));
#

# Techniques to Identify Letters: 
The approach used in this project was template matching. After we’ve identified the perfect sudoku square without any grid or border, we then try to find the connected component which is usually the number blobs, as well as the centroid of each by using region props: 

#
    % find the connected component and its centroid
    CC = bwconncomp(ICropped); 
    s = regionprops(CC, 'centroid'); 
    centroids = cat(1, s.Centroid);
#

![ReadyForOCR](https://github.com/qiaoranli/SudokuPuzzleDetector/blob/master/doc_images/a.png)

Then a subroutine, numberItentifier, for template matching is called from the main application (note, the algorithm is inspired by Video Sudoku Solver developed by Teja Muppirala from MathWorks). The template used for the algorithm can be visualized as follows: 

![Template](https://github.com/qiaoranli/SudokuPuzzleDetector/blob/master/doc_images/b.png)

The subroutines take the list of centroids, corner points of the sudoku, number of the templates, as well as the original images, it implements the following algorithm: 

![Degree of Confidence](https://github.com/qiaoranli/SudokuPuzzleDetector/blob/master/doc_images/c.png = 250x)

1.	Calculate the indices of the blobs: 
    * % returns the x, y indices of the blob
    * LocValue = round(2*listOfCentroids)/2;
2.	Then initialize the cell with number 0. 
3.	Compute the overlapping percentage between the blob and the template (DOC)
    * % returns a binary image containing the objects that over laps the pixel(listOfCentroids(k,1) + s, listOfCentroids(k,2)) with 4 connected component
    * N = bwselect(img,listOfCentroids(k,1) + s ,listOfCentroids(k,2));
    
    The template with the maximum non-zero degrees of confidence will be the chosen match. For example, a letter’s degrees of confidence level across the templates can be represented as follows: 
    As you can see, the maximum response is found in the second template, which means that the most probable matching for the blob. However, there are times, when the first and second maximum response-rates are too similar, this indicates that the number in the blob is in bad quality and that we not be able to find the best match.  In order to address this issue, a few conditions are added to the OCR algorithm to improve accuracy. See Improved OCR for more details. 
    * If the value is 0, then break out the loop
    * Pick the template with a maximum degree of DOC, and assign its number to the blob 
    * If there are DOC is below a certain threshold, we will run the additional tests. See details in section DOC Details.
4. Repeat the above step for all templates



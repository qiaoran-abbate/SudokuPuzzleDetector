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


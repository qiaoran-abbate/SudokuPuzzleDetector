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

<p align="center">
    <img src="https://github.com/qiaoranli/SudokuPuzzleDetector/blob/master/doc_images/a.png" alt="ReadyForOCR" align="middle" width="400" >
</p>

Then a subroutine, numberItentifier, for template matching is called from the main application (note, the algorithm is inspired by Video Sudoku Solver developed by Teja Muppirala from MathWorks). The template used for the algorithm can be visualized as follows: 

<p align="center">
    <img src="https://github.com/qiaoranli/SudokuPuzzleDetector/blob/master/doc_images/b.png" alt="Template" align="middle" width="400" >
</p>

The subroutines take the list of centroids, corner points of the sudoku, number of the templates, as well as the original images, it implements the following algorithm: 

<p align="center">
    <img src="https://github.com/qiaoranli/SudokuPuzzleDetector/blob/master/doc_images/c.png" alt="Degree of Confidence" align="middle" width="500" >
</p>

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

# Improved OCR Confidence
## Distinguish between 5 and 6
The number 5 and 6 can look very similar to each other, however, there is a big difference between even the worst 5 and 6 blobs. That is, 6 blobs all contain as least 1 Euler number, and 5 do not. Thus, the following coded is added: 

#
    % If it's a 5 or 6, use the Euler number
    if (LocValue(k,3) == 5 || LocValue(k,3) == 6) && abs(S(5) - S(6)) < 0.1 
        E = regionprops(N,'EulerNumber');
        % if the image contain a euler number, then it must be 6, otherwise 5
        if ~E(1).EulerNumber
            LocValue(k,3) = 6;
        end
    end
#

## Distinguish between 1 and 7
The number 1 and 7 are also very similar in terms of the template response rate. However, the centroid will always be on the number 1 itself well the centroid on the 7 will be not. This means that the centroid on the 1 is 1 while the centroid on the 7 will be a 0. This lead to the addition of the following code: 

#
    %If it's a 1 or 7, check the centroid position is 0 or 1 
    if (LocValue(k,3) == 1 || LocValue(k,3) == 7) && abs(S(1) - S(7)) < 0.5
        R = regionprops(N,'centroid');
      	% if the centroid does not overlap the image object, then it must be a 7, else 1
      	if  N(round(R.Centroid(1)), round(R.Centroid(2))) == 1
                LocValue(k,3) = 1;
          	end
     	end
#

## Distinguish between 1 and 4
Similar to number 5 and 6. Number 1 and 4 always have a low DOC ratio, additionally, 4 have a Euler number while 1 does not. This lead to the following code: 

#
    % If it's a 1 or 4, use the Euler number
      	if (LocValue(k,3) == 1 || LocValue(k,3) == 4) && abs(S(1) - S(4)) < 0.2 
            E = regionprops(N,'EulerNumber');
            % if the image contain a euler number, then it must be 4, otherwise 1
            if ~E(1).EulerNumber
                LocValue(k,3) = 4;
            else
                LocValue(k,3) = 1;
            end
    end
#

# Possible Future Improvement 
My algorithm makes 2 assumptions: 

## The Sudoku square is the largest region on the image
As you can see there are multiple rectangles that are bigger than the sudoku square. As you can see there are multiple rectangles that are bigger than the sudoku square. My algorithm checks for the largest region, and it fails to recognize the correct region One solution is to only consider regions that are square, but then we will face another problem. King crossword is bigger than sudoku, and it’s square. Therefore, I believe the best solution is to isolate each square region and check to see if it contains only 10 edges vertically and horizontally using Hough transform. 

## The image dimension is relatively larg
Take this image, for example, the dimension is 310*497, it is considerably smaller than the other images we’ve been testing.  During the process of noise cleaning, certain steps of morphology will remove most the details within the image. In this particular case, it fails at the step: 
#
    I=imopen(I,strel('disk', 3));
#

One way I can think of to solve this problem might be using a dynamic range. For example, instead of hard-coding 3, I might use 1% of the region blob instead. 

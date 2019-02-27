% Name: Qiaoran Li 
% Content: CSCI 631 Sudoku Project
% Due Date: 4/25/2018
% Professor: Thomas Kinsman

% this function load the test image and pass them through a series of
% imgaing chains to identify a gomoku area and print out the recognized
% letters

function SudokuProject_Li_Qiaoran_MAIN(fn)
    addpath('.\TEST_IMAGES')
    addpath('..\TEST_IMAGES')
    addpath('...\TEST_IMAGES')
    load TEMPLATEDATA 

    % Test by passing parameters when calling the main programs 
    % or uncomment the images below to test each images
    if nargin < 1
%         fn = 'SCAN0043.JPG'; % on white, , angled   
%         fn = 'SCAN0097.JPG'; 
%         fn = 'SCAN00101.JPG'; % on black
%         fn = 'SCAN0066.JPG'; 
        fn = 'SCAN0011.JPG'; % more content, no border
%         fn = 'SCAN00051.JPG'; % on black
%         fn = 'SCAN0075.JPG'; % on black, angled
%         fn = 'SCAN0035.JPG'; 
%         fn = 'SCAN00281.JPG'; 
    end
    
    figure('Position', [900, 10 , 1000, 800]);
    
    %% Read In a File 
    imOriginal = imread(fn);
    
    %% convert image to black and white 
    I = imOriginal;
    % create the function
    makebw = @(I) im2bw(I.data,median(double(I.data(:)))/1.3/255);
    % process the image block by block
    I = ~blockproc(I,[92 92],makebw); 

    %% Remove Noise
    % desolve small noise in the background 
    I = bwareaopen(I,100);
    
    % Clear the border 
    I = imclearborder(I);
    IClear = I;  % backup clean image for later use 
    
    % make sure close parallel lines are not touching each other 
    I = imopen(I,strel('disk', 3));
    
    % make sure gaps within a line are filled 
    I = imclose(I,strel('disk', 3));

    
    %% find the largest local region to further eliminate noise  
    
    %label the image 
    I = bwlabel(I);
    R = regionprops(I,'Area','boundingbox', 'PixelList');

    % find the largest closed retangle 
    maxArea = 0;
    for k = 1:numel(R)
        A(k) = prod(R(k).BoundingBox(3:4));
        % update the maxArea if larger ones are found 
        if (R(k).Area > maxArea)
            maxArea = R(k).Area;
            kmax = k;      
        end    
    end
           
    % remove everything but the largest closed retangle 
    I = zeros(size(I,1),size(I,2)); 

    for row = round(R(kmax).BoundingBox(1)): round(R(kmax).BoundingBox(1)+R(kmax).BoundingBox(3))
        for col = round(R(kmax).BoundingBox(2)): round(R(kmax).BoundingBox(2)+R(kmax).BoundingBox(4))
            I(col,row) = IClear(col,row);
        end 
    end 
    
    
    %% rotate the image with hough transform so that the tilt is within -45 to 45 degree 
    Iedge = edge(I, 'canny');

    [H, theta, rho] = hough(Iedge,'RhoResolution', 0.5, 'Theta', -80:01:80);
    peak = houghpeaks(H,2);
    angle = min(theta(peak(:,2)));
    
    % do not rotate if the image is already relatively straight
    if abs(angle) ~= 90
        %imOriginal = imrotate(imOriginal, angle, 'bilinear');
        I = imrotate(I, angle, 'bilinear');
        imOriginal = imrotate(imOriginal, angle, 'bilinear');
    end


    %% calculate the closest outline of the sudoku square
    % label the image rotated image 
    I = bwlabel(I);
    R = regionprops(I,'Area','boundingbox', 'PixelList');
    NR = numel(R); 

    % find the maximum region from image 
    maxArea = 0; % initialize to 0
    for k = 1:NR     
        
        % update the maxArea if larger ones are found 
        if (R(k).Area > maxArea)
            maxArea = R(k).Area;
            kmax = k;      
        end    
    end
   
    % array contianing upper left to lower right diagnal within the image region 
    diagnal1 = sum(R(kmax).PixelList,2);
    % array contianing lower left to upper right diagnal within the image region
    diagnal2 = diff(R(kmax).PixelList,[],2);
    
    % obtain the indices for upper left and lower right pixels from array
    [m,ulCorner] = min(diagnal1);    [m,lrCorner] = max(diagnal1);
    % obtain the indices for lower left and upper right pixels from array
    [m,llCorner] = min(diagnal2);    [m,urCorner]= max(diagnal2);
    
    % compute the vertex for corner pixel within the image region 
    cornerPoints = R(kmax).PixelList([ulCorner llCorner lrCorner urCorner ulCorner],:);
    
    %% outline sudoku square on the original image
    imshow(imOriginal); hold on; 
    plot(cornerPoints(:,1),cornerPoints(:,2),'m','linewidth',3);
    % Draw the grid based on the corners 
    T = cp2tform(cornerPoints(1:4,:),0.5 + [0 0; 9 0; 9 9; 0 9],'projective');
    for n = 0.5 + 0:9, [x,y] = tforminv(T,[n n],[0.5 9.5]); plot(x,y,'g'); end
    for n = 0.5 + 0:9, [x,y] = tforminv(T,[0.5 9.5],[n n]); plot(x,y,'g'); end
    
    %% Projective transformation and crop of the sudoku square 
    T = cp2tform(cornerPoints(1:4,:),500*[0 0; 1 0; 1 1; 0 1],'projective');
    ITransformed = imtransform(double(I),T);
    
    % calculate sudoku boundingbox for cropping
    ITransformedLabelled = bwlabel(ITransformed);
    R = regionprops(ITransformedLabelled,'Area','boundingbox', 'PixelList');
    NR = numel(R); 

    % find the maximum region from image 
    maxArea = 0; % initialize to 0
    for k = 1:NR
        % compute the area of the current region
        A(k) = prod(R(k).BoundingBox(3:4));        
        % update the maxArea if larger ones are found 
        if (R(k).Area > maxArea)
            maxArea = R(k).Area;
            kmax = k;      
        end    
    end
    
    % cropping the image 
    ICropped = imcrop(ITransformedLabelled, R(kmax).BoundingBox); 
    
    % clear the border and the grid of the sudoku square 
    ICropped = imopen(imclearborder(ICropped), strel('disk',1));
   
    %% get the skeleton of the letter 
    thinedImage = bwmorph(ICropped,'thin',inf);
    figure; imshow(thinedImage); title('Processed Img Before OCR');    

    % find the connected component and its centroid
    CC = bwconncomp(ICropped); 
    s = regionprops(CC, 'centroid'); 
    centroids = cat(1, s.Centroid);
    
    % compute and define corner points
    width = size(ICropped,1); 
    height = size(ICropped,2); 
    cpt = [1 1; height 1; height width; 1 width; 1 1]; 
    
    % plot the centrods on image 
    hold on; 
    plot(centroids(:,1),centroids(:,2), 'm*'); 
    plot(cpt(:,1),cpt(:,2),'m','linewidth',1);
    hold off; 

    %% Indentify the numbers and print out the result 
    
    % call numberIdentifier function to analyze the numbers 
    LocValue = numberIdentifier(cpt,centroids,NT,ICropped);
    M = zeros(9);
    
    for k = 1:size(LocValue,1)
        M(round(LocValue(k,2)),round(LocValue(k,1))) = LocValue(k,3);
    end
    
    M % print out the final result, use 0 to represent empty spot for each reading
end 

% Name: Qiaoran Li 
% Content: CSCI 631 Sudoku Project
% Due Date: 4/25/2018
% Professor: Thomas Kinsman

% This function uses the vertices of the puzzle quadrilateral "pts"
% to interpolate though each cell within the sudoku puzzle, and performs
% template matching on each blob
%
% param: pts, the cornerpoints of sudoku square
% param: listOfCentroids, the list of centroids
% param: numberOfTemplate, the number of template avaliable 
% param: img, the image containing the sudoku square
% return: the x, y index and the value of the sudoku number 

function [LocValue] = numberIdentifier(pts,listOfCentroids,numberOfTemplate,img)

% Use the vertices to transform the blob coordinates
try
    T = cp2tform(pts(1:4,:),[0.5 0.5; 9.5 0.5; 9.5 9.5; 0.5 9.5],'projective');
catch
    LocValue = nan;
    return
end
LocValue = (tformfwd(T,listOfCentroids));
LocValue = round(2*LocValue)/2;

% The actual identification algorithm
try
    LocValue(end,3) = 0; % add a 3rd row to store the actual number 
    
    % iterate throght the entire list of all possible letters 
    for k = 1:size(listOfCentroids,1)
        for s = [0 -1 1 -2 2 -3 3 -4 4 -5 5]
            % uses the vector x and y to establish a nondefault special
            % coordiante system for img
            N = bwselect(img,listOfCentroids(k,1) + s ,listOfCentroids(k,2));

            % check if N contains nonzero element 
            if any(N(:))
                break
            end
        end
        if s == 5
            LocValue = nan;
            return
            %continue
        end
        
        [i,j] = find(N);
        N = N(min(i):max(i),min(j):max(j));
        
        % Resize to be 20x20
        N = imresize(N,[20 20]);
        
        %for each digit, S(v) represents the degree of matching
        for v = 1:9
            S(v) = sum(sum(N.*numberOfTemplate{v}));
        end
        % find the value of the nonzero max position
        LocValue(k,3) = find(S == max(S),1);
        
        %If it's a 5 or 6, use the Euler number
        if (LocValue(k,3) == 5 || LocValue(k,3) == 6) && abs(S(5) - S(6)) < 0.1 
            E = regionprops(N,'EulerNumber');
            % if the image contain a euler number, then it must be 6,
            % otherwise 5
            if ~E(1).EulerNumber
                LocValue(k,3) = 6;
            end
        end
        
        %If it's a 1 or 4, use the Euler number
        if (LocValue(k,3) == 1 || LocValue(k,3) == 4) && abs(S(1) - S(4)) < 0.2 
            E = regionprops(N,'EulerNumber');
            % if the image contain a euler number, then it must be 4,
            % otherwise 1
            if ~E(1).EulerNumber
                LocValue(k,3) = 4;
            else
                LocValue(k,3) = 1;
            end
        end
        
        %If it's a 1 or 7, check the centroid position is 0 or 1 
        if (LocValue(k,3) == 1 || LocValue(k,3) == 7) && abs(S(1) - S(7)) < 0.5
            R = regionprops(N,'centroid');
            % if the centroid does not overlap the image object, then it
            % must be a 7, otherwise 1
            if  N(round(R.Centroid(1)), round(R.Centroid(2))) == 1
                LocValue(k,3) = 1;
            end
        end
        
        if (LocValue(k,3) == 1 || LocValue(k,3) == 2) 
            if(S(2)<0.5)
                LocValue(k,3) = 1;
            else
                LocValue(k,3) = 2;
            end 
        end 
        
    end
catch
    %keyboard
end
LocValue = sortrows(LocValue);

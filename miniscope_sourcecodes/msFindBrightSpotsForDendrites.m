function vidObj = msFindBrightSpotsForDendrites(vidObj,stepSize, frameLimits,dFFTresh, backgroundTresh, area_threshold, plotting)
%MSFINDBRIGHTSPOTS Function will identify the frame and pixel location of
%local maxima of dF/F across entire video. msFindBrightSpots will step
%through the video detecting locations that exceed dFFThresh and
%backgroundThresh.  This information is then used in msAutoSegment2
%   vidObj = The Miniscope data structure which contains location of video
%   files and preprocessing corrections
%   stepSize = number of frames to step by
%   frameLimits = [startFrameNumber endFrameNumber]. Leave this as an empty
%   array '[]' if you want to run through the entire video
%   dFFTresh = Local maxima need to be above this threshold to be detected.
%   Usually 0.03 to 0.1 works well
%   backgroundTresh = how much brighter a local maxima needs to be over the
%   surrounding background to be detected. 0.02 to 0.05 seem to work well.


if isempty(frameLimits) 
    frameLimits = [1 vidObj.numFrames];
end


%smoothing kernal
hSmall = fspecial('average', 3);
hLarge = fspecial('average', 60);

red = cat(3, ones(vidObj.alignedHeight(vidObj.selectedAlignment),vidObj.alignedWidth(vidObj.selectedAlignment)), ...
    zeros(vidObj.alignedHeight(vidObj.selectedAlignment),vidObj.alignedWidth(vidObj.selectedAlignment)), ...
    zeros(vidObj.alignedHeight(vidObj.selectedAlignment),vidObj.alignedWidth(vidObj.selectedAlignment)));

%used for overlay in display
green = cat(3, zeros(vidObj.alignedHeight(vidObj.selectedAlignment),vidObj.alignedWidth(vidObj.selectedAlignment)), ...
    ones(vidObj.alignedHeight(vidObj.selectedAlignment),vidObj.alignedWidth(vidObj.selectedAlignment)), ...
    zeros(vidObj.alignedHeight(vidObj.selectedAlignment),vidObj.alignedWidth(vidObj.selectedAlignment)));

% kernal used for eroding and dilating
se = strel('diamond',4);
se2 = strel('diamond',4);

frame = nan(vidObj.alignedHeight(vidObj.selectedAlignment),vidObj.alignedWidth(vidObj.selectedAlignment),stepSize);
vidObj.brightSpots = zeros(vidObj.alignedHeight(vidObj.selectedAlignment),vidObj.alignedWidth(vidObj.selectedAlignment)); %each cell (or pixel) contains the count of local maxima detected
vidObj.brightSpotTiming = sparse(vidObj.alignedHeight(vidObj.selectedAlignment)*vidObj.alignedWidth(vidObj.selectedAlignment),0); %holds the spatiotemporal information of detected bright spots

% 추가한 것
vidObj.brightSpotsContig=zeros(vidObj.alignedHeight(vidObj.selectedAlignment),vidObj.alignedWidth(vidObj.selectedAlignment));
vidObj.contig=zeros(vidObj.alignedHeight(vidObj.selectedAlignment),vidObj.alignedWidth(vidObj.selectedAlignment),length(frameLimits(1):stepSize:min([frameLimits(2) vidObj.numFrames-stepSize])));

count_two=0;
    
for startFrameNum=frameLimits(1):stepSize:min([frameLimits(2) vidObj.numFrames-stepSize]) %steps through data video
   
    count = 0;

    % Generates a max projection of the frames contained in the current
    % step. Applies a small spatial filter to the max projection to remove noise.
    % Applies a large spatial filter to get a measure of the background
    % activity.
    for frameNum = startFrameNum:(startFrameNum+stepSize) 
        count = count+1;
        frame(:,:,count) =filter2(hSmall,msReadFrame(vidObj,frameNum,true,true,true));
    end
    frameMax = max(frame,[],3);
    frameBase = filter2(hLarge,frameMax);
    %----------------------------------------------------------------------
    
    %Applies dFFThreshold and backgroundThreshold to the max projection.
    %Erodes the resulting mask to remove noise
    bw = zeros(size(frameMax));
    bw((frameMax-frameBase >= backgroundTresh) & (frameMax >dFFTresh)) = 1;
    bw = imerode(bw,se2);
    %         bw = imdilate(bw,se2);
    %----------------------------------------------------------------------
    count_two=count_two+1;
    %Finds the centroid of regions in the thresholded max projection
    %Records their pixel location and frame number
    bwProps = regionprops(logical(bw), frameMax, 'Area', 'BoundingBox', 'Image', 'PixelIdxList','Centroid','WeightedCentroid');
    propNumMat=zeros(size(bwProps, 1), 1);
    for propNum = 1:length(bwProps)
        centroid = floor(bwProps(propNum).WeightedCentroid);        
        if (bwProps(propNum).Area >=area_threshold) % bwProps(propNum).Area < 500 && 
            vidObj.brightSpots(centroid(2),centroid(1)) = vidObj.brightSpots(centroid(2),centroid(1)) + 1;
            vidObj.brightSpotTiming(centroid(2)+(centroid(1)-1)*vidObj.alignedHeight,...
                vidObj.brightSpots(centroid(2),centroid(1))) = frameNum;
            propFrame = bwProps(propNum).BoundingBox;
            propFrameBox = [ceil(propFrame(2)) ceil(propFrame(1)) ...
                ceil(propFrame(2))+propFrame(4)-1 ceil(propFrame(1))+propFrame(3)-1];
            vidObj.contig(propFrameBox(1):propFrameBox(3), propFrameBox(2):propFrameBox(4), count_two) = vidObj.contig(propFrameBox(1):propFrameBox(3), propFrameBox(2):propFrameBox(4), count_two) + bwProps(propNum).Image;
            vidObj.brightSpotsContig(propFrameBox(1):propFrameBox(3), propFrameBox(2):propFrameBox(4)) = vidObj.brightSpotsContig(propFrameBox(1):propFrameBox(3), propFrameBox(2):propFrameBox(4)) +...
                bwProps(propNum).Image;
            propNumMat(propNum, 1) = 1;
        end
    end  
    %----------------------------------------------------------------------
    
    IndAboveTh=find(propNumMat);
    NumAboveTh=sum(propNumMat);
    %Plotting (Can be commented out)
    if plotting == true
        figure(1);
        clf
        hold off
        subplot_tight(1,2,1,0.05*[1 1])
        pcolor(frameMax)
        caxis([-0.05 .3]) %sets visial dF/F range    
        colormap gray
        freezeColors
        shading flat
        hold on
        %overlay outline of segmentations
        h3 = imshow(green);
        set(h3, 'AlphaData', bw);
        title(['Frame: ' num2str(frameNum) '/' num2str(vidObj.numFrames)]);
        subplot_tight(1,2,2,0.05*[1 1])
%         pcolor(vidObj.brightSpots)
        L = bwlabel(bw);
        imshow(label2rgb(L, @jet, [.7 .7 .7]))
        daspect([1 1 1])
        shading flat
        colormap jet
        freezeColors
        
        hold on;
        for kk = 1:NumAboveTh
            plot(bwProps(IndAboveTh(kk)).WeightedCentroid(1), bwProps(IndAboveTh(kk)).WeightedCentroid(2),...
                'ko');
            hold on;
        end
        

    end
    %----------------------------------------------------------------------

end


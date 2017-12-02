function ms = msSelectROIs(ms)
%MSSELECTROIS Summary of this function goes here
%   Detailed explanation goes here

    numROIs=0;
    userInput = 'Y';
    refFrameNumber = ceil(ms.numFrames/2);
    refFrame = msReadFrame(ms,refFrameNumber,true,false,false);
    
    himage = figure;
    figure(himage)
    
    if (isfield(ms,'alignmentROI'))  %checks if alignmentROIs already exsist
        imshow(uint8(refFrame), [min(ms.minFluorescence) max(ms.maxFluorescence)]);
        hold on
        for ROINum = 1:size(ms.alignmentROI,2)
            rectangle('Position', ms.alignmentROI(:,ROINum),'LineWidth',1,'EdgeColor', [1 0 0],'LineStyle','--');
        end
        userInput = upper(input('Session already has alignment ROIs. Reset ROIs? (Y/N)','s'));
    end

    if strcmp(userInput,'Y')
        ms.alignmentROI = [];
        temp = {'hShift','wShift','alignedWidth','alignedHeight'};
        idx = isfield(ms,temp);
        ms = rmfield(ms,temp(idx));

        imshow(uint8(refFrame));
        hold on
        while (strcmp(userInput,'Y'))
            numROIs = numROIs+1;
            display('Select ROI (select areas around vessels) from the figure.')
            display('How to: Draw ROI box in the figure window by drag & drop.')
            rect = getrect(); 
            rect(3) = rect(3) - mod(rect(3),2);
            rect(4) = rect(4) - mod(rect(4),2);

            ms.alignmentROI(:,numROIs) = rect; %uint16([rect(1) rect(1)+rect(3) rect(2) rect(2)+rect(4)]);
            rectangle('Position',rect,'LineWidth',1, 'EdgeColor', [1 0 0], 'LineStyle','--');
            userInput = 'N'; % changed
            display('ROI Selection has been completed.');
            
            saveas(himage, [ms.outputPath, '\alignment_selected_ROI.png']);
%             userInput = upper(input('Select another ROI? (Y/N)','s'));
        end
    end 
end


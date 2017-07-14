function frame = msReadFrame(ms,frameNum,columnCorrect, align, dFF)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    
    vidNum = ms.vidNum(frameNum);
    vidFrameNum = ms.frameNum(frameNum);    
    frame = double(ms.vidObj{vidNum}.read(vidFrameNum));
 
    if size(frame, 3)~=1
       frame=frame(:,:,2); 
    end
    
    if (columnCorrect)
        frame = frame - ms.columnCorrection + ms.columnCorrectionOffset;
    end
    if (align)
        frame = frame(((max(ms.hShift(:,ms.selectedAlignment))+1):(end+min(ms.hShift(:,ms.selectedAlignment))-1))-ms.hShift(frameNum,ms.selectedAlignment), ...
                      ((max(ms.wShift(:,ms.selectedAlignment))+1):(end+min(ms.wShift(:,ms.selectedAlignment))-1))-ms.wShift(frameNum,ms.selectedAlignment));
        frame(ms.vessel_position) = 0;
    end
    if (dFF)
%         idx = ms.maxFrame{ms.selectedAlignment}<0.2*max(ms.maxFrame{ms.selectedAlignment}(:)); % need to be changed
        frame = frame./ms.minFrame{ms.selectedAlignment}-1;
%         frame(idx) = 0;
    end
end
function ms = msFluorFrameProps(ms)
%MSFLOURFRAME Summary of this function goes here
%   Detailed explanation goes here

    disp('Calculating fluorescence properties...');

    minFluorescence = nan(1,ms.numFrames);
    meanFluorescence = nan(1,ms.numFrames);
    maxFluorescence = nan(1,ms.numFrames);

    parfor frameNum=1:ms.numFrames
        frame = msReadFrame(ms,frameNum,true,false,false);
        minFluorescence(frameNum) = min(frame(:));
        maxFluorescence(frameNum) = max(frame(:));
%         ms.quant10Fluorescence(frameNum) = quantile(frame(:),.1);
%         ms.quant90Fluorescence(frameNum) = quantile(frame(:),.9);
        meanFluorescence(frameNum) = mean(frame(:));
    end

    ms.minFluorescence=minFluorescence;
    ms.maxFluorescence=maxFluorescence;
    ms.meanFluorescence=meanFluorescence;
    
%     ms.minF = min(ms.minFluorescence);
%     ms.maxF = max(ms.maxFluorescence);

    
end


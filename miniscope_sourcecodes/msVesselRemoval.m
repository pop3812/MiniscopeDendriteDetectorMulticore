function [ ms ] = msVesselRemoval( ms, vessel_threshold )
%MSVESSELREMOVAL 이 함수의 요약 설명 위치
%   자세한 설명 위치

    disp('Removing Vessel and artifact pixels from the video...');
    diffFrame = ms.maxFrame{ms.selectedAlignment}-ms.minFrame{ms.selectedAlignment};

    max_diff = max(diffFrame(:));
    threshold = max_diff * vessel_threshold;
%     idx = ms.maxFrame{ms.selectedAlignment}<vessel_threshold*max(ms.maxFrame{ms.selectedAlignment}(:));

    idx = threshold>diffFrame;
    ms.vessel_position = idx;
    
    ms.vessel_position = imgaussfilt(double(ms.vessel_position),4);
    ms.vessel_position = (ms.vessel_position>0.2);
    
    figure;
    subplot(1,2,2);
    imagesc(ms.vessel_position);
    title('Vessel position detected : ');
    axis off;
    
    subplot(1,2,1);
    imagesc(ms.meanFrame{ms.selectedAlignment});
    title('Original image'); colormap gray;
    axis off;
end


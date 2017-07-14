function [ ms ] = msVesselRemoval( ms, vessel_threshold )
%MSVESSELREMOVAL 이 함수의 요약 설명 위치
%   자세한 설명 위치

    disp('Removing Vessel and artifact pixels from the video.');
    diffFrame = ms.maxFrame{ms.selectedAlignment}-ms.minFrame{ms.selectedAlignment};
    max_diff = max(diffFrame(:));
    threshold = max_diff * vessel_threshold;
%     idx = ms.maxFrame{ms.selectedAlignment}<vessel_threshold*max(ms.maxFrame{ms.selectedAlignment}(:));

    idx = threshold>diffFrame;
    ms.vessel_position = idx;
    disp('Done.');

    figure;
    imagesc(ms.vessel_position);
    title('Vessel position detected : ');
    axis off;
end


function [ ms ] = msVesselRemoval( ms, vessel_threshold )
%MSVESSELREMOVAL �� �Լ��� ��� ���� ��ġ
%   �ڼ��� ���� ��ġ

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


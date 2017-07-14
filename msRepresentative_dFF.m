function [ms] = msRepresentative_dFF(ms, downsample_rate, mode)
%MSMEANDFF �� �Լ��� ��� ���� ��ġ
%   �ڼ��� ���� ��ġ

dsamp_space = ms.space_down_samp_rate;
sumFrame = imresize(zeros(ms.alignedHeight, ms.alignedWidth), 1/dsamp_space, 'bilinear');

disp('Calculation of representative image......')

for jj=1:downsample_rate:ms.numFrames
    frame = imresize(msReadFrame(ms, jj, true, true, true), 1/dsamp_space, 'bilinear' );
    if strcmp(mode, 'avg')
        sumFrame = sumFrame + frame; % average
    elseif strcmp(mode, 'max')
        sumFrame(frame>sumFrame)=frame(frame>sumFrame); % max
    end
end

if strcmp(mode, 'avg')
    ms.meandFF = sumFrame./ms.numFrames; % average
elseif strcmp(mode, 'max')
    ms.meandFF = sumFrame; % max
end

end


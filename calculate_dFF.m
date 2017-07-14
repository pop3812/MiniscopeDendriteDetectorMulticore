function [ params ] = calculate_dFF( params )
%CALCULATE_DFF 이 함수의 요약 설명 위치
%   자세한 설명 위치

frames = params.inputSeq;
numberOfFrames = params.numberOfFrames;
minFrame = min(frames, [], 3);
pixw = params.pixw;
pixh = params.pixh;

dFF = zeros(pixw, pixh, numberOfFrames);

for i = 1:numberOfFrames
    dFF(:,:,i) = frames(:,:,i)./minFrame-1;
end

params.baseline_F = minFrame;
params.dFF = dFF;

%
params.inputSeq = dFF;

end


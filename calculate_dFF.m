function [ params ] = calculate_dFF( params )
%CALCULATE_DFF �� �Լ��� ��� ���� ��ġ
%   �ڼ��� ���� ��ġ

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


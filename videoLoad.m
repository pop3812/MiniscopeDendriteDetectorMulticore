function [ params ] = videoLoad( inputPath )
%VIDEOLOAD 이 함수의 요약 설명 위치
%   자세한 설명 위치

params.inputPath=inputPath;

% Read in the movie.
mov = VideoReader(inputPath);

% Determine how many frames there are.
numberOfFrames = mov.FrameRate * mov.Duration;
pixw = mov.Width;
pixh = mov.Height;

%
pixw = 100;
pixh = 100;
numberOfFrames = 1000;

films = zeros(pixw, pixh, numberOfFrames);
frame=0;

while hasFrame(mov)
    frame=frame+1;
    thisFrame = readFrame(mov);
    
    %
    thisFrame = thisFrame(1:pixw, 1:pixh);
    
    films(:,:, frame)=double(thisFrame');
end

%
% films = films(1:64, 1:64,:);

params.date = datestr(datetime);
params.inputSeq=films;
params.numberOfFrames = numberOfFrames;
params.pixw = pixw;
params.pixh = pixh;
params.frameRate = mov.FrameRate;
params.duration = mov.Duration;
params.fileName = mov.Name;

end


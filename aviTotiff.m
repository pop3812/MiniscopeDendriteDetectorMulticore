function [] = aviTotiff( inputPath, outputPath )
%AVITOTIFF 이 함수의 요약 설명 위치
%   자세한 설명 위치

% Read in the movie.
mov = VideoReader(inputPath);

% Determine how many frames there are.
numberOfFrames = mov.FrameRate * mov.Duration;
films = zeros(mov.Width, mov.Height, 3, numberOfFrames);
frame=0;

while hasFrame(mov)
    frame=frame+1;
    thisFrame = readFrame(mov);
    films(:,:, 1, frame)=double(thisFrame');
    films(:,:, 2, frame)=double(thisFrame');
    films(:,:, 3, frame)=double(thisFrame');
end

% Write it out to disk.
options.color = true;
saveastiff(films, outputPath, options);
% imwrite(films, outputPath, 'tif');

end


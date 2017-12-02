function msExportAligned(ms, save_mat)
%MSEXPORTALIGNED 이 함수의 요약 설명 위치
%   자세한 설명 위치

if nargin < 2
   save_mat = false; 
end

hSmall = fspecial('average', 2);
dirpath = [ms.vidObj{1}.Path, '\aligned'];
filename =  [ms.vidObj{1}.Path, '\aligned\', ms.vidObj{1}.Name];

filename = strrep(filename,'.avi','_aligned.avi');

if (exist(dirpath, 'dir') == 0), mkdir(dirpath); end
    
v = VideoWriter(filename);
v.FrameRate = 30;

open(v);

if save_mat
    video_mat = uint16(zeros(ms.alignedHeight, ms.alignedWidth, ms.numFrames));
end

for frameNum=1:ms.numFrames
    

    
    frame = msReadFrame(ms,frameNum,true,true,false);
    frame = filter2(hSmall,frame);
    if save_mat
        video_mat(:,:,frameNum) = uint16(frame);
    end
    writeVideo(v,uint8(frame));
    
    if (mod(frameNum,1000)==0)
       display(['Export aligned frames. On frame ' num2str(frameNum) '.']);    
    end
    
end

close(v);
disp(['Saved aligned video at : ', filename]);

if save_mat
    Y=video_mat;
    Ysiz=size(video_mat);

    save([dirpath, '\', strrep(ms.vidObj{1}.Name,'.avi','.mat')], 'Y', 'Ysiz', '-v7.3');
end

end


function msExportAligned(ms, save_mat)
%MSEXPORTALIGNED 이 함수의 요약 설명 위치
% saves aligned video, matrix file in input_path\aligned directory
% because of the memory issue, matrix file is saved for every 1,000 frames

if nargin < 2
   save_mat = false; 
end

hSmall = fspecial('average', 2);
date_tag = datestr(datetime('now'), 'yyyymmmdd_HHMMSS');
dirpath = [ms.vidObj{1}.Path, '\aligned_', date_tag];

% filename =  [dirpath, '\', ms.vidObj{1}.Name];
% filename = strrep(filename,'.avi','_aligned.avi');
filename = [dirpath, '\miniscope_data_aligned.avi'];

if (exist(dirpath, 'dir') == 0)
    disp(['Made a result directory.']); mkdir(dirpath); end
    
v = VideoWriter(filename);
v.FrameRate = 30;

open(v);

file_idx = 0;

for frameNum=1:ms.numFrames
    
    if save_mat && mod(frameNum, 1000) == 1
        file_idx = floor(frameNum/1000)+1;
        is_last = ((ms.numFrames-frameNum) < 1000);
        if is_last
            video_mat = uint16(zeros(ms.alignedHeight, ms.alignedWidth, ms.numFrames));
        else
            video_mat = uint16(zeros(ms.alignedHeight, ms.alignedWidth, 1000));
        end
    end
    
    frame = msReadFrame(ms,frameNum,true,true,false);
    frame = filter2(hSmall,frame);
    
    if save_mat
            new_idx = frameNum-(file_idx-1)*1000;
            video_mat(:,:,new_idx) = uint16(frame);
    end
    
    % Save aligned video file
    writeVideo(v,uint8(frame));
    
    % Save aligned matrix file per 1000 frames
    if frameNum == ms.numFrames || mod(frameNum,1000)==0
        if frameNum == ms.numFrames
            display(['Export aligned frames. On frame ' num2str(frameNum) '. (The last frame)']);
        else
            display(['Export aligned frames. On frame ' num2str(frameNum) '.']);
        end
        
        if save_mat
            Y=video_mat;
            Ysiz=size(video_mat);
            save([dirpath, '\', strrep(ms.vidObj{file_idx}.Name,'.avi',...
                ['_aligned.mat'])],...
                'Y', 'Ysiz', '-v7.3');
        end
    end
    
end

close(v);

% Save alignment histogram
msAlignmentHistogram(ms,[]);
saveas(gcf, [dirpath, '\alignment_histogram.png']);

% Save parameters
save([dirpath, '\parameters.mat'],'ms','-v7.3');

disp(['Saved result video (and matrix) at :', newline, char(9), dirpath]);
disp('Pre-processing DONE.');

end


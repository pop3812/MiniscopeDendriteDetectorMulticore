function msPlayVidObj(vidObj,downSamp,columnCorrect, align, dFF, overlay, ica_segments)
%MSPLAYVIDOBJ Summary of this function goes here
%   Detailed explanation goes here
 hSmall = fspecial('average', 2);

    for frameNum=1:downSamp:vidObj.numFrames
             
        frame = msReadFrame(vidObj,frameNum,columnCorrect,align,dFF);
        frame = filter2(hSmall,frame);

        if ~overlay
        pcolor(frame);
        end
        
        if dFF
%                 caxis([0 255]) % [0 0.5]
        else
            caxis([0 255])
        end
        colormap gray
        axis off
        hold on
            
        if overlay && nargin==7
            
            ICuse=[1:size(ica_segments,1)];
            ica_filters=ica_segments;
            sigsm=1;
            colord=[         0         0    1.0000
                    0    0.4000         0
                    1.0000         0         0
                    0    0.7500    0.7500
                    0.7500         0    0.7500
                    0.8, 0.5, 0
                    0         0    0.5
                    0         0.85      0];
            
            f_pos = get(gcf,'Position');
            if f_pos(4)>f_pos(3)
                f_pos(4) = 0.5*f_pos(3);
                set(gcf,'Position',f_pos);
            end
            set(gcf,'Renderer','zbuffer','RendererMode','manual')

            clf
            colormap(gray)

            set(gcf,'DefaultAxesColorOrder',colord)
%             subplot(1,2,1)

            crange = [min(min(min(ica_filters(ICuse,:,:)))),max(max(max(ica_filters(ICuse,:,:))))];
            contourlevel = crange(2) - diff(crange)*[1,1]*0.8;

            cla
            imagesc(imresize(frame,0.5));
            cax = caxis;
            shading flat
            hold on
            
            for j=1:length(ICuse)
            ica_filtersuse = gaussblur(squeeze(ica_filters(ICuse(j),:,:)), sigsm);
            contour(ica_filtersuse, [1,1]*(mean(ica_filtersuse(:))+4*std(ica_filtersuse(:))), ...
                'Color',colord(mod(j-1,size(colord,1))+1,:),'LineWidth',1)
            end
            hold off
            caxis(cax)
            axis image tight off
            
%             title({'Representative image of movie', 'with contours of ICs', ''})

%             for j=1:length(ICuse)
%             ica_filtersuse = gaussblur(squeeze(ica_filters(ICuse(j),:,:)), sigsm);
% 
%             % Write the number at the cell center
%             [ypeak, xpeak] = find(ica_filtersuse == max(max(ica_filtersuse)),1);
%             text(xpeak,ypeak,num2str(j), 'horizontalalignment','c','verticalalignment','m','color','y')
%             end


%             green = cat(3, zeros(vidObj.alignedHeight(vidObj.selectedAlignment),vidObj.alignedWidth(vidObj.selectedAlignment)), ...
%     ones(vidObj.alignedHeight(vidObj.selectedAlignment),vidObj.alignedWidth(vidObj.selectedAlignment)), ...
%     zeros(vidObj.alignedHeight(vidObj.selectedAlignment),vidObj.alignedWidth(vidObj.selectedAlignment)));
%             hold on
%             h = imshow(green);
%             set(h, 'AlphaData', vidObj.segementOutline)
%             
%             hold off
        end
        
        title(['Frame: ' num2str(frameNum) '/' num2str(vidObj.numFrames)]);

        shading flat
        set(gca,'Ydir','reverse') 
        daspect([1 1 1])

    
%     drawnow
    pause(0.01);    
    end
    
end

function fout = gaussblur(fin, smpix)
%
% Blur an image with a Gaussian kernel of s.d. smpix
%

if ndims(fin)==2
    [x,y] = meshgrid([-ceil(3*smpix):ceil(3*smpix)]);
    smfilt = exp(-(x.^2+y.^2)/(2*smpix^2));
    smfilt = smfilt/sum(smfilt(:));

    fout = imfilter(fin, smfilt, 'replicate', 'same');
else
    [x,y] = meshgrid([-ceil(smpix):ceil(smpix)]);
    smfilt = exp(-(x.^2+y.^2)/(2*smpix^2));
    smfilt = smfilt/sum(smfilt(:));

    fout = imfilter(fin, smfilt, 'replicate', 'same');
end
end

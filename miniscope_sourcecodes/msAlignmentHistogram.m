function msAlignmentHistogram(ms,bins)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    if (isempty(bins))
        bins = -20:20;
    end
    hist_fig = figure;
    alignH2 = hist2(ms.hShift ,ms.wShift,bins,bins);
    pcolorCentered(bins,bins,log10(alignH2'));
    colormap parula
%     colorbar
    xlabel('Horizontal Shift (pixel)')
    ylabel('Vertical Shift (pixel)');
    hcb=colorbar;

    ylabel(hcb,'Log10(Number of Frames)')
    
    saveas(hist_fig, [ms.outputPath, '\alignment_histogram.png']);
    
end


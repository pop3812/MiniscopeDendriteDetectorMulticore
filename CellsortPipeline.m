function [ms] = CellsortPipeline(ms, inputPath)
%CELLSORTPIPELINE

% CellSort is a MATLAB toolbox containing code that accompanies the
% manuscript, Automated analysis of cellular signals from large-scale
% calcium imaging data by Eran Mukamel, Axel Nimmerjahn and Mark Schnitzer, NEURON (2009). 

%% Read movie data and perform singular-value decomposition (SVD) dimensional reduction.

[mixedsig, mixedfilters, CovEvals, covtrace, movm, movtm] = CellsortPCA_dendrite(ms, inputPath);

%%  Allows the user to select which principal components will be kept following dimensional reduction.

[PCuse] = CellsortChoosePCs_dendrite(params, mixedfilters);

%%  Plot the principal component (PC) spectrum and compare with the corresponding random-matrix noise floor

CellsortPlotPCspectrum_dendrite(params, CovEvals, PCuse);

%% Perform ICA with a standard set of parameters, including skewness as the objective function
mu=0.5;
nIC=20;

[ica_sig, ica_filters, ica_A, numiter] = CellsortICA_dendrite(mixedsig, mixedfilters, CovEvals, PCuse, mu, nIC) ;

%% 
mode = 'contour'; % 'contour' or 'serial'
% CellsortICAplot(mode, ica_filters, ica_sig, f0, tlims, dt, ratebin, plottype, ICuse, spt, spc);
f0 = mean(params.inputSeq,3);
tlim = [0 params.duration];
dt = 1./params.frameRate;
CellsortICAplot(mode, ica_filters, ica_sig, f0, tlim, dt);

%%
[ica_segments, segmentlabel, segcentroid] = CellsortSegmentation(ica_filters, smwidth, thresh, arealims, plotting);
cell_sig = CellsortApplyFilter(fn, ica_segments, flims, movm, subtractmean);
[spmat, spt, spc, zsig] = CellsortFindspikes(ica_sig, thresh, dt, deconvtau, normalization);

end


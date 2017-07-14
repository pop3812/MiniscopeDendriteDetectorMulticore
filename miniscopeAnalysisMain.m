%% Multicore miniscope analysis tool
% 2017 July by yakwang
% optimized for MATLAB R2017a w/ Parallel processing toolbox

%% ����� ���� ����
% �ý��� ����
use_parallel_processing = 1;                                               % ��Ƽ�ھ� ������� ����

% ���� �б� ���� ����
file_path = 'C:\Users\pop38\Documents\īī���� ���� ����\sample_data';       % ������ ���丮
down_sampling_rate = 5;                                                    % �ٿ� ���ø� (������) 
% down_sample_segmentation = 5;                                               

% ��鸲 ���� ���� ����
plotting_alignment = false;                                                % ���� ���� �÷��� ����

% ���� �� ��� ���� ���� ����
vessel_threshold = 0.1;                                                    % �� ������ �ȼ� ���� ��� ������
                                                                           % ���� �Ǵ� ������� ���� ���� (�⺻�� = 0.1)
% Segmentation ���� ����
space_down_samp_rate = 2;                                                  % ������ �ٿ� ���ø� (�⺻�� = 2)
smwidth = 3;                                                               % Smoothing ���� ũ�� (�⺻�� = 3)
thresh = 2;                                                                % Segment detection threshold (�⺻�� = 2)
arealims = 350;                                                            % Segment ũ�� ���� (�⺻�� = 750)
plotting_segment = 1;                                                      % Segmentation ���� �÷��� ����

% Deconvolution ���� ����
deconvtau = 400;                                                           % Deconvolution filter tau ��
                                                                           % ����: tau-on = 74ms, tau-off = 400ms for GCaMP6f
spike_thresh = 2;                                                          % Spike threshold S.D. (�⺻�� = 2)
normalization = 1;                                                         % Normalization ����

%% Parallel processing preparation (pooling)
pool_connected=gcp;
if use_parallel_processing && ~pool_connected.Connected
    disp('Parallel pool preparation for parallel processing (might take some time)')
    parpool;
end

%% Generates the initial ms data struct for data set contained in current folder
addpath([cd, '\miniscope_sourcecodes']);

ms = msGenerateVideoObj(file_path,'msCam');  
ms = msColumnCorrection(ms,down_sampling_rate);                            % analog-to-digital converting noise ����
ms = msFluorFrameProps(ms);                                                % flourescence ���� Ư�� �м� (max, min, mean)

%% Select fluorescnece thesh for good frames
% ms = msSelectFluorThresh(ms);                                            % ����ڰ� threshold�� ���� ���� ����
fluorThresh = 0.75 * mean(ms.meanFluorescence);
ms.goodFrame = ms.meanFluorescence>=fluorThresh;
ms.fluorThresh = fluorThresh;

%% Allows user to select ROIs for each data folder
ms = msSelectROIs(ms);                                                     % ��鸲 ������ ���� ROI ����

%% Run alignment across all ROIs / Image registration �ܰ�
tic
% ms = msAlignment(ms);                                                    % ��鸲 ����. mid frame �̿��� alignment
ms = msAlignmentFFT(ms,plotting_alignment);                                % ��鸲 ����. FFT�� �̿��� alignment
toc

%% Calculate mean frames
ms = msMeanFrame(ms,down_sampling_rate);                                   % ��� ������ ���

%% Manually inspect and select best alignment
ms = msSelectAlignment(ms);                                                

%% Thresholding for vessel & blot elimination - added by Kwang
% if signal is too low, regard it as artifact
ms = msVesselRemoval(ms, vessel_threshold);

%% Segment Sessions
% dFF�� �Ѱ��ָ� �ٸ� method�� segmentation
% Reference: Mukamel et al. Neuron, 2009.

% ��� ���� �� �� ����
% msPlayVidObj(ms, down_sampling_rate,true,true,true, false);

% ----- pipeline�� �� ����� -----
ms.space_down_samp_rate = space_down_samp_rate;

% Read movie data and perform singular-value decomposition (SVD) dimensional reduction.
[mixedsig, mixedfilters, CovEvals, covtrace, movm, movtm] = CellsortPCA_dendrite(ms, file_path);

%  Allows the user to select which principal components will be kept following dimensional reduction.
% [PCuse] = CellsortChoosePCs_dendrite(ms, mixedfilters);

%  Plot the principal component (PC) spectrum and compare with the corresponding random-matrix noise floor
PCuse=[];
PCuse=CellsortPlotPCspectrum_dendrite(ms, file_path, CovEvals, PCuse);

%%  Perform ICA with a standard set of parameters, including skewness as the objective function
mu=0.15; % the recommended value of mu in the original paper = 0.1-0.2
nIC=size(PCuse,2);

nIC=min([80, nIC]); %%%
[ica_sig, ica_filters, ica_A, numiter] = CellsortICA_dendrite(mixedsig, mixedfilters, CovEvals, PCuse, mu, nIC) ;

mode = 'contour'; % 'contour' or 'series'
representative_mode = 'max'; % 'max' or 'avg'
% CellsortICAplot(mode, ica_filters, ica_sig, f0, tlims, dt, ratebin, plottype, ICuse, spt, spc);
ms = msRepresentative_dFF(ms, down_sampling_rate, representative_mode); % calculate mean dFF
f0 = ms.meandFF;

tlim = [0 ms.vidObj{1}.Duration];
dt = 1./ms.vidObj{1}.FrameRate;
% CellsortICAplot_dendrite(mode, ica_filters, ica_sig, f0, tlim, dt);

[ica_segments, segmentlabel, segcentroid] = CellsortSegmentation_dendrite(ica_filters, smwidth, thresh, arealims, plotting_segment);

%% Apply filter & Find spikes (Deconvolution)

subtractmean = 0;

% ���� ��ȣ ����
cell_sig = CellsortApplyFilter_dendrite(ms, ica_segments, [], movm, subtractmean);

% Spike detection (Deconvolution)
[spmat, spt, spc] = CellsortFindspikes_dendrite(cell_sig, spike_thresh, dt, deconvtau, normalization);

%% Show results

figure(2)
CellsortICAplot_dendrite('contour', ica_segments, cell_sig, f0, tlim, dt, 1, 2, [1:size(ica_segments,1)], spt, spc);

% ms = CellsortPipeline(ms, file_path);

%% original (�ּ� ó��)
% plotting = true;
% area_threshold = 200;
% ms = msFindBrightSpotsForDendrites(ms,down_sample_segmentation,[],.001,0.03, area_threshold, plotting);
% disp('a');
% ms = msAutoSegmentForDendrites(ms,[],[500 10000],down_sampling_rate,.90,plotting);
% 
% %% Calculate Segment relationships
% calcCorr = false;
% calcDist = true;
% calcOverlap = true;
% ms = msCalcSegmentRelations(ms, calcCorr, calcDist, calcOverlap);
% 
% %% Clean Segments
% corrThresh = [];
% distThresh = 7;
% overlapThresh = .8;
% ms = msCleanSegments(ms,corrThresh,distThresh,overlapThresh);
% 
% %% Calculate Segment relationships
% calcCorr = false;
% calcDist = true;
% calcOverlap = true;
% ms = msCalcSegmentRelations(ms, calcCorr, calcDist, calcOverlap);
% 
% %% Calculate segment centroids
% ms = msSegmentCentroids(ms);
% 
% %% Extract dF/F
% ms = msExtractdFFTraces(ms);
% ms = msCleandFFTraces(ms);
% ms = msExtractFiring(ms);
% 
% %% Align across sessions
% % ms = msAlignBetweenSessions(msRef,ms);
% 
% %% Count segments in common field
% % msBatchSegmentsInField(pwd);
% 
% %% Match segments across sessions
% % distThresh = 5;
% % msBatchMatchSegmentsBetweenSessions(pwd, distThresh);
% 
% 
% %% BEHAV STUFF
% 
% %% Generate behav.m
% behav = msGenerateVideoObj(pwd,'behavCam');
% 
% %% Select ROI and HSV for tracking
% behav = msSelectPropsForTracking(behav); 
% 
% %% Extract position
% trackLength = 200;%cm
% behav = msExtractBehavoir(behav, trackLength); 
%% Multicore miniscope analysis tool
% 2017 July by yakwang
% optimized for MATLAB R2017a w/ Parallel processing toolbox

%% 사용자 변수 지정
% 시스템 설정
use_parallel_processing = 1;                                               % 멀티코어 사용할지 여부

% 파일 읽기 관련 변수
file_path = 'C:\Users\pop38\Documents\카카오톡 받은 파일\sample_data';       % 데이터 디렉토리
down_sampling_rate = 5;                                                    % 다운 샘플링 (프레임) 
% down_sample_segmentation = 5;                                               

% 흔들림 보정 관련 변수
plotting_alignment = false;                                                % 보정 과정 플롯팅 여부

% 혈관 및 배경 제거 관련 변수
vessel_threshold = 0.1;                                                    % 이 값보다 픽셀 값이 계속 낮으면
                                                                           % 혈관 또는 배경으로 보고 제거 (기본값 = 0.1)
% Segmentation 관련 변수
space_down_samp_rate = 2;                                                  % 공간상 다운 샘플링 (기본값 = 2)
smwidth = 3;                                                               % Smoothing 필터 크기 (기본값 = 3)
thresh = 2;                                                                % Segment detection threshold (기본값 = 2)
arealims = 350;                                                            % Segment 크기 제한 (기본값 = 750)
plotting_segment = 1;                                                      % Segmentation 과정 플롯팅 여부

% Deconvolution 관련 변수
deconvtau = 400;                                                           % Deconvolution filter tau 값
                                                                           % 참고: tau-on = 74ms, tau-off = 400ms for GCaMP6f
spike_thresh = 2;                                                          % Spike threshold S.D. (기본값 = 2)
normalization = 1;                                                         % Normalization 여부

%% Parallel processing preparation (pooling)
pool_connected=gcp;
if use_parallel_processing && ~pool_connected.Connected
    disp('Parallel pool preparation for parallel processing (might take some time)')
    parpool;
end

%% Generates the initial ms data struct for data set contained in current folder
addpath([cd, '\miniscope_sourcecodes']);

ms = msGenerateVideoObj(file_path,'msCam');  
ms = msColumnCorrection(ms,down_sampling_rate);                            % analog-to-digital converting noise 제거
ms = msFluorFrameProps(ms);                                                % flourescence 세기 특성 분석 (max, min, mean)

%% Select fluorescnece thesh for good frames
% ms = msSelectFluorThresh(ms);                                            % 사용자가 threshold를 보고 직접 선택
fluorThresh = 0.75 * mean(ms.meanFluorescence);
ms.goodFrame = ms.meanFluorescence>=fluorThresh;
ms.fluorThresh = fluorThresh;

%% Allows user to select ROIs for each data folder
ms = msSelectROIs(ms);                                                     % 흔들림 보정을 위한 ROI 선택

%% Run alignment across all ROIs / Image registration 단계
tic
% ms = msAlignment(ms);                                                    % 흔들림 보정. mid frame 이용한 alignment
ms = msAlignmentFFT(ms,plotting_alignment);                                % 흔들림 보정. FFT를 이용한 alignment
toc

%% Calculate mean frames
ms = msMeanFrame(ms,down_sampling_rate);                                   % 평균 프레임 계산

%% Manually inspect and select best alignment
ms = msSelectAlignment(ms);                                                

%% Thresholding for vessel & blot elimination - added by Kwang
% if signal is too low, regard it as artifact
ms = msVesselRemoval(ms, vessel_threshold);

%% Segment Sessions
% dFF만 넘겨주면 다른 method로 segmentation
% Reference: Mukamel et al. Neuron, 2009.

% 결과 비디오 한 번 보기
% msPlayVidObj(ms, down_sampling_rate,true,true,true, false);

% ----- pipeline에 들어갈 내용들 -----
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

% 세포 신호 추출
cell_sig = CellsortApplyFilter_dendrite(ms, ica_segments, [], movm, subtractmean);

% Spike detection (Deconvolution)
[spmat, spt, spc] = CellsortFindspikes_dendrite(cell_sig, spike_thresh, dt, deconvtau, normalization);

%% Show results

figure(2)
CellsortICAplot_dendrite('contour', ica_segments, cell_sig, f0, tlim, dt, 1, 2, [1:size(ica_segments,1)], spt, spc);

% ms = CellsortPipeline(ms, file_path);

%% original (주석 처리)
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
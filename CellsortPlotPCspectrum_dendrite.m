function PCuse=CellsortPlotPCspectrum_dendrite(ms, inputPath, CovEvals, PCuse)
% CellsortPlotPCspectrum(fn, CovEvals, PCuse)
%
% Plot the principal component (PC) spectrum and compare with the
% corresponding random-matrix noise floor
%
% Inputs:
%   fn - movie file name. Must be in TIFF format.
%   CovEvals - eigenvalues of the covariance matrix
%   PCuse - [optional] - indices of PCs included in dimensionally reduced
%   data set
%
% Eran Mukamel, Axel Nimmerjahn and Mark Schnitzer, 2009
% Email: eran@post.harvard.edu, mschnitz@stanford.edu
%

if nargin<4
    PCuse = [];
end

% Receive parameters
numberOfFrames = ms.numFrames;

space_down_samp_rate = ms.space_down_samp_rate;
pixw = ceil(ms.alignedWidth./space_down_samp_rate);
pixh = ceil(ms.alignedHeight./space_down_samp_rate);

npix = pixw*pixh;
nt = numberOfFrames;

% Random matrix prediction (Sengupta & Mitra)
p1 = npix; % Number of pixels
q1 = nt; % Number of time frames
q = max(p1,q1);
p = min(p1,q1);
sigma = 1;
lmax = sigma*sqrt(p+q + 2*sqrt(p*q));
lmin = sigma*sqrt(p+q - 2*sqrt(p*q));
lambda = [lmin: (lmax-lmin)/100.0123423421: lmax];
rho = (1./(pi*lambda*(sigma^2))).*sqrt((lmax^2-lambda.^2).*(lambda.^2-lmin^2));
rho(isnan(rho)) = 0;
rhocdf = cumsum(rho)/sum(rho);
noiseigs = interp1(rhocdf, lambda, [p:-1:1]'/p, 'linear', 'extrap').^2 ;

% Normalize the PC spectrum
normrank = min(nt-1,length(CovEvals));
pca_norm = CovEvals*noiseigs(normrank) / (CovEvals(normrank)*noiseigs(1));

% above noise * 2 level only
pca_norm_ab=pca_norm(pca_norm > 2);

n_pca_extracted = length(pca_norm);
n_pca_recommended = length(pca_norm_ab);

fprintf('\nThe program extracted %d number of PCA components,', n_pca_extracted);
% fprintf('\nand you chose to use %d number of PCA components.', length(PCuse));
fprintf('\nWe recommend you to use %d PCA components. (above 2 x noise level significance)\n', n_pca_recommended);
% if (n_pca_recommended~=length(PCuse))
%     fprintf('We recommend to re-select PCA components.\n', length(PCuse));
% end

clf
plot(pca_norm, 'o-', 'Color', [1,1,1]*0.3, 'MarkerFaceColor', [1,1,1]*0.3, 'LineWidth',2)
hold on
plot(noiseigs / noiseigs(1), 'b-', 'LineWidth',2)
plot(2*noiseigs / noiseigs(1), 'b--', 'LineWidth',2)
if ~isempty(PCuse)
    plot(PCuse, pca_norm(PCuse), 'rs', 'LineWidth',2)
end
hold off
formataxes
set(gca,'XScale','log','YScale','log', 'Color','none')
xlabel('PC rank')
ylabel('Normalized variance')
axis tight
if isempty(PCuse)
    legend('Data variance','Noise floor','2 x Noise floor')
    PCuse=1:n_pca_recommended;
    fprintf('\nAutomatically chose %d PCA components. (above 2 x noise level significance)\n', n_pca_recommended);
else
    legend('Data variance','Noise floor','2 x Noise floor','Retained PCs')
end

fntitle = inputPath;
fntitle(inputPath=='_') = ' ';
title('Principal component (PC) spectrum')

function formataxes

set(gca,'FontSize',12,'FontWeight','bold','FontName','Helvetica','LineWidth',2,'TickLength',[1,1]*.02,'tickdir','out')
set(gcf,'Color','w','PaperPositionMode','auto')


function j = tiff_frames(fn)
%
% n = tiff_frames(filename)
%
% Returns the number of slices in a TIFF stack.
%
% Modified April 9, 2013 for compatibility with MATLAB 2012b

j = length(imfinfo(fn));

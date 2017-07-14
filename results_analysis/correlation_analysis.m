function [ corr_matrix ] = correlation_analysis(cell_sig, segcentroid)
%CORRELATION_ANALYSIS �� �Լ��� ��� ���� ��ġ
%   �ڼ��� ���� ��ġ

n_cell = size(cell_sig, 1);
corr_matrix = corrcoef(cell_sig');

dist_corr = zeros(n_cell*(n_cell-1)/2,2);
count=0;

figure; subplot(1,2,1); imagesc(corr_matrix); colorbar;
title('Correlation matrix')

for i=1:n_cell
   if i>1
    for j=1:i-1
        count=count+1;
        % �Ÿ� ���ϱ�
        dist=sqrt(sum((segcentroid(i,:)-segcentroid(j,:)) .^ 2));
        
        % correlation ���ϱ�
        corr=corr_matrix(i,j);
        
        dist_corr(count, 1)=dist;
        dist_corr(count, 2)=corr;

    end
   end
end

% plotting
subplot(1,2,2); scatter(dist_corr(:,1),dist_corr(:,2), 3,'filled');
xlabel('Distance (pixel)');
ylabel('Correlation coefficient');

end


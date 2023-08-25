function [mCoord_out final_dist] = point_bdb_minus(pntCoord, pntIntensity, mCoord_in, TH, alpha, beta, gamma, img0, K_factor,do_plotting)
%function mCoord_out = point_bdb_minus(pntCoord, pntIntensity, mCoord_in, TH, alpha, beta, gamma, img0)
%
% The BDB_minus method for a set pixels (location in pntCoord, intensity in
% pntIntensity). The initial backbone coordinates of the centers are  mCoord_in.
% This program adjusts the coordinates until converge. 
%
% ** Parameters:
%
% alpha, beta, gamma are weighting factors of different force terms. See
% the reference paper for details.
%
% ** Reference: 
%
% Peng, H., Long, F., Liu, X., Kim, S., and Myers, E.W., "Straightening C. elegans images," 
% Bioinformatics, Vol. 24, No. 2, pp. 234-242, 2008.
% 
% ** Note:
% 
% This program may appear to be slow, because a picture plot is displayed at each step. It will run
% much faster if the respective display/file-io operations are disabled.
%
% Copyright: Hanchuan Peng
% All rights reserved.
%
% Last update: 2008-May-19
%


verbose = 1;

if nargin<9,
    do_plotting=1;
end;

if nargin<8,
    img0 = [];
else
    if ~isdeployed
        if do_plotting
            mean_val = mean(img0(:));
            std_val = std(img0(:));    

            if length(size(img0)) > 2 % Means we are in 3D
                [x,y,z] = meshgrid(1:size(img0,2), 1:size(img0,1),1:size(img0,3));
                disp('Plotting data...');

                clf;    
                K_factor_plotting = 1;
                [xx,yy,zz] = ndgrid(-5:5);
                nhood = sqrt(xx.^2 + yy.^2 + zz.^2) <= 5.0;
                img0 = imopen(img0, nhood);
                img0 = imclose(img0, nhood);
                
                
%                p = patch(isosurface(x,y,z,img0,mean_val+K_factor_plotting*std_val));
                p = patch(isosurface(x,y,z,img0,0.1));
                p.FaceColor = 'red';
                p.EdgeColor = 'none';
                p.FaceAlpha = 0.3;
                daspect([1,1,0.2]);    
                disp('...done');
                grid on;

                h_plot = [];

            else % Means we are in 2D
                [x,y] = meshgrid(1:size(img0,2), 1:size(img0,1));
                disp('Plotting data...');

                clf;
                %contour(x,y,max(img0,[],3),mean_val+K_factor*std_val);
                imagesc(img0);
                axis image;  
                disp('...done');
                grid on;

                h_plot = [];

            end
        end% do_plotting
    end
end;


if nargin<7,
    gamma=0.5;
end;

if nargin<6,
    beta=1;
end;

if nargin<5,
    alpha=0.5;
end;


if nargin<4 | TH<0,
    TH = 0.1; %% the threshold to judge if the algorithm converges
end;

N = size(pntCoord,1); %% number of pixels/points
if (N~=size(pntIntensity,1)),
    error('The first and second para must have the same number of rows.');
end;

ND = size(pntCoord,2); %%dimension of coordinates
if (ND~=size(mCoord_in,2)),
    error('The first and third para must have the same number of columns.');
end;

if (size(pntIntensity,2)~=1),
    error('The column of 2nd para must be 1');
end;

if ~exist('res_tmp', 'dir'),
    mkdir('res_tmp');
end;

M = size(mCoord_in,1); %% number of control points / centers of k_means

MAXLOOP=70;

%%==========
nloop = 0;
while (nloop<MAXLOOP),
    
    d = zeros(N,M); %%distance matrix
    for i=1:M,
        d(:,i) = sum((pntCoord - repmat(mCoord_in(i,:), N, 1)).^2, 2);
    end;

    [YY, II] = min(d, [], 2);
    %UII = unique(II);
    %M_new = length(UII);

    mCoord_in_new = zeros(M, ND);
    for j=1:M,
        j_ind = find(II==j);
        if ~isempty(j_ind),
            M_term = sum(repmat(pntIntensity(j_ind,1), 1, ND) .* pntCoord(j_ind, :), 1) ./ sum(pntIntensity(j_ind,1), 1);
            b_use_M_term = 1;
        else,
            M_term = 0;
            b_use_M_term = 0;
        end;
        
        switch (j),
            case 1,
                F_1_term = mCoord_in(j+1,:);
                F_2_term = 2*mCoord_in(j+1,:) - mCoord_in(j+2,:);
                mCoord_in_new(j,:) = (b_use_M_term*alpha*M_term) ./ (b_use_M_term*alpha);

            case 2,
                F_1_term = mCoord_in(j-1,:) + mCoord_in(j+1,:);
                F_2_term = 2*mCoord_in(j-1,:) + 4*mCoord_in(j+1,:) - mCoord_in(j+2,:);
                mCoord_in_new(j,:) = (beta*F_1_term + b_use_M_term*alpha*M_term) ./ (2*beta + b_use_M_term*alpha);

            case M-1,
                F_1_term = mCoord_in(j-1,:) + mCoord_in(j+1,:);
                F_2_term = -mCoord_in(j-2,:) + 4*mCoord_in(j-1,:) + 2*mCoord_in(j+1,:);
                mCoord_in_new(j,:) = (beta*F_1_term + b_use_M_term*alpha*M_term) ./ (2*beta + b_use_M_term*alpha);

            case M,
                F_1_term = mCoord_in(j-1,:);
                F_2_term = -mCoord_in(j-2,:) + 2*mCoord_in(j-1,:);
                mCoord_in_new(j,:) = (b_use_M_term*alpha*M_term) ./ (b_use_M_term*alpha);

            otherwise,
                F_1_term = mCoord_in(j-1,:) + mCoord_in(j+1,:);
                F_2_term = -0.5*mCoord_in(j-2,:) + 1.5*mCoord_in(j-1,:) + 1.5*mCoord_in(j+1,:) - 0.5*mCoord_in(j+2,:);
                mCoord_in_new(j,:) = (beta*F_1_term + gamma*F_2_term + b_use_M_term*alpha*M_term) ./ (2*beta + 2*gamma + b_use_M_term*alpha);
        end;
        
    end;

    score = NaN;

    tmps = zeros(M,1);
    for i=1:M,
        tmps(i) = sum(abs(mCoord_in_new(i,:) - mCoord_in(i,:)), 2);
    end;
    score = sum(tmps);
    if (score<TH)
        break;
    else
        if ~isempty(img0),
            if ~isdeployed
                if do_plotting

                    hold on;
                    delete(h_plot);

                    if length(size(img0)) > 2 % Means we are in 3D 
                        h_plot = plot3(mCoord_in(:,2),mCoord_in(:,1),mCoord_in(:,3), 'ko-'); 
                        view([45 45]);
                        drawnow;
                        hold off;
                    else
                        h_plot = plot(mCoord_in(:,2),mCoord_in(:,1), 'ko-'); 
                        %view([45 45]);
                        drawnow;
                        hold off;

                    end
                end
            end
        end;

        mCoord_in = mCoord_in_new;
    end;
    
    nloop = nloop+1;
    if verbose
        fprintf('score[%d]=%5.3f total dist=%5.3f.\n', nloop, score, sum(YY));
    end

end;

final_dist  = sum(YY);
    
mCoord_out = mCoord_in_new;

if exist('res_tmp', 'dir'),
    rmdir('res_tmp', 's');
end;

return;
   
    

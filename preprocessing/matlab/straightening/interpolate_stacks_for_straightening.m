function [straightened_trigger, straightened_channels,sample_points_x,sample_points_y,sample_points_z]  = ...
                    interpolate_stacks_for_straightening(trigger_stack,channel_images,img, new_sample_points_x, new_sample_points_y,midline, ...
                                    new_z_size, AP_padd_size)
%
%
%
%   INPUT ARGS:
%
%   GPU_option is a flag, if zero, normal interpolation on the CPU is used,
%   if 1, the graphics card is used, this options needs CUDA installed and
%   setup for with MATLAB, doesn't work on MacOS Mojave or higher
%
%   AP_padd_size is an optional argument, specifies the size of the stack
%   along the AP axis of the worm, longer stacks are cut, shorter stacks
%   are padded with zeros
%
%   noise_param ... 2x(no_channels) vector with mean and variance of the noise that is
%   used to fill the zeros in the images
%   first row is for trigger_channel, next rows are for remaining channels
%
%
%
%   Wolfgang Keil, Institut Curie 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   no_channel2straighten = size(channel_images,4);
   
     %%% This happens, if the positions doesn't contain a worm, in this case, just fill a matrix with appropriate noise                           
    if isempty(midline)
        
        straightened_trigger = [];
        straightened_channels = [];
    else
        
        sample_points_x  = zeros(2*new_z_size+1, size(new_sample_points_x,1),size(new_sample_points_x,2));
        sample_points_y  = zeros(2*new_z_size+1, size(new_sample_points_x,1),size(new_sample_points_x,2));

        % this generates 
        for jj = 1:size(new_sample_points_x,2) % loop goes along the midline
           sample_points_x(:,:,jj) = repmat(new_sample_points_x(:,jj)',[2*new_z_size+1,1]);
           sample_points_y(:,:,jj) = repmat(new_sample_points_y(:,jj)',[2*new_z_size+1,1]);
        end

        % This generates the z-array, take the first z-center of the midline
        % for all points
        sample_points_z  = repmat([-new_z_size:new_z_size]',[1,size(new_sample_points_x,1)]) + midline(1,3);
        sample_points_z  = repmat(sample_points_z,[1,1,size(new_sample_points_x,2)]);


        %2. setup grids for interpolation of the stack
        [x_size,y_size,z_size] = size(trigger_stack);
        [X,Y,Z] = meshgrid(0:(y_size-1),0:(x_size-1), 0:(z_size-1));

        % now interpolate the trigger image at the positions
        % do it blockwise, because otherwise, images might not fit into the graphics
        % card, 10 blocks is save
        no_blocks = 20;
        blocks = round(linspace(1,size(sample_points_x,3),no_blocks+1));

        for ii  = 1:length(blocks)-1
            iind = blocks(ii):blocks(ii+1);
            straightened_trigger(:,:,iind) = interp3(X,Y,Z,double(trigger_stack),...
                               sample_points_y(:,:,iind),sample_points_x(:,:,iind),...
                               sample_points_z(:,:,iind),'nearest', 0);         
        end

       straightened_channels = [];
       % straightened_channels = zeros(size(channel_images));
        for kk=1:no_channel2straighten
            current_channel  = squeeze(channel_images(:,:,:,kk));
            %interpolate in blocks
            for ii  = 1:length(blocks)-1
                iind = blocks(ii):blocks(ii+1);
                straightened_channels(:,:,iind,kk) = interp3(X,Y,Z,double(current_channel),...
                               sample_points_y(:,:,iind),sample_points_x(:,:,iind),...
                               sample_points_z(:,:,iind), 'nearest', 0);         
            end
        end
        
 
        % permute indices because after interpolation they are in wrong order
        straightened_trigger = permute(straightened_trigger, [2 3 1]);
        straightened_channels = permute(straightened_channels, [2 3 1 4]);

        sample_points_x = permute(sample_points_x,[2,3,1]);
        sample_points_y = permute(sample_points_y,[2,3,1]);
        sample_points_z = permute(sample_points_z,[2,3,1]);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        sample_points_x(straightened_trigger==0) =0;
        sample_points_y(straightened_trigger==0) =0;
        sample_points_z(straightened_trigger==0) =0;
        
        if nargin > 7
            % CROP/PAD stacks to desired size      
            [straightened_trigger, straightened_channels,...
                sample_points_x,sample_points_y,sample_points_z] = crop_and_pad(straightened_trigger, straightened_channels, ...,
                        sample_points_x,sample_points_y,sample_points_z,AP_padd_size);     
        end
        % Add noise to the zeros of the stacks, facilitates some of the
        % analysis
        [straightened_trigger, straightened_channels] = add_noise_to_stacks(trigger_stack, channel_images,img,straightened_trigger,straightened_channels);
    end
end
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%% USED FUNCTIONS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [straightened_trigger, straightened_channels,...
        sample_points_x,sample_points_y,sample_points_z] = crop_and_pad(straightened_trigger, straightened_channels, ...
                sample_points_x,sample_points_y,sample_points_z,AP_padd_size)
    
    if size(straightened_trigger,2) > AP_padd_size
        % Crop
        twocrop = size(straightened_trigger,2) - AP_padd_size;  

        straightened_trigger = straightened_trigger(:,ceil(twocrop/2):(size(straightened_trigger,2)-floor(twocrop/2)),  :);
        straightened_channels = straightened_channels(:,ceil(twocrop/2):(size(straightened_channels,2)-floor(twocrop/2)),  :,:);

        sample_points_x = sample_points_x(:,ceil(twocrop/2):(size(straightened_trigger,2)-floor(twocrop/2)),  :);
        sample_points_y = sample_points_y(:,ceil(twocrop/2):(size(straightened_trigger,2)-floor(twocrop/2)),  :);
        sample_points_z = sample_points_z(:,ceil(twocrop/2):(size(straightened_trigger,2)-floor(twocrop/2)),  :);

    elseif size(straightened_trigger,2) < AP_padd_size
        %padd
        twopadd = AP_padd_size - size(straightened_trigger,2);   

        tmp = zeros(size(straightened_trigger,1), AP_padd_size, size(straightened_trigger,3));
        tmp(:,ceil(twopadd/2):(ceil(twopadd/2)+size(straightened_trigger,2))-1,:) = straightened_trigger;
        straightened_trigger = tmp;      
        
        tmp = zeros(size(straightened_channels,1), AP_padd_size, size(straightened_channels,3),size(straightened_channels,4));
        tmp(:,ceil(twopadd/2):(ceil(twopadd/2)+size(straightened_channels,2))-1,:,:) = straightened_channels;
        straightened_channels = tmp;
        
        %%% Also padd the sample_points, with NaNs
        tmp = zeros(size(sample_points_x,1), AP_padd_size, size(sample_points_x,3))*NaN;
        tmp(:,ceil(twopadd/2):(ceil(twopadd/2)+size(sample_points_x,2))-1,:) = sample_points_x;
        sample_points_x = tmp;
        
        tmp = zeros(size(sample_points_y,1), AP_padd_size, size(sample_points_y,3))*NaN;
        tmp(:,ceil(twopadd/2):(ceil(twopadd/2)+size(sample_points_y,2))-1,:) = sample_points_y;
        sample_points_y = tmp;
        
        tmp = zeros(size(sample_points_z,1), AP_padd_size, size(sample_points_z,3))*NaN;
        tmp(:,ceil(twopadd/2):(ceil(twopadd/2)+size(sample_points_z,2))-1,:) = sample_points_z;
        sample_points_z = tmp;
          
        
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [straightened_trigger, straightened_channels, noise_params] ...
                    = add_noise_to_stacks(trigger_stack, channel_images,img,straightened_trigger,straightened_channels)
    % Add noise with appropriate mean and variance to the zeros within the
    % stacks
    trigger_stack = double(trigger_stack);
    % Estimate the noise magnitude
    noise_param = zeros(2,size(channel_images,4)+1);

    img = repmat(img, [1,1,size(trigger_stack,3)]);
    iind = (img==0) & trigger_stack>0;
    trigger_noise = trigger_stack(iind);

    noise_param(1,1) = mean(trigger_noise);
    noise_param(2,1) = std(trigger_noise);

    for kk=1:size(channel_images,4)
        tmp = double(channel_images(:,:,:,kk));
        nn = tmp(iind);
        noise_param(1,kk+1) = mean(nn);
        noise_param(2,kk+1) = std(nn);

    end        


    % Fill the zeros in the images with a noise that corresponds to the
    % noise in the images
    iind = find(straightened_trigger == 0);
    straightened_trigger(iind) = noise_param(1,1) + randn(1,length(iind))*sqrt(noise_param(2,1));

    for kk=1:size(channel_images,4)
        tmp = straightened_channels(:,:,:,kk);
        tmp(iind) = noise_param(1,kk+1) + randn(1,length(iind))*sqrt(noise_param(2,kk+1));
        straightened_channels(:,:,:,kk) = tmp;

    end
end



clc;
clear all;
close all;

% Input Variable Parameters
threshold_greyscale = 50; % Greyscale Threshold
threshold_bgsub = 0.13; % Background Subtraction Threshold
mean_over = 100; % no. of frames used for creating the first background frame
alpha_min = 0.7; % Minimum value of alpha to be set
% Dataset Path (Dataset from changedetection.net)
dataset_path = 'D:\\Education\\Project\\Results\\Testing\\dataset\\'; 

% Choosing a Dataset or Video from a location
dataset = 1; % Default Value (Yes)
prompt = ('From Dataset (1 for yes and 0 for no)');
dataset = input(strcat(prompt,'\n ='));

%Dataset Condition
if dataset
    % Dataset Location
    baseline = {'baseline','highway','pedestrians'};
    dynamic_background = {'dynamic background','canoe','fountain01'};
    camera_jitter = {'camera jitter','badminton','sidewalk'};
    intermittent_object_motion = {'intermittent','sofa','winterDriveway'};
    lowframerate = {'low framerate','turnpike_0_5fps','dummy'};
    nightvideos = {'night videos','fluidHighway','dummy'};
    env = [baseline;dynamic_background;camera_jitter;intermittent_object_motion;lowframerate;nightvideos]
    prompt = ' Dataset Type(1st Prompt), Dataset Name(2nd Prompt)';
    d_choice = input(strcat(prompt,'\n =')); % dataset choice
    e_choice = input(' =') + 1; % environment choice


    % Defining Begin and End Iter Based on Temporal ROI
    fid = fopen(sprintf(char(strcat(dataset_path,env(d_choice,1),'\\',env(d_choice,e_choice),'\\temporalROI.txt'))));
    tmp_var = fscanf(fid,'%d %d');
    no_of_images = tmp_var(2); % no. of frames over which the operation is to be performed
    fclose(fid);

    path_1 = sprintf(char(strcat(dataset_path,env(d_choice,1),'\\',env(d_choice,e_choice),'\\input\\in%06d.jpg')),1);
    tmp = double(rgb2gray(imread(path_1)));
    [y_res,x_res] = size(tmp); % Y and X resolution
    for n=2:mean_over
        path_1 = sprintf(char(strcat(dataset_path,env(d_choice,1),'\\',env(d_choice,e_choice),'\\input\\in%06d.jpg')),n);
        tmp = tmp + double(rgb2gray(imread(path_1)));
    end
    % Path for writing the mean image
    path_1 = sprintf(char(strcat(dataset_path,env(d_choice,1),'\\',env(d_choice,e_choice),'\\FuzzyRunningAverage\\fuzzyrunningaverage%06d.png')),mean_over);

% Video location condition
else
    prompt = ' Enter the location of Video (forward slash only)';
    v_loc = input(strcat(prompt,'\n = '),'s'); % Location of video
    ip_v_obj = VideoReader(v_loc);
    no_of_images = ip_v_obj.NumberOfFrames;
    %no_of_images = 100;
    y_res = ip_v_obj.Height;
    x_res = ip_v_obj.Width;
    tmp = zeros(y_res,x_res); % Temp Matrix
    for n=1:mean_over
        tmp = tmp + double(rgb2gray(read(ip_v_obj,n)));
    end
    % Path for writing the mean image
    path_1 = strcat(v_loc(1:end-3),'png');
end

% Division of the sum over number of frames
tmp=tmp./mean_over;
imwrite(uint8(tmp),path_1,'PNG');

% Video Object
if dataset
    path_1 = strcat(path_1(1:end-3),'avi');
else
    path_1 = strcat(path_1(1:end-4),'_info.avi');
end
aviobj=VideoWriter(path_1);
open(aviobj);
path_1 = strcat(path_1(1:end-4),'%06d.png');

% Matrix Parameters
fbgs = zeros(y_res,x_res); % Fuzzy Background Subtraction
bgs = zeros(y_res,x_res); % Background Subtraction
alpha = zeros(y_res,x_res); % Parameter used in the equation of Background Frame generation
filter_kernel = [[0.075,0.15,0.075];[0.15,0.225,0.15];[0.075,0.15,0.075]]; % Filter Kernel

for n=1:no_of_images
% Algorithm for Background updation in Fuzzy Running Average
% Parameters used in the algorithm
% tmp(input) -> BG(t-1)
% tmp(output) -> BG(t)
% tmp_img -> I(t)
  if dataset
    path_2 = sprintf(char(strcat(dataset_path,env(d_choice,1),'\\',env(d_choice,e_choice),'\\input\\in%06d.jpg')),n);
    tmp_img = double(rgb2gray(imread(path_2)));
  else
    tmp_img = double(rgb2gray(read(ip_v_obj,n)));
  end
  
  if (n ~= 1)     
    for i=1:y_res
          for j=1:x_res	
        % alpha generation
            alpha(i,j) = (1 - alpha_min)*exp(-5*fbgs(i,j));	
        % Background Frame generation
            tmp(i,j) = alpha(i,j)*tmp(i,j) + (1 - alpha(i,j))*tmp_img(i,j);
          end
    end
  end
    
  for i=1:y_res
      for j=1:x_res
	% FBGS generation
        if abs(tmp(i,j)-tmp_img(i,j)) > threshold_greyscale
            fbgs(i,j) = 1;
        else
            fbgs(i,j) = abs(tmp_img(i,j)-tmp(i,j))/threshold_greyscale;
        end
      end
  end
  
  fbgs = filter2(filter_kernel,fbgs);
  
  for i=1:y_res
      for j=1:x_res
    % BGS generation
        if (fbgs(i,j)) > threshold_bgsub
            bgs(i,j) = 255;
        else
            bgs(i,j) = 0;
        end
      end
  end
  
% Adding frame to video object
  writeVideo(aviobj,uint8(bgs));
 if dataset
     imwrite(uint8(bgs),sprintf(char(strcat(dataset_path,env(d_choice,1),'\\',...
         env(d_choice,e_choice),'\\FuzzyRunningAverage\\bin%06d.png')),n),'PNG');
 else
     sprintf(path_1,n)
     tmp_var = sprintf(path_1,n);
     imwrite(uint8(bgs),tmp_var);
 end 
end

close(aviobj);



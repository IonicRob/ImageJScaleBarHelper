%% Image Scale Bar Ratio Calculator
% By Robert J Scales Feb 2021
clc
clear

cd_code = cd;

disp('Started: Image Scale Bar Ratio Calculator');

%% User Settings

% This is the time for which the code waits after opening a dialogue box to
% then close it.
waittime = 2;

% Enter in '' if you want to use the current folder where this code is
% running from, otherwise copy the folder location into
% cd_StartFolderLocation.
cd_StartFolderLocation = '';

% Using ImageJ find, the settings which appeal to you an image for the
% scale bar, then copy down that image's width and height, and then all of
% the parameters used to generate the scale bar.
Calib_Width = 2048; % In pixels
Calib_Height = 1536; % In pixels
Calib_FontSize = 75; % Font size that matches calib width and height
Calib_LineHeight = 8; % Thickness of scale bar that matches calib width and height
Calib_ScaleBarWidth = 0.2290*1000; % pixels/nm * width in nm Length of scale bar in pixels that matches calib width and height

%% Ratio Calculations

Ratio_FontSize = Calib_FontSize/Calib_Height;
Ratio_LineHeight = Calib_LineHeight/Calib_Height;
Ratio_ScaleBarWidth = Calib_ScaleBarWidth/Calib_Width;

%% Loading Files

if isempty(cd_StartFolderLocation)
    cd_StartFolderLocation = cd_code;
end

cd(cd_StartFolderLocation);
filter = '*.tif';
[files,path] = uigetfile(filter,'MultiSelect','on');
filenames = string(files);
fullfiles = string(fullfile(path,files));
cd(cd_code);

if isa(files,'char') % If one file is selected it will be loaded in as a char and not a cell.
    files = cellstr(files);
end

%% Main Section
clc

% Cycles for each file loaded
for i = 1:length(fullfiles)
    filename = fullfiles(i);
    
    message = sprintf('Current Image = %s\n',files{i});
    disp(message);
    f = msgbox(message,'Output','help');
    popup(waittime,f)
    
    % Gets image information
    info = imfinfo(filename);
    Input_Width = info.Width;
    Input_Height = info.Height;
    
    % Loads image in as a table
    Matrix = readtable(filename,'FileType','text','ReadVariableNames',false);
    ImageTable = table2cell(Matrix);
    clear Matrix
    
    % Tries to search for Image Pixel Size tag stored in Zeiss tif image
    % files.
    row_IPS = strcmp(ImageTable(:,1),'Image Pixel Size');
    if sum(row_IPS) % If that tag can be found it does the following.
        IPS = sprintf('%s/pixel',string(ImageTable(row_IPS==1,2)));
        IPS_Value = extractBefore(IPS,' ');
        IPS_Value =  str2double(IPS_Value);
        IPS_Unit = extractAfter(IPS,' ');
        IPSUnit_Num = extractBefore(IPS_Unit,'/');
        IPSUnit_Den = extractAfter(IPS_Unit,'/');
    elseif isfield(info,'XResolution') % If the tag CANNOT be found it does the following.
        IPS_Value = (info.XResolution/10^4)^-1;
        IPSUnit_Num = 'um';
        IPSUnit_Den = 'pixel';
    else
        pop = warndlg('Code cannot interpret metadata');
    end
    
    % This is used to confirm to the user what the image's scale is
    message = sprintf('Scale for ImageJ = %s %s/%s\nOR %s %s/%s\n',string(1/IPS_Value),IPSUnit_Den,IPSUnit_Num,string(IPS_Value),IPSUnit_Num,IPSUnit_Den);
    disp(message);
    f = msgbox(message,'Output','help');
    popup(waittime,f)
    
    % If the image's scale will produce something like a scale bar of over
    % 1000 in units, then it does this alternative scale which then means
    % it should be < 1000 in the new units.
    if 1/IPS_Value < 1
        fprintf('___ALTERNATIVE___\n');
        first_value = (1/IPS_Value)*10^3;
        second_value = 1/((1/IPS_Value)*10^3);
        message = sprintf('Scale for ImageJ = %s %s/(%s*10^3)\nOR %s (%s*10^3)/%s\n',string(first_value),IPSUnit_Den,IPSUnit_Num,string(second_value),IPSUnit_Num,IPSUnit_Den);
        disp(message);
        f = msgbox(message,'Output','help');
        popup(waittime,f)
    end
    
    % Works out the new scale bar in pixel width and then in unit width.
    NewSBWinPixels = Ratio_ScaleBarWidth*Input_Width; % In pixels
    NewSBWinUnit = NewSBWinPixels*IPS_Value;

    % These are the recommended parameters for the scale bar for that
    % image.
    Output_FontSize = string(round(Ratio_FontSize*Input_Height,0));
    Output_LineHeight = string(round(Ratio_LineHeight*Input_Height,0)); 
    Output_ScaleBarWidth = string(round(NewSBWinUnit,0));
    
    message = sprintf('Rec. Width in %s = %s\nRec. Height in Pixels = %s\nRec. Font Size = %s',IPSUnit_Num,Output_ScaleBarWidth,Output_LineHeight,Output_FontSize);
    disp(message);
    f = msgbox(message,'Output','help');
    popup(waittime,f)

    fprintf('----------------------------------------------------------\n');
end

disp('Finished: Image Scale Bar Ratio Calculator');
%% Other Functions

function popup(waittime,f)
    pause(waittime);
    try
        close(f);
    catch
        fprintf('Pop up already closed\n')
    end
end
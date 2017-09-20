close all
clear all

%% WELCOME
%helpdlg('Please select the .DTA files of all the electrodes of a single implant','ZEUS 0.1')
%% IMPORT FILES
[importedFiles, pathName] = uigetfile({'*.DTA'},'MultiSelect','on');
if iscell(importedFiles)
    loopSize = size(importedFiles,2); %getfile has returned >1 files sorted in a cell array
else
    loopSize = 1; %getfile has return 1 file, fileNameArray = 1xstringLength
end

%% INIT DATA BASE
fileNameArray = [];
implantIDArray = [];
electrodeIDArray = [];
voltageArray = [];
currentArray = [];
timeArray = [];
chargeStorageCapacity = 0;

%% LOOP THROUGH IMPORTED FILES
for i=1:1:loopSize
    
    % EXTRACT DATA
    if iscell(importedFiles)
        fileNameArray = [fileNameArray; strjoin(importedFiles(i))]; %strjoin converts cell type into string
    else
        fileNameArray = [importedFiles]; %getfile has only returned 1 file whose name is already a string
    end
    fileName = fileNameArray(i,:)
    indexOfImplantID = strfind(fileName,'W');
    implantID = fileName(indexOfImplantID:indexOfImplantID+9);
    implantIDArray = [implantIDArray; implantID];
    electrodeID = fileName(indexOfImplantID+11:indexOfImplantID+12);
    electrodeIDArray = [electrodeIDArray; electrodeID];
    voltageArray = importVoltage(fileName);
    voltageArray = voltageArray(~isnan(voltageArray)); %remove NaN values
    currentArray = importCurrent(fileName);
    currentArray = currentArray(~isnan(currentArray));
    timeArray = importTime(fileName);
    timeArray = timeArray(~isnan(timeArray));
%     i = 2;
%     % first 3 segments of the curve
%     while voltageArray(i) > 0 || (voltageArray(i+1)-voltageArray(i)) < 0
%         chargeStorageCapacity = chargeStorageCapacity + (currentArray(i+1)+currentArray(i))/2*(timeArray(i+1)-timeArray(i));
%         i = i+1;
%     end
    minVoltageIndex = find(voltageArray == min(voltageArray));
    maxVoltageIndex = find(voltageArray == max(voltageArray));
    i = minVoltageIndex(1);
    %last segment of the curve
    while i < minVoltageIndex(2)
        chargeStorageCapacity = chargeStorageCapacity + (currentArray(i+1)+currentArray(i))/2*(timeArray(i+1)-timeArray(i));
        i = i+1;
    end
    i
    
end
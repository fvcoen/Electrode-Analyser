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
warning('off','MATLAB:print:FigureTooLargeForPage')
warning('off','MATLAB:xlswrite:AddSheet')

%% LOOP THROUGH IMPORTED FILES
for n=1:1:loopSize
    
    % EXTRACT DATA
    if iscell(importedFiles)
        fileNameArray = [fileNameArray; strjoin(importedFiles(n))]; %strjoin converts cell type into string
    else
        fileNameArray = [importedFiles]; %getfile has only returned 1 file whose name is already a string
    end
    fileName = fileNameArray(n,:)
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
    
    chargeStorageCapacityArray = [];
    chargeStorageCapacityRow = [];
    chargeStorageCapacityTemp = 0;
    chargeStorageCapacity = [];
    phase1Edges = [];
    phase2Edges = [];
    phase3Edges = [];
    phase4Edges = [];
    curveNames = [];
    CVPlotAll = figure;
    i = 2;
    
    % Sort data in 4 phases and compute charge storage capacity
    while i < size(voltageArray,1)
        % Phase 1: voltage positive, voltage slope positive
        start = i;
        while i < size(voltageArray,1) && voltageArray(i) > 0 && (voltageArray(i) - voltageArray(i-1)) > 0
            chargeStorageCapacityTemp = chargeStorageCapacityTemp + abs(trapz(timeArray(i-1:i), currentArray(i-1:i))/(voltageArray(i)-voltageArray(i-1)));
            i = i+1;
        end
        phase1Edges = [phase1Edges; start i-1];
        chargeStorageCapacityRow  = [chargeStorageCapacityRow chargeStorageCapacityTemp];
        chargeStorageCapacityTemp = 0;
        % Phase 2: voltage positive, voltage slope negative
        start = i;
        while i < size(voltageArray,1) && voltageArray(i) > 0 && (voltageArray(i) - voltageArray(i-1)) < 0
            chargeStorageCapacityTemp = chargeStorageCapacityTemp + abs(trapz(timeArray(i-1:i), currentArray(i-1:i))/(voltageArray(i)-voltageArray(i-1)));
            i = i+1;
        end
        phase2Edges = [phase2Edges; start i-1];
        chargeStorageCapacityRow = [chargeStorageCapacityRow chargeStorageCapacityTemp];
        chargeStorageCapacityTemp = 0;
        % Phase 3: voltage negative, voltage slope negative
        start = i;
        while i < size(voltageArray,1) && voltageArray(i) < 0 && (voltageArray(i) - voltageArray(i-1)) < 0
            chargeStorageCapacityTemp = chargeStorageCapacityTemp + abs(trapz(timeArray(i-1:i), currentArray(i-1:i))/(voltageArray(i)-voltageArray(i-1)));
            i = i+1;
        end
        phase3Edges = [phase3Edges; start i-1];
        chargeStorageCapacityRow = [chargeStorageCapacityRow chargeStorageCapacityTemp];
        chargeStorageCapacityTemp = 0;
        % Phase 4: voltage negative, voltage slope positive
        start = i;
        while i < size(voltageArray,1) && voltageArray(i) < 0 && (voltageArray(i) - voltageArray(i-1)) > 0
            chargeStorageCapacityTemp = chargeStorageCapacityTemp + abs(trapz(timeArray(i-1:i), currentArray(i-1:i))/(voltageArray(i)-voltageArray(i-1)));
            i = i+1;
        end
        phase4Edges = [phase4Edges; start i-1];
        chargeStorageCapacityRow = [chargeStorageCapacityRow chargeStorageCapacityTemp];
        chargeStorageCapacityTemp = 0;
        
        chargeStorageCapacityArray = [chargeStorageCapacityArray; chargeStorageCapacityRow];
        chargeStorageCapacityRow = [];
    end
    
    for j=1:1:size(phase1Edges,1)
        
        % Generate and display individual CV plot
        figure
        plot(voltageArray(phase1Edges(j,1):phase4Edges(j,2)), 10^6.*currentArray(phase1Edges(j,1):phase4Edges(j,2)),'LineWidth',2.5)
        grid on
        curveNames = [curveNames; replace(strcat('Curve_',num2str(j)),'_',' ')];
        legend(curveNames(j,:))
        xlabel('Voltage [V]')
        ylabel('Current [\muA]')
        title(replace(strcat('Cyclic Voltametry_',implantIDArray(n,:),'_',electrodeIDArray(n,:)),'_',' '))
        CVPlot2 = gcf;
        CVPlot2.PaperPositionMode = 'auto';
        CVPlot2_pos = CVPlot2.PaperPosition;
        CVPlot2.PaperSize = [CVPlot2_pos(3) CVPlot2_pos(4)];
        titleCVPlotFile = strcat(implantIDArray(n,:),'_',electrodeIDArray(n,:),'_Curve_',num2str(j),'_CV_plot','.pdf');
        saveas(gcf,titleCVPlotFile)
        
        %Populate global CV plot
        figure(CVPlotAll)
        plot(voltageArray(phase1Edges(j,1):phase4Edges(j,2)), 10^6.*currentArray(phase1Edges(j,1):phase4Edges(j,2)),'LineWidth',2.5)
        hold on
        
        % Compute and save Charge Storage Capacity in .txt file
        chargeStorageCapacity = [chargeStorageCapacity; sum(chargeStorageCapacityArray(j,:),2)];
        if n == 1 && j == 1 % First curve of the first electrode is responsible for creating the file
            fid = fopen(strcat(implantIDArray(1,:),'_CSC','.txt'),'wt+');
            fprintf(fid,'\t \t \t \t \t \t Charge Storage Capacity [mF]\n');
            fprintf(fid, '%s_%s %s\t %f\t \n',implantID,electrodeID,curveNames(j,:),10^3.*chargeStorageCapacity(j));
        else
            fid = fopen(strcat(implantIDArray(1,:),'_CSC','.txt'),'at+');
            fprintf(fid, '%s_%s %s\t %f\t \n',implantID,electrodeID,curveNames(j,:),10^3.*chargeStorageCapacity(j));
        end
        if j == size(phase1Edges,1) % Last curve of each electrode is responsible for creating the avg and var
            fid = fopen(strcat(implantIDArray(1,:),'_CSC','.txt'),'at+');
            fprintf(fid, '______________________________________________________________\n');
            fprintf(fid, '%s_%s Average\t %f\t Variance\t %e\n',implantID,electrodeID,10^3*mean(sum(chargeStorageCapacityArray,2)),var(sum(chargeStorageCapacityArray,2)));
            fprintf(fid, '______________________________________________________________\n');
        end
    end
    
    % Display global CV plot
    figure(CVPlotAll)
    grid on
    legend(curveNames)
    xlabel('Voltage [V]')
    ylabel('Current [\muA]')
    title(replace(strcat('Cyclic Voltametry_',implantIDArray(n,:),'_',electrodeIDArray(n,:)),'_',' '))
    CVPlot = gcf;
    CVPlot.PaperPositionMode = 'auto';
    CVPlot_pos = CVPlot.PaperPosition;
    CVPlot.PaperSize = [CVPlot_pos(3) CVPlot_pos(4)];
    titleCVPlotFile = strcat(implantIDArray(n,:),'_',electrodeIDArray(n,:),'_CV_plot','.pdf');
    saveas(gcf,titleCVPlotFile)
    
    % Display global CV plot 2
    figure
    grid on
    title(replace(strcat('Cyclic Voltametry_',implantIDArray(n,:),'_',electrodeIDArray(n,:)),'_',' '))
    yyaxis left
    plot(timeArray,voltageArray,'LineWidth',2.5)
    xlabel('Time [s]')
    ylabel('Voltage [V]')
    
    yyaxis right
    plot(timeArray,currentArray.*10^6,'LineWidth',2.5)
    ylabel('Current [\muA]')
    CVPlot2 = gcf;
    CVPlot2.PaperPositionMode = 'auto';
    CVPlot2_pos = CVPlot2.PaperPosition;
    CVPlot2.PaperSize = [CVPlot2_pos(3) CVPlot2_pos(4)];
    titleCVPlot2File = strcat(implantIDArray(n,:),'_',electrodeIDArray(n,:),'_CV_plot2','.pdf');
    saveas(gcf,titleCVPlot2File)
    
    
    %% GENERATE .xlsx FILE
    xlsxFile = strcat(implantIDArray(1,:),'.xlsx');
    dataTable = table(timeArray, voltageArray, currentArray,'VariableNames',{'Time' 'Voltage' 'Current'});
    writetable(dataTable, xlsxFile, 'Sheet',electrodeIDArray(n,:))


end
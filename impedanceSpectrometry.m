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
zModulusArray = [];
zPhaseArray = [];
implantModulusPlot = figure;
implantPhasePlot = figure;

%% LOOP THROUGH IMPORTED FILES
for i=1:1:loopSize
    
    %% EXTRACT DATA
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
    frequency = str2double(importFrequency(fileName)); %frequency is stored as a string in data file
    zModulus = importZMod(fileName);
    zModulusArray = [zModulusArray zModulus];
    zPhase = importZPhz(fileName);
    zPhaseArray = [zPhaseArray zPhase];
    
    %% SAVE IMPEDANCE AT 1kHz
    if i == 1
        fid = fopen(strcat(implantIDArray(1,:),'_impedance_1kHz','.txt'),'wt+'); %create txt file
        fprintf(fid,'\t \t Frequency [Hz]\t Impedance [Ohm]\n'); %init txt layout
        fprintf(fid, '%s_%s\t %f.3\t %f.2\n',implantID,electrodeID,frequency(frequency==998.2640),zModulus(frequency==998.2640));
    else
        fid = fopen(strcat(implantIDArray(1,:),'_impedance_1kHz','.txt'),'at+');
        fprintf(fid, '%s_%s\t %f.3\t %f.2\n',implantID,electrodeID,frequency(frequency==998.2640),zModulus(frequency==998.2640));
    end
    %% GENERATE BODE PLOTE
    titleModulusPlot = replace(strcat('Impedance Modulus_',implantID),'_',' '); %workaround because strcat ignores trailing white space
    titleModulusPlotFile = strcat(implantID,'_',electrodeID,'_impedance_modulus','.pdf');
    figure
    semilogx(frequency,zModulus./10^3,'LineWidth',2.5)
    grid on
    legend(electrodeID)
    xlabel('Frequency [Hz]')
    ylabel('Modulus [k\Omega]')
    title(titleModulusPlot)
    modulusPlot = gcf;
    modulusPlot.PaperPositionMode = 'auto';
    modulusPlot_pos = modulusPlot.PaperPosition;
    modulusPlot.PaperSize = [modulusPlot_pos(3) modulusPlot_pos(4)];
    saveas(gcf,titleModulusPlotFile)
    
    figure(implantModulusPlot)
    semilogx(frequency,zModulus./10^3,'LineWidth',2.5)
    hold on
    
    titlePhasePlot = replace(strcat('Impedance Phase_',implantID),'_',' '); %workaround because strcat ignores trailing white space
    titlePhasePlotFile = strcat(implantID,'_',electrodeID,'_impedance_phase','.pdf');
    figure
    semilogx(frequency,zPhase,'LineWidth',2.5)
    grid on
    legend(electrodeID)
    xlabel('Frequency [Hz]')
    ylabel('Phase [deg]')
    title(titlePhasePlot)
    phasePlot = gcf;
    phasePlot.PaperPositionMode = 'auto';
    phasePlot_pos = phasePlot.PaperPosition;
    phasePlot.PaperSize = [phasePlot_pos(3) phasePlot_pos(4)];
    saveas(gcf,titlePhasePlotFile)
    
    figure(implantPhasePlot)
    semilogx(frequency,zPhase,'LineWidth',2.5)
    hold on
end
fclose(fid);

%% GENERATE BODE PLOT FOR ENTIRE IMPLANT
figure(implantModulusPlot)
grid on
legend(electrodeIDArray)
xlabel('Frequency [Hz]')
ylabel('Modulus [k\Omega]')
title(replace(strcat('Impedance Modulus_',implantIDArray(1,:)),'_',' '))
implantModulusPlot.PaperPositionMode = 'auto';
implantModulusPlot_pos = implantModulusPlot.PaperPosition;
implantModulusPlot.PaperSize = [implantModulusPlot_pos(3) implantModulusPlot_pos(4)];
titleImplantModulusPlotFile = strcat(implantIDArray(1,:),'_full_impedance_modulus','.pdf');
saveas(gcf,titleImplantModulusPlotFile)

figure(implantPhasePlot)
grid on
legend(electrodeIDArray)
xlabel('Frequency [Hz]')
ylabel('Phase [deg]')
title(replace(strcat('Impedance Phase_',implantIDArray(1,:)),'_',' '))
implantPhasePlot.PaperPositionMode = 'auto';
implantPhasePlot_pos = implantPhasePlot.PaperPosition;
implantPhasePlot.PaperSize = [implantPhasePlot_pos(3) implantPhasePlot_pos(4)];
titleImplantPhasePlotFile = strcat(implantIDArray(1,:),'_full_impedance_phase','.pdf');
saveas(gcf,titleImplantPhasePlotFile)

%% GENERATE .xlsx FILE
xlsxFile = strcat(implantIDArray(1,:),'.xlsx')
for i=1:1:loopSize
    dataTable = table(frequency, zModulusArray(:,i), zPhaseArray(:,i),'VariableNames',{'Frequency' 'Modulus' 'Phase'})
    writetable(dataTable, xlsxFile, 'Sheet',electrodeIDArray(i,:))
end




clc;clear all;
files = {'raw_data.txt','data.txt'};
for i=1:numel(files)
  plotData(files{i},figure(i));
end
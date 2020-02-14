clc;clear all;
x = [-40,-30,-20,-10,-5,0];
files = arrayfun(@(x)sprintf('data_%ddb_snr.txt',x),x,'Un',0);
for i=1:numel(files)
  plotData(files{i},figure(i));
end
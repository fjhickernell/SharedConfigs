function [] = Ch94Run1FacDesPlot(x,fname)
y = 0;

p = figure;
h = plot(x,y,'sk');
set(h,'LineWidth',6);
set(gca,'FontSize',24);
set(gca,'PlotBoxAspectRatio',[350 1 1]);
set(gca,'Box','Off');
set(gca,'XTick',[0 0.5 1]);
set(gca,'XLim',[0 1]);

print('-deps2',fname); 
close(p);

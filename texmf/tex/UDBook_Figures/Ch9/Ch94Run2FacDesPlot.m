function [] = Ch94Run2FacDesPlot(x,fname)

p = figure;

h = plot(x(1,:),x(2,:),'sk');
set(h,'LineWidth',6);
set(gca,'FontSize',24);
set(gca,'XTick',[0 0.5 1]);
set(gca,'YTick',[0 0.5 1]);
set(gca,'XLim',[0 1]);
set(gca,'YLim',[0 1]);
axis square;

print('-deps2',fname); 
close(p);

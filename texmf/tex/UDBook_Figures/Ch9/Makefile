TARGET1FAC = Ch94Run1FacDes1.eps Ch94Run1FacDes2.eps Ch94Run1FacDes3.eps Ch94Run1FacDes4.eps Ch94Run1FacDes5.eps
TARGET2FAC = Ch94Run2FacDes1.eps Ch94Run2FacDes2.eps Ch94Run2FacDes3.eps Ch94Run2FacDes4.eps

all: build

burn:
	rm *.eps

build: $(TARGET1FAC) $(TARGET2FAC)

$(TARGET1FAC): Ch94Run1FacDesPlot.m
$(TARGET2FAC): Ch94Run2FacDesPlot.m

%.eps: %.m
	matlab < $<

%.view: %.eps
	gv $<

view: $(subst eps,view,$(TARGET1FAC) $(TARGET2FAC))
	
clean:	


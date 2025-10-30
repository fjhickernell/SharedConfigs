#       Makefile for Adobe Palatino [2004-09-06 PSNFSS-v9.2 (WaS)]

#       This is for OS/2 with emTeX/TDS and GNU Make or IBM's nmake;
#   *** asterisks indicate directory names and commands
#       which need to be customized for other systems.

#   *** the TDS root dirctory:
tdsdir= e:\texmf

#   *** where the .vf and .tfm files should go:
vfdir=  $(tdsdir)\fonts\vf\adobe\palatino
tfmdir= $(tdsdir)\fonts\tfm\adobe\palatino

#   *** how to run fontinst:
fi=     tex

all:    ppl pplx installfonts

ppl:
	$(fi) inst
	pltotf pplb8r.pl 
	pltotf pplbi8r.pl
	pltotf pplbo8r.pl
	pltotf pplr8r.pl 
	pltotf pplri8r.pl
	pltotf pplro8r.pl
	vptovf pplb7t.vpl 
	vptovf pplb8c.vpl 
	vptovf pplb8t.vpl 
	vptovf pplbc7t.vpl
	vptovf pplbc8t.vpl
	vptovf pplbi7t.vpl
	vptovf pplbi8c.vpl
	vptovf pplbi8t.vpl
	vptovf pplbo7t.vpl
	vptovf pplbo8c.vpl
	vptovf pplbo8t.vpl
	vptovf pplr7t.vpl 
	vptovf pplr8c.vpl 
	vptovf pplr8t.vpl 
	vptovf pplrc7t.vpl
	vptovf pplrc8t.vpl
	vptovf pplri7t.vpl
	vptovf pplri8c.vpl
	vptovf pplri8t.vpl
	vptovf pplro7t.vpl
	vptovf pplro8c.vpl
	vptovf pplro8t.vpl

pplx:
	$(fi) instx
	pltotf pplbij8r.pl  
	pltotf pplbj8r.pl   
	pltotf pplrc8r.pl   
	pltotf pplrij8r.pl
	vptovf pplb9c.vpl
	vptovf pplb9d.vpl
	vptovf pplb9e.vpl
	vptovf pplb9o.vpl
	vptovf pplb9t.vpl
	vptovf pplbi9c.vpl
	vptovf pplbi9d.vpl
	vptovf pplbi9e.vpl
	vptovf pplbi9o.vpl
	vptovf pplbi9t.vpl
	vptovf pplr9c.vpl
	vptovf pplr9d.vpl
	vptovf pplr9e.vpl
	vptovf pplr9o.vpl
	vptovf pplr9t.vpl
	vptovf pplrc9d.vpl
	vptovf pplrc9e.vpl
	vptovf pplrc9o.vpl
	vptovf pplrc9t.vpl
	vptovf pplri9c.vpl
	vptovf pplri9d.vpl
	vptovf pplri9e.vpl
	vptovf pplri9o.vpl
	vptovf pplri9t.vpl
	

installfonts:
	-mkdir $(vfdir)
	-mkdir $(tfmdir)
	cp -p *.vf $(vfdir)
	cp -p *.tfm $(tfmdir)


clean:  
	-rm *.pl *.vpl ppl*.mtx fpl*.mtx
	
zap:
	rm *.tfm *.vf *.fd
	
realclean: clean zap


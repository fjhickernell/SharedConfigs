#	Makefile for Adobe Utopia [2001-05-26 PSNFSS-v8.2 (WaS)]

#       This is for OS/2 with emTeX/TDS and GNU Make or IBM's nmake;
#   ***	asterisks indicate directory names and commands 
#       which need to be customized for other systems.

#   ***	the TDS root dirctory:
tdsdir=	e:\texmf

#   ***	where the .vf and .tfm files should go:
vfdir=  $(tdsdir)\fonts\vf\adobe\utopia
tfmdir= $(tdsdir)\fonts\tfm\adobe\utopia

#   *** how to run plain TeX:
tex=    tex

all:	tex metrics installfonts
	
tex:
	$(tex) inst

metrics:
	pltotf putb8r.pl 
	pltotf putbi8r.pl
	pltotf putbo8r.pl
	pltotf putr8r.pl 
	pltotf putri8r.pl
	pltotf putro8r.pl
	vptovf putb7t.vpl 
	vptovf putb8c.vpl 
	vptovf putb8t.vpl 
	vptovf putbc7t.vpl
	vptovf putbc8t.vpl
	vptovf putbi7t.vpl
	vptovf putbi8c.vpl
	vptovf putbi8t.vpl
	vptovf putbo7t.vpl
	vptovf putbo8c.vpl
	vptovf putbo8t.vpl
	vptovf putr7t.vpl 
	vptovf putr8c.vpl 
	vptovf putr8t.vpl 
	vptovf putrc7t.vpl
	vptovf putrc8t.vpl
	vptovf putri7t.vpl
	vptovf putri8c.vpl
	vptovf putri8t.vpl
	vptovf putro7t.vpl
	vptovf putro8c.vpl
	vptovf putro8t.vpl
	
installfonts:
	-mkdir $(vfdir)
	-mkdir $(tfmdir)
	cp *.vf $(vfdir)
	cp *.tfm $(tfmdir)

clean:
	-rm *.pl *.vpl *.mtx

realclean: clean
	-rm *tfm *.vf *.fd *.log


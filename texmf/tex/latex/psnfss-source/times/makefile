#	Makefile for Adobe Times [2001-05-26 PSNFSS-v8.2 (WaS)]

#       This is for OS/2 with emTeX/TDS and GNU Make or IBM's nmake;
#   ***	asterisks indicate directory names and commands 
#       which need to be customized for other systems.

#   ***	the TDS root dirctory:
tdsdir=	e:\texmf

#   ***	where the .vf and .tfm files should go:
vfdir=  $(tdsdir)\fonts\vf\adobe\times
tfmdir= $(tdsdir)\fonts\tfm\adobe\times

#   *** how to run fontinst:
fi=     fi-1801

all:	tex metrics installfonts

tex:
	$(fi) inst

metrics:
	pltotf ptmb8r.pl 
	pltotf ptmbi8r.pl
	pltotf ptmbo8r.pl
	pltotf ptmr8r.pl 
	pltotf ptmri8r.pl
	pltotf ptmro8r.pl
	vptovf ptmb7t.vpl 
	vptovf ptmb8c.vpl 
	vptovf ptmb8t.vpl 
	vptovf ptmbc7t.vpl
	vptovf ptmbc8t.vpl
	vptovf ptmbi7t.vpl
	vptovf ptmbi8c.vpl
	vptovf ptmbi8t.vpl
	vptovf ptmbo7t.vpl
	vptovf ptmbo8c.vpl
	vptovf ptmbo8t.vpl
	vptovf ptmr7t.vpl 
	vptovf ptmr8c.vpl 
	vptovf ptmr8t.vpl 
	vptovf ptmrc7t.vpl
	vptovf ptmrc8t.vpl
	vptovf ptmri7t.vpl
	vptovf ptmri8c.vpl
	vptovf ptmri8t.vpl
	vptovf ptmro7t.vpl
	vptovf ptmro8c.vpl
	vptovf ptmro8t.vpl
	
installfonts:
	-mkdir $(vfdir)
	-mkdir $(tfmdir)
	cp *vf $(vfdir)
	cp *tfm $(tfmdir)

clean:
	-rm *pl *mtx *fd

realclean: clean
	-rm *tfm *vf


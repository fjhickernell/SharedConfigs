#	Makefile for Adobe Helvetica [2001-05-26 PSNFSS-v8.2 (WaS)]

#       This is for OS/2 with emTeX/TDS and GNU Make or IBM's nmake;
#   ***	asterisks indicate directory names and commands 
#       which need to be customized for other systems.

#   ***	the TDS root dirctory:
tdsdir=	e:\texmf

#   ***	where the .vf and .tfm files should go:
vfdir=  $(tdsdir)\fonts\vf\adobe\helvetic
tfmdir= $(tdsdir)\fonts\tfm\adobe\helvetic

#   *** how to run fontinst:
fi=     fi-1801

all:	vfs installfonts

vfs:
	$(fi) inst
	pltotf phvb8r.pl  
	pltotf phvb8rn.pl 
	pltotf phvbo8r.pl 
	pltotf phvbo8rn.pl
	pltotf phvr8r.pl  
	pltotf phvr8rn.pl 
	pltotf phvro8r.pl 
	pltotf phvro8rn.pl
	vptovf phvb7t.vpl  
	vptovf phvb7tn.vpl 
	vptovf phvb8c.vpl  
	vptovf phvb8cn.vpl 
	vptovf phvb8t.vpl  
	vptovf phvb8tn.vpl 
	vptovf phvbc7t.vpl 
	vptovf phvbc7tn.vpl
	vptovf phvbc8t.vpl 
	vptovf phvbc8tn.vpl
	vptovf phvbo7t.vpl 
	vptovf phvbo7tn.vpl
	vptovf phvbo8c.vpl 
	vptovf phvbo8cn.vpl
	vptovf phvbo8t.vpl 
	vptovf phvbo8tn.vpl
	vptovf phvr7t.vpl  
	vptovf phvr7tn.vpl 
	vptovf phvr8c.vpl  
	vptovf phvr8cn.vpl 
	vptovf phvr8t.vpl  
	vptovf phvr8tn.vpl 
	vptovf phvrc7t.vpl 
	vptovf phvrc7tn.vpl
	vptovf phvrc8t.vpl 
	vptovf phvrc8tn.vpl
	vptovf phvro7t.vpl 
	vptovf phvro7tn.vpl
	vptovf phvro8c.vpl 
	vptovf phvro8cn.vpl
	vptovf phvro8t.vpl 
	vptovf phvro8tn.vpl

installfonts:
	-mkdir $(vfdir)
	-mkdir $(tfmdir)
	cp *vf $(vfdir)
	cp *tfm $(tfmdir)
clean:
	-rm *pl *mtx *fd

realclean: clean
	-rm *tfm *vf *afm


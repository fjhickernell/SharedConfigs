#	Makefile for Adobe New Century Schoolbook [2003-09-26 PSNFSS-v9.1 (WaS)]

#       This is for OS/2 with emTeX/TDS and GNU Make or IBM's nmake;
#   ***	asterisks indicate directory names and commands 
#       which need to be customized for other systems.

#   ***	the TDS root dirctory:
tdsdir=	e:\texmf

#   ***	where the .vf and .tfm files should go:
vfdir=  $(tdsdir)\fonts\vf\adobe\ncntrsbk
tfmdir= $(tdsdir)\fonts\tfm\adobe\ncntrsbk

#   *** how to run fontinst:
fi=     fi-1801

all:	vfs installfonts

vfs:
	$(fi) inst
	pltotf pncb8r.pl 
	pltotf pncbi8r.pl
	pltotf pncbo8r.pl
	pltotf pncr8r.pl 
	pltotf pncri8r.pl
	pltotf pncro8r.pl
	vptovf pncb7t.vpl 
	vptovf pncb8c.vpl 
	vptovf pncb8t.vpl 
	vptovf pncbc7t.vpl
	vptovf pncbc8t.vpl
	vptovf pncbi7t.vpl
	vptovf pncbi8c.vpl
	vptovf pncbi8t.vpl
	vptovf pncbo7t.vpl
	vptovf pncbo8c.vpl
	vptovf pncbo8t.vpl
	vptovf pncr7t.vpl 
	vptovf pncr8c.vpl 
	vptovf pncr8t.vpl 
	vptovf pncrc7t.vpl
	vptovf pncrc8t.vpl
	vptovf pncri7t.vpl
	vptovf pncri8c.vpl
	vptovf pncri8t.vpl
	vptovf pncro7t.vpl
	vptovf pncro8c.vpl
	vptovf pncro8t.vpl
	
installfonts:
	-mkdir $(vfdir)
	-mkdir $(tfmdir)
	cp *vf $(vfdir)
	cp *tfm $(tfmdir)

clean:
	-rm *pl *mtx

realclean: clean
	-rm *tfm *vf *fd


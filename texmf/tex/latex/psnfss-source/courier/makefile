#	Makefile for Adobe Courier [2003/09/26 PSNFSS-v9.1 (WaS)]

#       This is for OS/2 with emTeX/TDS and GNU Make or IBM's nmake;
#   ***	asterisks indicate directory names and commands 
#       which need to be customized for other systems.

#   ***	the TDS root dirctory:
tdsdir=	e:\texmf

#   ***	where the .vf and .tfm files should go:
vfdir=  $(tdsdir)\fonts\vf\adobe\courier
tfmdir= $(tdsdir)\fonts\tfm\adobe\courier

#   *** how to run fontinst:
fi=     fi-1801

all:	vfs installfonts

vfs:
	$(fi) inst
	pltotf pcrb8r.pl 
	pltotf pcrbo8r.pl
	pltotf pcrr8r.pl 
	pltotf pcrro8r.pl
	vptovf pcrb7t.vpl 
	vptovf pcrb8c.vpl 
	vptovf pcrb8t.vpl 
	vptovf pcrbc7t.vpl
	vptovf pcrbc8t.vpl
	vptovf pcrbo7t.vpl
	vptovf pcrbo8c.vpl
	vptovf pcrbo8t.vpl
	vptovf pcrr7t.vpl 
	vptovf pcrr8c.vpl 
	vptovf pcrr8t.vpl 
	vptovf pcrrc7t.vpl
	vptovf pcrrc8t.vpl
	vptovf pcrro7t.vpl
	vptovf pcrro8c.vpl
	vptovf pcrro8t.vpl
	
installfonts:
	-mkdir $(vfdir)
	-mkdir $(tfmdir)
	cp *vf $(vfdir)
	cp *tfm $(tfmdir)

clean:
	-rm *pl *mtx *fd

realclean: clean
	-rm *tfm *vf


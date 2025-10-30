#	Makefile for Bitstream Charter [2004/01/19 PSNFSS-v9.1a (WaS)]

#       This is for OS/2 with emTeX/TDS and GNU Make or IBM's nmake;
#   ***	asterisks indicate directory names and commands 
#       which need to be customized for other systems.

#   ***	the TDS root dirctory:
tdsdir=	e:\texmf

#   ***	where the .vf and .tfm files should go:
vfdir=  $(tdsdir)\fonts\vf\bitstrea\charter
tfmdir= $(tdsdir)\fonts\tfm\bitstrea\charter

#   *** how to run fomtinst:
fi=     tex

all:	vfs installfonts

vfs:
	$(fi) inst
	pltotf bchb8r.pl 
	pltotf bchbi8r.pl
	pltotf bchbo8r.pl
	pltotf bchr8r.pl 
	pltotf bchri8r.pl
	pltotf bchro8r.pl
	vptovf bchb7t.vpl 
	vptovf bchb8c.vpl 
	vptovf bchb8t.vpl 
	vptovf bchbc7t.vpl
	vptovf bchbc8t.vpl
	vptovf bchbi7t.vpl
	vptovf bchbi8c.vpl
	vptovf bchbi8t.vpl
	vptovf bchbo7t.vpl
	vptovf bchbo8c.vpl
	vptovf bchbo8t.vpl
	vptovf bchr7t.vpl 
	vptovf bchr8c.vpl 
	vptovf bchr8t.vpl 
	vptovf bchrc7t.vpl
	vptovf bchrc8t.vpl
	vptovf bchri7t.vpl
	vptovf bchri8c.vpl
	vptovf bchri8t.vpl
	vptovf bchro7t.vpl
	vptovf bchro8c.vpl
	vptovf bchro8t.vpl
	
installfonts:
	-mkdir $(vfdir)
	-mkdir $(tfmdir)
	cp *vf $(vfdir)
	cp *tfm $(tfmdir)

clean:
	-rm *pl b*.mtx *fd

realclean: clean
	-rm *tfm *vf


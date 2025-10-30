#	Makefile for Adobe Zapf Chancery [2001-09-26 PSNFSS-v9.1 (WaS)]

#       This is for OS/2 with emTeX/TDS and GNU Make or IBM's nmake;
#   ***	asterisks indicate directory names and commands 
#       which need to be customized for other systems.

#   ***	the TDS root dirctory:
tdsdir=	e:\texmf

#   ***	where the .vf and .tfm files should go:
vfdir=  $(tdsdir)\fonts\vf\adobe\zapfchan
tfmdir= $(tdsdir)\fonts\tfm\adobe\zapfchan

#   *** how to run fontinst:
fi=     fi-1801

all:	vfs installfonts

vfs:
	$(fi) inst
	pltotf pzcmi8r.pl
	vptovf pzcmi7t.vpl
	vptovf pzcmi8c.vpl
	vptovf pzcmi8t.vpl
	
installfonts:
	-mkdir $(vfdir)
	-mkdir $(tfmdir)
	cp *vf $(vfdir)
	cp *tfm $(tfmdir)

clean:
	-rm *pl *mtx *fd

realclean: clean
	-rm *tfm *vf


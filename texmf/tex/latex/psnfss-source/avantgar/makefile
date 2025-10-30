#	Makefile for Adobe AvantGarde [2003/09/26 PSNFSS-v9.1 (WaS)]

#       This is for OS/2 with emTeX/TDS and GNU Make or IBM's nmake;
#   ***	asterisks indicate directory names and commands 
#       which need to be customized for other systems.

#   ***	the TDS root dirctory:
tdsdir=	e:\texmf

#   ***	where the .vf and .tfm files should go:
vfdir=  $(tdsdir)\fonts\vf\adobe\avantgar
tfmdir= $(tdsdir)\fonts\tfm\adobe\avantgar

#   *** how to run fontinst:
fi=     fi-1801

all:	vfs installfonts

vfs:
	$(fi) inst
	pltotf pagd8r.pl 
	pltotf pagdo8r.pl
	pltotf pagk8r.pl 
	pltotf pagko8r.pl
	vptovf pagd7t.vpl 
	vptovf pagd8c.vpl 
	vptovf pagd8t.vpl 
	vptovf pagdc7t.vpl
	vptovf pagdc8t.vpl
	vptovf pagdo7t.vpl
	vptovf pagdo8c.vpl
	vptovf pagdo8t.vpl
	vptovf pagk7t.vpl 
	vptovf pagk8c.vpl 
	vptovf pagk8t.vpl 
	vptovf pagkc7t.vpl
	vptovf pagkc8t.vpl
	vptovf pagko7t.vpl
	vptovf pagko8c.vpl
	vptovf pagko8t.vpl

installfonts:
	-mkdir $(vfdir)
	-mkdir $(tfmdir)
	cp *vf $(vfdir)
	cp *tfm $(tfmdir)

clean:
	-rm *pl *mtx *fd

realclean: clean
	-rm *tfm *vf


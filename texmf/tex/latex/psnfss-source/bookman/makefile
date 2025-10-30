#	Makefile for Adobe Bookman [2003/09/29 PSNFSS-v9.1 (WaS)]

#       This is for OS/2 with emTeX/TDS and GNU Make or IBM's nmake;
#   ***	asterisks indicate directory names and commands 
#       which need to be customized for other systems.

#   ***	the TDS root dirctory:
tdsdir=	e:\texmf

#   ***	where the .vf and .tfm files should go:
vfdir=  $(tdsdir)\fonts\vf\adobe\bookman
tfmdir= $(tdsdir)\fonts\tfm\adobe\bookman

#   *** how to run fontinst:
fi=     fi-1801

all:	vfs installfonts

vfs:
	$(fi) inst
	pltotf pbkd8r.pl 
	pltotf pbkdi8r.pl
	pltotf pbkdo8r.pl
	pltotf pbkl8r.pl 
	pltotf pbkli8r.pl
	pltotf pbklo8r.pl
	vptovf pbkd7t.vpl 
	vptovf pbkd8c.vpl 
	vptovf pbkd8t.vpl 
	vptovf pbkdc7t.vpl
	vptovf pbkdc8t.vpl
	vptovf pbkdi7t.vpl
	vptovf pbkdi8c.vpl
	vptovf pbkdi8t.vpl
	vptovf pbkdo7t.vpl
	vptovf pbkdo8c.vpl
	vptovf pbkdo8t.vpl
	vptovf pbkl7t.vpl 
	vptovf pbkl8c.vpl 
	vptovf pbkl8t.vpl 
	vptovf pbklc7t.vpl
	vptovf pbklc8t.vpl
	vptovf pbkli7t.vpl
	vptovf pbkli8c.vpl
	vptovf pbkli8t.vpl
	vptovf pbklo7t.vpl
	vptovf pbklo8c.vpl
	vptovf pbklo8t.vpl
	
installfonts:
	-mkdir $(vfdir)
	-mkdir $(tfmdir)
	cp *vf $(vfdir)
	cp *tfm $(tfmdir)

clean:
	-rm *pl *mtx *fd

realclean: clean
	-rm *tfm *vf


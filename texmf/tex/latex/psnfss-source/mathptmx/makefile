#	Makefile for the virtual mathptmx fonts.
#       This file is part of PSNFSS v8.1a [1999-10-30 (WaS)].

#       This is for OS/2 with emTeX/TDS and GNU Make or IBM's nmake;
#   ***	asterisks indicate directory names and commands 
#       which need to be customized for other systems.

#   ***	the TDS root dirctory:
tdsdir=	e:\texmf

#   ***	where the .vf and .tfm files should go:
vfdir=  $(tdsdir)\fonts\vf\adobe\times
tfmdir= $(tdsdir)\fonts\tfm\adobe\times

#   ***	where the .fd files should go:
texdir= $(tdsdir)\tex\latex\psnfss

#   *** how to run plain TeX:
tex=    tex
ZAP=	cmex10.mtx cmr10.mtx cmmi10.mtx cmsy10.mtx \
	rsfs10.mtx psyr.mtx psyr.pl psyro.mtx psyro.pl \
	ptmr8a.mtx ptmr8a.pl ptmr8r.mtx ptmr8r.pl \
	ptmri8a.mtx ptmri8a.pl ptmri8r.mtx ptmri8r.pl \
	zptmcm7t.vpl zptmcm7m.vpl zptmcm7y.vpl zptmcm7v.vpl

all:	getafms tex metrics installfonts

getafms:
	cp $(tdsdir)/fonts/afm/adobe/times/ptmr8a.afm .
	cp $(tdsdir)/fonts/afm/adobe/times/ptmri8a.afm .
	cp $(tdsdir)/fonts/afm/adobe/symbol/psyr.afm .
	
tex:	
	$(tex) fontptcmx

metrics:
	vptovf zptmcm7t.vpl
	vptovf zptmcm7m.vpl
	vptovf zptmcm7y.vpl
	vptovf zptmcm7v.vpl
	pltotf psyro.pl

installfonts:
	-mkdir $(vfdir)
	-mkdir $(tfmdir)
	-mkdir $(texdir)
	cp *.vf $(vfdir)
	cp *.tfm $(tfmdir)
	cp *.fd $(texdir)

clean:
	-rm $(ZAP)

realclean: clean
	-rm *.afm p*tfm z*.tfm *.vf *.fd *.log

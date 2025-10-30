#	Makefile for the virtual mathptm fonts [1999-06-08]
#       for PSNFSS 8.0. (WaS)

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

ZAP=	cmex10.mtx cmex9.mtx cmr10.mtx cmmi10.mtx cmsy10.mtx \
	psyr.mtx psyr.pl \
	ptmr8a.mtx ptmr8a.pl ptmr8r.mtx ptmr8r.pl \
	ptmri8a.mtx ptmri8a.pl ptmri8r.mtx ptmri8r.pl \
	pzcmi8a.mtx pzcmi8a.pl pzcmi8r.mtx pzcmi8r.pl \
	zpsycmrv.vpl zptmcmr.vpl zptmcmrm.vpl zpzccmry.vpl

all:	getafms tex metrics installfonts

getafms:
	cp $(tdsdir)/fonts/afm/adobe/times/ptmr8a.afm .
	cp $(tdsdir)/fonts/afm/adobe/times/ptmri8a.afm .
	cp $(tdsdir)/fonts/afm/adobe/zapfchan/pzcmi8a.afm .
	cp $(tdsdir)/fonts/afm/adobe/symbol/psyr.afm .
	
tex:	
	tex fontptcm

metrics:
	vptovf zpsycmrv.vpl
	vptovf zptmcmr.vpl
	vptovf zptmcmrm.vpl
	vptovf zpzccmry.vpl

installfonts:
	-mkdir $(vfdir)
	-mkdir $(tfmdir)
	-mkdir $(texdir)
	cp *.vf $(vfdir)
	cp z*.tfm $(tfmdir)
	cp *.fd $(texdir)

clean:
	-rm $(ZAP)

realclean: clean
	-rm z*.tfm *.vf *.fd *.log

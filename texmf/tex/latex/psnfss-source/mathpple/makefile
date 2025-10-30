#	Makefile for the virtual mathpple fonts [1999-12-20 PSNFSS-8.1 (WaS)]

#       This is for OS/2 with emTeX/TDS and GNU Make or IBM's nmake;
#   ***	asterisks indicate directory names and commands 
#       which need to be customized for other systems.

#   ***	the TDS root dirctory:
tdsdir=	e:\texmf

#   ***	where the .vf and .tfm files should go:
vfdir=  $(tdsdir)\fonts\vf\adobe\palatino
tfmdir= $(tdsdir)\fonts\tfm\adobe\palatino

#   ***	where the .fd files should go:
texdir= $(tdsdir)\tex\latex\psnfss

#   *** how to run plain TeX:
tex=    tex

ZAP=	cmr10.mtx cmmi10.mtx cmsy10.mtx cmex10.mtx \
	cmbx10.mtx cmmib10.mtx cmbsy10.mtx \
	pplb8a.mtx pplb8r.mtx pplbi8a.mtx pplbi8r.mtx pplr8a.mtx \
	pplr8r.mtx pplri8a.mtx pplri8r.mtx \
	pplb8a.pl pplb8r.pl pplbi8a.pl pplbi8r.pl pplr8a.pl \
	pplr8r.pl pplri8a.pl pplri8r.pl \
	eurm10.mtx eurb10.mtx eusm10.mtx eusb10.mtx euex10.mtx\
	eurmo10.mtx eurbo10.mtx eurmo10.pl eurbo10.pl psyr.mtx psyr.pl \
	zppleb7m.vpl  zppleb7y.vpl  zppler7t.vpl  zppler7y.vpl \
	zppleb7t.vpl  zppler7m.vpl  zppler7v.vpl


all:	tex metrics installfonts

tex:
	$(tex) fontplcme

metrics:
	pltotf eurmo10.pl
	pltotf eurbo10.pl
	vptovf zppler7t.vpl
	vptovf zppler7m.vpl
	vptovf zppler7y.vpl
	vptovf zppler7v.vpl
	vptovf zppleb7t.vpl
	vptovf zppleb7m.vpl
	vptovf zppleb7y.vpl

installfonts:
	-mkdir $(vfdir)
	-mkdir $(tfmdir)
	-mkdir $(texdir)
	cp *.vf $(vfdir)
	cp z*.tfm eurmo10.tfm eurbo10.tfm $(tfmdir)
	cp ot1zpple.fd $(texdir)
	cp omlzpple.fd $(texdir)
	cp omszpple.fd $(texdir)
	cp omxzpple.fd $(texdir)

clean:
	-rm $(ZAP)

realclean: clean
	-rm *tfm *.vf *.fd *.log


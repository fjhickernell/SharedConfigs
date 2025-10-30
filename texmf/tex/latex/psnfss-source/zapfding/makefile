#	Makefile for Adobe Zapf Dingbats [2001-05-26 PSNFSS-v8.2 (WaS)]

#       This is for OS/2 with emTeX/TDS and GNU Make or IBM's nmake;
#   ***	asterisks indicate directory names and commands 
#       which need to be customized for other systems.

#   ***	the TDS root dirctory:
tdsdir=	e:\texmf

#   ***	where the .tfm files should go:
tfmdir= $(tdsdir)\fonts\tfm\adobe\zapfding

all:	metrics installfonts

metrics:
	afm2tfm pzdr.afm
	
installfonts:
	-mkdir $(tfmdir)
	cp pzdr.tfm $(tfmdir)

realclean:
	-rm pzdr.tfm


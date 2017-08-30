PY?=python
PELICAN?=pelican
PELICANOPTS=

BASEDIR=$(CURDIR)
INPUTDIR=$(BASEDIR)/content
OUTPUTDIR=$(BASEDIR)/output
CONFFILE=$(BASEDIR)/pelicanconf.py
PUBLISHCONF=$(BASEDIR)/publishconf.py
TMPDIR=$(BASEDIR)/tmp

SSH_HOST=kumo.ovgu.de
SSH_PORT=22
SSH_USER=
SSH_TARGET_DIR=/var/www/psychoinformatics/www

DEBUG ?= 0
ifeq ($(DEBUG), 1)
	PELICANOPTS += -D
endif

RELATIVE ?= 0
ifeq ($(RELATIVE), 1)
	PELICANOPTS += --relative-urls
endif

help:
	@echo 'Makefile for a pelican Web site                                           '
	@echo '                                                                          '
	@echo 'Usage:                                                                    '
	@echo '   make html                           (re)generate the web site          '
	@echo '   make clean                          remove the generated files         '
	@echo '   make regenerate                     regenerate files upon modification '
	@echo '   make publish                        generate using production settings '
	@echo '   make devserver [PORT=8000]          start/restart develop_server.sh    '
	@echo '   make stopserver                     stop local server                  '
	@echo '   make ssh_upload                     upload the web site via SSH        '
	@echo '   make rsync_upload                   upload the web site via rsync+ssh  '
	@echo '                                                                          '
	@echo 'Set the DEBUG variable to 1 to enable debugging, e.g. make DEBUG=1 html   '
	@echo 'Set the RELATIVE variable to 1 to enable relative urls                    '
	@echo '                                                                          '

html:
	$(PELICAN) $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS)
	if test -d $(BASEDIR)/static; then rsync -r $(BASEDIR)/static/ $(OUTPUTDIR)/; fi

clean:
	[ ! -d $(OUTPUTDIR) ] || rm -rf $(OUTPUTDIR)
	[ ! -d $(TMPDIR) ] || rm -rf $(TMPDIR)
	pyclean ./

regenerate:
	$(PELICAN) -r $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS)

devserver:
ifdef PORT
	$(BASEDIR)/develop_server.sh restart $(PORT)
else
	$(BASEDIR)/develop_server.sh restart
endif

prep:
	git submodule update --init

stopserver:
	$(BASEDIR)/develop_server.sh stop
	@echo 'Stopped Pelican and SimpleHTTPServer processes running in background.'

publish: prep
	$(PELICAN) $(INPUTDIR) -o $(OUTPUTDIR) -s $(PUBLISHCONF) $(PELICANOPTS)
	if test -d $(BASEDIR)/static; then rsync -rv $(BASEDIR)/static/ $(OUTPUTDIR)/; fi

ssh_upload: publish
ifdef SSH_USER
	scp -P $(SSH_PORT) -r $(OUTPUTDIR)/* $(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR)
else
	scp -P $(SSH_PORT) -r $(OUTPUTDIR)/* $(SSH_HOST):$(SSH_TARGET_DIR)
endif

rsync_upload: publish
ifdef SSH_USER
	rsync -e "ssh -p $(SSH_PORT)" -rv --delete $(OUTPUTDIR)/ $(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR) --cvs-exclude
else
	rsync -e "ssh -p $(SSH_PORT)" -rv --delete $(OUTPUTDIR)/ $(SSH_HOST):$(SSH_TARGET_DIR) --cvs-exclude
endif

.PHONY: html help clean regenerate devserver prep publish ssh_upload rsync_upload

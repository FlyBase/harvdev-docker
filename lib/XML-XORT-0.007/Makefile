# This Makefile is for the XML::XORT extension to perl.
#
# It was generated automatically by MakeMaker version
# 6.17 (Revision: 1.133) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: (q[LIB=/users/zhou/work/XML-XORT-0.007/xort])
#
#   MakeMaker Parameters:

#     ABSTRACT => q[A generic module for mapping relational schema to XML]
#     AUTHOR => q[Pinglei Zhou <zhou@morgan.harvard.edu>]
#     EXE_FILES => [q[bin/xort_validator.pl], q[bin/xort_loader.pl], q[bin/XORTDiff.pl], q[bin/xort_dump.pl], q[bin/xort_ddl_properties_creator.pl]]
#     NAME => q[XML::XORT]
#     PL_FILES => { make_util/conf_install.pl.PLS=>q[make_util/conf_install.pl], bin/dump.pl.PLS=>q[bin/xort_dump.pl], bin/validator.pl.PLS=>q[bin/xort_validator.pl], bin/XORTDiff.pl.PLS=>q[bin/XORTDiff.pl], bin/apollo_cgi.pl.PLS=>q[bin/apollo_cgi.pl], bin/ddl_properties_creator.pl.PLS=>q[bin/xort_ddl_properties_creator.pl], bin/loader.pl.PLS=>q[bin/xort_loader.pl] }
#     PREREQ_PM => { XML::DOM=>q[0], XML::Parser::PerlSAX=>q[0], DBI=>q[0] }
#     VERSION => q[0.007]

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /usr/local/lib/perl5/5.8.5/sun4-solaris/Config.pm)

# They may have been overridden via Makefile.PL or on the command line
AR = ar
CC = gcc
CCCDLFLAGS = -fPIC
CCDLFLAGS =  
DLEXT = so
DLSRC = dl_dlopen.xs
LD = gcc
LDDLFLAGS = -G -L/usr/local/lib
LDFLAGS =  -L/usr/local/lib 
LIBC = /lib/libc.so
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = solaris
OSVERS = 2.8
RANLIB = :
SITELIBEXP = /usr/local/lib/perl5/site_perl/5.8.5
SITEARCHEXP = /usr/local/lib/perl5/site_perl/5.8.5/sun4-solaris
SO = so
EXE_EXT = 
FULL_AR = /usr/ccs/bin/ar
VENDORARCHEXP = /users/zhou/work/XML-XORT-0.007/xort/sun4-solaris
VENDORLIBEXP = /users/zhou/work/XML-XORT-0.007/xort


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = /
NAME = XML::XORT
NAME_SYM = XML_XORT
VERSION = 0.007
VERSION_MACRO = VERSION
VERSION_SYM = 0_007
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 0.007
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = blib/arch
INST_SCRIPT = blib/script
INST_BIN = blib/bin
INST_LIB = blib/lib
INST_MAN1DIR = blib/man1
INST_MAN3DIR = blib/man3
MAN1EXT = 1
MAN3EXT = 3
INSTALLDIRS = site
DESTDIR = 
PREFIX = 
PERLPREFIX = /usr/local
SITEPREFIX = /usr/local
VENDORPREFIX = 
INSTALLPRIVLIB = /users/zhou/work/XML-XORT-0.007/xort
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = /users/zhou/work/XML-XORT-0.007/xort
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = /users/zhou/work/XML-XORT-0.007/xort
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = /users/zhou/work/XML-XORT-0.007/xort/sun4-solaris
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = /users/zhou/work/XML-XORT-0.007/xort/sun4-solaris
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = /users/zhou/work/XML-XORT-0.007/xort/sun4-solaris
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = $(PERLPREFIX)/bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = $(SITEPREFIX)/bin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = 
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = $(PERLPREFIX)/bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLMAN1DIR = $(PERLPREFIX)/man/man1
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = $(SITEPREFIX)/man/man1
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = 
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = $(PERLPREFIX)/man/man3
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = $(SITEPREFIX)/man/man3
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = 
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB = /usr/local/lib/perl5/5.8.5
PERL_ARCHLIB = /usr/local/lib/perl5/5.8.5/sun4-solaris
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = $(FIRST_MAKEFILE).old
MAKE_APERL_FILE = $(FIRST_MAKEFILE).aperl
PERLMAINCC = $(CC)
PERL_INC = /usr/local/lib/perl5/5.8.5/sun4-solaris/CORE
PERL = /usr/local/bin/perl5.8.5
FULLPERL = /usr/local/bin/perl5.8.5
ABSPERL = $(PERL)
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
ABSPERLRUN = $(ABSPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
PERL_CORE = 0
PERM_RW = 644
PERM_RWX = 755

MAKEMAKER   = /usr/local/lib/perl5/5.8.5/ExtUtils/MakeMaker.pm
MM_VERSION  = 6.17
MM_REVISION = 1.133

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
FULLEXT = XML/XORT
BASEEXT = XORT
PARENT_NAME = XML
DLBASE = $(BASEEXT)
VERSION_FROM = 
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic

# Handy lists of source code files:
XS_FILES = 
C_FILES  = 
O_FILES  = 
H_FILES  = 
MAN1PODS = bin/XORTDiff.pl \
	bin/xort_ddl_properties_creator.pl \
	bin/xort_dump.pl \
	bin/xort_loader.pl \
	bin/xort_validator.pl
MAN3PODS = lib/XML/XORT/Dumper/DumperSpec.pm \
	lib/XML/XORT/Dumper/DumperXML.pm \
	lib/XML/XORT/Loader/XMLAccession.pm \
	lib/XML/XORT/Loader/XMLParser.pm \
	lib/XML/XORT/Loader/XMLValidator.pm \
	lib/XML/XORT/Loader/XMLValidatorNoDB.pm

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIB)$(DIRFILESEP)Config.pm $(PERL_INC)$(DIRFILESEP)config.h

# Where to build things
INST_LIBDIR      = $(INST_LIB)/XML
INST_ARCHLIBDIR  = $(INST_ARCHLIB)/XML

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC      = 
INST_DYNAMIC     = 
INST_BOOT        = 

# Extra linker info
EXPORT_LIST        = 
PERL_ARCHIVE       = 
PERL_ARCHIVE_AFTER = 


TO_INST_PM = lib/XML/XORT/Dumper/DumperSpec.pm \
	lib/XML/XORT/Dumper/DumperXML.pm \
	lib/XML/XORT/Loader/XMLAccession.pm \
	lib/XML/XORT/Loader/XMLParser.pm \
	lib/XML/XORT/Loader/XMLValidator.pm \
	lib/XML/XORT/Loader/XMLValidatorNoDB.pm \
	lib/XML/XORT/Util/DbUtil/DB.pm \
	lib/XML/XORT/Util/DbUtil/DbHandler.pm \
	lib/XML/XORT/Util/GeneralUtil/Constants.pm \
	lib/XML/XORT/Util/GeneralUtil/Properties.pm \
	lib/XML/XORT/Util/GeneralUtil/Structure.pm \
	lib/XML/XORT/XMLDiff/XORTTreeDiff.pm

PM_TO_BLIB = lib/XML/XORT/Loader/XMLValidator.pm \
	blib/lib/XML/XORT/Loader/XMLValidator.pm \
	lib/XML/XORT/XMLDiff/XORTTreeDiff.pm \
	blib/lib/XML/XORT/XMLDiff/XORTTreeDiff.pm \
	lib/XML/XORT/Loader/XMLAccession.pm \
	blib/lib/XML/XORT/Loader/XMLAccession.pm \
	lib/XML/XORT/Loader/XMLValidatorNoDB.pm \
	blib/lib/XML/XORT/Loader/XMLValidatorNoDB.pm \
	lib/XML/XORT/Util/GeneralUtil/Constants.pm \
	blib/lib/XML/XORT/Util/GeneralUtil/Constants.pm \
	lib/XML/XORT/Util/DbUtil/DB.pm \
	blib/lib/XML/XORT/Util/DbUtil/DB.pm \
	lib/XML/XORT/Dumper/DumperXML.pm \
	blib/lib/XML/XORT/Dumper/DumperXML.pm \
	lib/XML/XORT/Util/GeneralUtil/Structure.pm \
	blib/lib/XML/XORT/Util/GeneralUtil/Structure.pm \
	lib/XML/XORT/Util/GeneralUtil/Properties.pm \
	blib/lib/XML/XORT/Util/GeneralUtil/Properties.pm \
	lib/XML/XORT/Loader/XMLParser.pm \
	blib/lib/XML/XORT/Loader/XMLParser.pm \
	lib/XML/XORT/Dumper/DumperSpec.pm \
	blib/lib/XML/XORT/Dumper/DumperSpec.pm \
	lib/XML/XORT/Util/DbUtil/DbHandler.pm \
	blib/lib/XML/XORT/Util/DbUtil/DbHandler.pm


# --- MakeMaker platform_constants section:
MM_Unix_VERSION = 1.42
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(PERLRUN)  -e 'use AutoSplit;  autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1)'



# --- MakeMaker tool_xsubpp section:


# --- MakeMaker tools_other section:
SHELL = /bin/sh
CHMOD = chmod
CP = cp
MV = mv
NOOP = $(SHELL) -c true
NOECHO = @
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1
MKPATH = $(PERLRUN) "-MExtUtils::Command" -e mkpath
EQUALIZE_TIMESTAMP = $(PERLRUN) "-MExtUtils::Command" -e eqtime
ECHO = echo
ECHO_N = echo -n
UNINST = 0
VERBINST = 0
MOD_INSTALL = $(PERLRUN) -MExtUtils::Install -e 'install({@ARGV}, '\''$(VERBINST)'\'', 0, '\''$(UNINST)'\'');'
DOC_INSTALL = $(PERLRUN) "-MExtUtils::Command::MM" -e perllocal_install
UNINSTALL = $(PERLRUN) "-MExtUtils::Command::MM" -e uninstall
WARN_IF_OLD_PACKLIST = $(PERLRUN) "-MExtUtils::Command::MM" -e warn_if_old_packlist


# --- MakeMaker makemakerdflt section:
makemakerdflt: all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section:
TAR = tar
TARFLAGS = cvf
ZIP = zip
ZIPFLAGS = -r
COMPRESS = gzip --best
SUFFIX = .gz
SHAR = shar
PREOP = $(NOECHO) $(NOOP)
POSTOP = $(NOECHO) $(NOOP)
TO_UNIX = $(NOECHO) $(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist
DISTNAME = XML-XORT
DISTVNAME = XML-XORT-0.007


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIB="$(LIB)"\
	LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	PREFIX="$(PREFIX)"\
	OPTIMIZE="$(OPTIMIZE)"\
	PASTHRU_DEFINE="$(PASTHRU_DEFINE)"\
	PASTHRU_INC="$(PASTHRU_INC)"


# --- MakeMaker special_targets section:
.SUFFIXES: .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest



# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:
all :: pure_all manifypods
	$(NOECHO) $(NOOP)


pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) $(INST_LIBDIR)$(DIRFILESEP).exists
	$(NOECHO) $(NOOP)

config :: $(INST_ARCHAUTODIR)$(DIRFILESEP).exists
	$(NOECHO) $(NOOP)

config :: $(INST_AUTODIR)$(DIRFILESEP).exists
	$(NOECHO) $(NOOP)

$(INST_AUTODIR)/.exists :: /usr/local/lib/perl5/5.8.5/sun4-solaris/CORE/perl.h
	$(NOECHO) $(MKPATH) $(INST_AUTODIR)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) /usr/local/lib/perl5/5.8.5/sun4-solaris/CORE/perl.h $(INST_AUTODIR)/.exists

	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_AUTODIR)

$(INST_LIBDIR)/.exists :: /usr/local/lib/perl5/5.8.5/sun4-solaris/CORE/perl.h
	$(NOECHO) $(MKPATH) $(INST_LIBDIR)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) /usr/local/lib/perl5/5.8.5/sun4-solaris/CORE/perl.h $(INST_LIBDIR)/.exists

	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_LIBDIR)

$(INST_ARCHAUTODIR)/.exists :: /usr/local/lib/perl5/5.8.5/sun4-solaris/CORE/perl.h
	$(NOECHO) $(MKPATH) $(INST_ARCHAUTODIR)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) /usr/local/lib/perl5/5.8.5/sun4-solaris/CORE/perl.h $(INST_ARCHAUTODIR)/.exists

	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_ARCHAUTODIR)

config :: $(INST_MAN1DIR)$(DIRFILESEP).exists
	$(NOECHO) $(NOOP)


$(INST_MAN1DIR)/.exists :: /usr/local/lib/perl5/5.8.5/sun4-solaris/CORE/perl.h
	$(NOECHO) $(MKPATH) $(INST_MAN1DIR)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) /usr/local/lib/perl5/5.8.5/sun4-solaris/CORE/perl.h $(INST_MAN1DIR)/.exists

	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_MAN1DIR)

config :: $(INST_MAN3DIR)$(DIRFILESEP).exists
	$(NOECHO) $(NOOP)


$(INST_MAN3DIR)/.exists :: /usr/local/lib/perl5/5.8.5/sun4-solaris/CORE/perl.h
	$(NOECHO) $(MKPATH) $(INST_MAN3DIR)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) /usr/local/lib/perl5/5.8.5/sun4-solaris/CORE/perl.h $(INST_MAN3DIR)/.exists

	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_MAN3DIR)

help:
	perldoc ExtUtils::MakeMaker


# --- MakeMaker linkext section:

linkext :: $(LINKTYPE)
	$(NOECHO) $(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic section:

dynamic :: $(FIRST_MAKEFILE) $(INST_DYNAMIC) $(INST_BOOT)
	$(NOECHO) $(NOOP)


# --- MakeMaker dynamic_bs section:

BOOTSTRAP =


# --- MakeMaker dynamic_lib section:


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker static_lib section:


# --- MakeMaker manifypods section:

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all  \
	bin/xort_ddl_properties_creator.pl \
	bin/XORTDiff.pl \
	bin/xort_validator.pl \
	bin/xort_dump.pl \
	bin/xort_loader.pl \
	lib/XML/XORT/Loader/XMLValidator.pm \
	lib/XML/XORT/Dumper/DumperXML.pm \
	lib/XML/XORT/Loader/XMLParser.pm \
	lib/XML/XORT/Loader/XMLAccession.pm \
	lib/XML/XORT/Dumper/DumperSpec.pm \
	lib/XML/XORT/Loader/XMLValidatorNoDB.pm \
	lib/XML/XORT/Loader/XMLValidator.pm \
	lib/XML/XORT/Dumper/DumperXML.pm \
	lib/XML/XORT/Loader/XMLParser.pm \
	lib/XML/XORT/Loader/XMLAccession.pm \
	lib/XML/XORT/Dumper/DumperSpec.pm \
	lib/XML/XORT/Loader/XMLValidatorNoDB.pm
	$(NOECHO) $(POD2MAN) --section=1 --perm_rw=$(PERM_RW)\
	  bin/xort_ddl_properties_creator.pl $(INST_MAN1DIR)/xort_ddl_properties_creator.pl.$(MAN1EXT) \
	  bin/XORTDiff.pl $(INST_MAN1DIR)/XORTDiff.pl.$(MAN1EXT) \
	  bin/xort_validator.pl $(INST_MAN1DIR)/xort_validator.pl.$(MAN1EXT) \
	  bin/xort_dump.pl $(INST_MAN1DIR)/xort_dump.pl.$(MAN1EXT) \
	  bin/xort_loader.pl $(INST_MAN1DIR)/xort_loader.pl.$(MAN1EXT) 
	$(NOECHO) $(POD2MAN) --section=3 --perm_rw=$(PERM_RW)\
	  lib/XML/XORT/Loader/XMLValidator.pm $(INST_MAN3DIR)/XML::XORT::Loader::XMLValidator.$(MAN3EXT) \
	  lib/XML/XORT/Dumper/DumperXML.pm $(INST_MAN3DIR)/XML::XORT::Dumper::DumperXML.$(MAN3EXT) \
	  lib/XML/XORT/Loader/XMLParser.pm $(INST_MAN3DIR)/XML::XORT::Loader::XMLParser.$(MAN3EXT) \
	  lib/XML/XORT/Loader/XMLAccession.pm $(INST_MAN3DIR)/XML::XORT::Loader::XMLAccession.$(MAN3EXT) \
	  lib/XML/XORT/Dumper/DumperSpec.pm $(INST_MAN3DIR)/XML::XORT::Dumper::DumperSpec.$(MAN3EXT) \
	  lib/XML/XORT/Loader/XMLValidatorNoDB.pm $(INST_MAN3DIR)/XML::XORT::Loader::XMLValidatorNoDB.$(MAN3EXT) 




# --- MakeMaker processPL section:

all :: bin/XORTDiff.pl
	$(NOECHO) $(NOOP)

bin/XORTDiff.pl :: bin/XORTDiff.pl.PLS
	$(PERLRUNINST) bin/XORTDiff.pl.PLS bin/XORTDiff.pl

all :: bin/apollo_cgi.pl
	$(NOECHO) $(NOOP)

bin/apollo_cgi.pl :: bin/apollo_cgi.pl.PLS
	$(PERLRUNINST) bin/apollo_cgi.pl.PLS bin/apollo_cgi.pl

all :: bin/xort_ddl_properties_creator.pl
	$(NOECHO) $(NOOP)

bin/xort_ddl_properties_creator.pl :: bin/ddl_properties_creator.pl.PLS
	$(PERLRUNINST) bin/ddl_properties_creator.pl.PLS bin/xort_ddl_properties_creator.pl

all :: bin/xort_dump.pl
	$(NOECHO) $(NOOP)

bin/xort_dump.pl :: bin/dump.pl.PLS
	$(PERLRUNINST) bin/dump.pl.PLS bin/xort_dump.pl

all :: bin/xort_loader.pl
	$(NOECHO) $(NOOP)

bin/xort_loader.pl :: bin/loader.pl.PLS
	$(PERLRUNINST) bin/loader.pl.PLS bin/xort_loader.pl

all :: bin/xort_validator.pl
	$(NOECHO) $(NOOP)

bin/xort_validator.pl :: bin/validator.pl.PLS
	$(PERLRUNINST) bin/validator.pl.PLS bin/xort_validator.pl

all :: make_util/conf_install.pl
	$(NOECHO) $(NOOP)

make_util/conf_install.pl :: make_util/conf_install.pl.PLS
	$(PERLRUNINST) make_util/conf_install.pl.PLS make_util/conf_install.pl


# --- MakeMaker installbin section:

$(INST_SCRIPT)/.exists :: /usr/local/lib/perl5/5.8.5/sun4-solaris/CORE/perl.h
	$(NOECHO) $(MKPATH) $(INST_SCRIPT)
	$(NOECHO) $(EQUALIZE_TIMESTAMP) /usr/local/lib/perl5/5.8.5/sun4-solaris/CORE/perl.h $(INST_SCRIPT)/.exists

	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)

EXE_FILES = bin/xort_validator.pl bin/xort_loader.pl bin/XORTDiff.pl bin/xort_dump.pl bin/xort_ddl_properties_creator.pl

FIXIN = $(PERLRUN) "-MExtUtils::MY" -e "MY->fixin(shift)"

pure_all :: $(INST_SCRIPT)/xort_ddl_properties_creator.pl $(INST_SCRIPT)/XORTDiff.pl $(INST_SCRIPT)/xort_validator.pl $(INST_SCRIPT)/xort_dump.pl $(INST_SCRIPT)/xort_loader.pl
	$(NOECHO) $(NOOP)

realclean ::
	$(RM_F) $(INST_SCRIPT)/xort_ddl_properties_creator.pl $(INST_SCRIPT)/XORTDiff.pl $(INST_SCRIPT)/xort_validator.pl $(INST_SCRIPT)/xort_dump.pl $(INST_SCRIPT)/xort_loader.pl

$(INST_SCRIPT)/xort_ddl_properties_creator.pl: bin/xort_ddl_properties_creator.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)/.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/xort_ddl_properties_creator.pl
	$(CP) bin/xort_ddl_properties_creator.pl $(INST_SCRIPT)/xort_ddl_properties_creator.pl
	$(FIXIN) $(INST_SCRIPT)/xort_ddl_properties_creator.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/xort_ddl_properties_creator.pl

$(INST_SCRIPT)/XORTDiff.pl: bin/XORTDiff.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)/.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/XORTDiff.pl
	$(CP) bin/XORTDiff.pl $(INST_SCRIPT)/XORTDiff.pl
	$(FIXIN) $(INST_SCRIPT)/XORTDiff.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/XORTDiff.pl

$(INST_SCRIPT)/xort_validator.pl: bin/xort_validator.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)/.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/xort_validator.pl
	$(CP) bin/xort_validator.pl $(INST_SCRIPT)/xort_validator.pl
	$(FIXIN) $(INST_SCRIPT)/xort_validator.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/xort_validator.pl

$(INST_SCRIPT)/xort_dump.pl: bin/xort_dump.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)/.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/xort_dump.pl
	$(CP) bin/xort_dump.pl $(INST_SCRIPT)/xort_dump.pl
	$(FIXIN) $(INST_SCRIPT)/xort_dump.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/xort_dump.pl

$(INST_SCRIPT)/xort_loader.pl: bin/xort_loader.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)/.exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/xort_loader.pl
	$(CP) bin/xort_loader.pl $(INST_SCRIPT)/xort_loader.pl
	$(FIXIN) $(INST_SCRIPT)/xort_loader.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/xort_loader.pl


# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean_subdirs section:
clean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean :: clean_subdirs
	-$(RM_RF) ./blib $(MAKE_APERL_FILE) $(INST_ARCHAUTODIR)/extralibs.all $(INST_ARCHAUTODIR)/extralibs.ld perlmain.c tmon.out mon.out so_locations pm_to_blib *$(OBJ_EXT) *$(LIB_EXT) perl.exe perl perl$(EXE_EXT) $(BOOTSTRAP) $(BASEEXT).bso $(BASEEXT).def lib$(BASEEXT).def $(BASEEXT).exp $(BASEEXT).x core core.*perl.*.? *perl.core core.[0-9] core.[0-9][0-9] core.[0-9][0-9][0-9] core.[0-9][0-9][0-9][0-9] core.[0-9][0-9][0-9][0-9][0-9]
	-$(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)
	-$(PERL) bin/install_clean.pl


# --- MakeMaker realclean_subdirs section:
realclean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean realclean_subdirs
	$(RM_RF) $(INST_AUTODIR) $(INST_ARCHAUTODIR)
	$(RM_RF) $(DISTVNAME)
	$(RM_F)  blib/lib/XML/XORT/Dumper/DumperSpec.pm blib/lib/XML/XORT/Dumper/DumperXML.pm blib/lib/XML/XORT/Util/GeneralUtil/Properties.pm blib/lib/XML/XORT/XMLDiff/XORTTreeDiff.pm $(MAKEFILE_OLD)
	$(RM_F) blib/lib/XML/XORT/Loader/XMLParser.pm blib/lib/XML/XORT/Util/GeneralUtil/Structure.pm blib/lib/XML/XORT/Util/DbUtil/DbHandler.pm blib/lib/XML/XORT/Util/GeneralUtil/Constants.pm
	$(RM_F) blib/lib/XML/XORT/Loader/XMLValidator.pm blib/lib/XML/XORT/Loader/XMLAccession.pm blib/lib/XML/XORT/Util/DbUtil/DB.pm $(FIRST_MAKEFILE) blib/lib/XML/XORT/Loader/XMLValidatorNoDB.pm


# --- MakeMaker metafile section:
metafile :
	$(NOECHO) $(ECHO) '# http://module-build.sourceforge.net/META-spec.html' > META.yml
	$(NOECHO) $(ECHO) '#XXXXXXX This is a prototype!!!  It will change in the future!!! XXXXX#' >> META.yml
	$(NOECHO) $(ECHO) 'name:         XML-XORT' >> META.yml
	$(NOECHO) $(ECHO) 'version:      0.007' >> META.yml
	$(NOECHO) $(ECHO) 'version_from: ' >> META.yml
	$(NOECHO) $(ECHO) 'installdirs:  site' >> META.yml
	$(NOECHO) $(ECHO) 'requires:' >> META.yml
	$(NOECHO) $(ECHO) '    DBI:                           0' >> META.yml
	$(NOECHO) $(ECHO) '    XML::DOM:                      0' >> META.yml
	$(NOECHO) $(ECHO) '    XML::Parser::PerlSAX:          0' >> META.yml
	$(NOECHO) $(ECHO) '' >> META.yml
	$(NOECHO) $(ECHO) 'distribution_type: module' >> META.yml
	$(NOECHO) $(ECHO) 'generated_by: ExtUtils::MakeMaker version 6.17' >> META.yml


# --- MakeMaker metafile_addtomanifest section:
metafile_addtomanifest:
	$(NOECHO) $(PERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{META.yml} => q{Module meta-data (added by MakeMaker)}}) } ' \
	-e '    or print "Could not add META.yml to MANIFEST: $${'\''@'\''}\n"'


# --- MakeMaker dist_basics section:
distclean :: realclean distcheck
	$(NOECHO) $(NOOP)

distcheck :
	$(PERLRUN) "-MExtUtils::Manifest=fullcheck" -e fullcheck

skipcheck :
	$(PERLRUN) "-MExtUtils::Manifest=skipcheck" -e skipcheck

manifest :
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest

veryclean : realclean
	$(RM_F) *~ *.orig */*~ */*.orig



# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	$(NOECHO) $(PERLRUN) -l -e 'print '\''Warning: Makefile possibly out of date with $(VERSION_FROM)'\''' \
	-e '    if -e '\''$(VERSION_FROM)'\'' and -M '\''$(VERSION_FROM)'\'' < -M '\''$(FIRST_MAKEFILE)'\'';'

tardist : $(DISTVNAME).tar$(SUFFIX)
	$(NOECHO) $(NOOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) $(DISTVNAME).tar$(SUFFIX) > $(DISTVNAME).tar$(SUFFIX)_uu

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(POSTOP)

zipdist : $(DISTVNAME).zip
	$(NOECHO) $(NOOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)


# --- MakeMaker distdir section:
distdir : metafile metafile_addtomanifest
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"



# --- MakeMaker dist_test section:

disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)


# --- MakeMaker dist_ci section:

ci :
	$(PERLRUN) "-MExtUtils::Manifest=maniread" \
	  -e "@all = keys %{ maniread() };" \
	  -e "print(qq{Executing $(CI) @all\n}); system(qq{$(CI) @all});" \
	  -e "print(qq{Executing $(RCS_LABEL) ...\n}); system(qq{$(RCS_LABEL) @all});"


# --- MakeMaker install section:

install :: all pure_install doc_install conf_install

install_perl :: all pure_perl_install doc_perl_install

install_site :: all pure_site_install doc_site_install

install_vendor :: all pure_vendor_install doc_vendor_install

pure_install :: pure_$(INSTALLDIRS)_install

doc_install :: doc_$(INSTALLDIRS)_install

pure__install : pure_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install ::
	$(NOECHO) $(MOD_INSTALL) \
		read $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLARCHLIB)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLPRIVLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLARCHLIB) \
		$(INST_BIN) $(DESTINSTALLBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(SITEARCHEXP)/auto/$(FULLEXT)


pure_site_install ::
	$(NOECHO) $(MOD_INSTALL) \
		read $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLSITEARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLSITELIB) \
		$(INST_ARCHLIB) $(DESTINSTALLSITEARCH) \
		$(INST_BIN) $(DESTINSTALLSITEBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLSITEMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLSITEMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(PERL_ARCHLIB)/auto/$(FULLEXT)

pure_vendor_install ::
	$(NOECHO) $(MOD_INSTALL) \
		read $(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLVENDORARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLVENDORLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLVENDORARCH) \
		$(INST_BIN) $(DESTINSTALLVENDORBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLVENDORMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLVENDORMAN3DIR)

doc_perl_install ::
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLPRIVLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod

doc_site_install ::
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod

doc_vendor_install ::
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLVENDORLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod


uninstall :: uninstall_from_$(INSTALLDIRS)dirs

uninstall_from_perldirs ::
	$(NOECHO) $(UNINSTALL) $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist

uninstall_from_vendordirs ::
	$(NOECHO) $(UNINSTALL) $(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE:
	$(NOECHO) $(NOOP)


# --- MakeMaker perldepend section:


# --- MakeMaker makefile section:

# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
$(FIRST_MAKEFILE) : Makefile.PL $(CONFIGDEP)
	$(NOECHO) $(ECHO) "Makefile out-of-date with respect to $?"
	$(NOECHO) $(ECHO) "Cleaning current config before rebuilding Makefile..."
	$(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	$(NOECHO) $(MV)   $(FIRST_MAKEFILE) $(MAKEFILE_OLD)
	-$(MAKE) -f $(MAKEFILE_OLD) clean $(DEV_NULL) || $(NOOP)
	$(PERLRUN) Makefile.PL "LIB=/users/zhou/work/XML-XORT-0.007/xort"
	$(NOECHO) $(ECHO) "==> Your Makefile has been rebuilt. <=="
	$(NOECHO) $(ECHO) "==> Please rerun the make command.  <=="
	false



# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = /usr/local/bin/perl5.8.5

$(MAP_TARGET) :: static $(MAKE_APERL_FILE)
	$(MAKE) -f $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : $(FIRST_MAKEFILE)
	$(NOECHO) $(ECHO) Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	$(NOECHO) $(PERLRUNINST) \
		Makefile.PL DIR= \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS= \
		LIB=/users/zhou/work/XML-XORT-0.007/xort


# --- MakeMaker test section:

TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = t/*.t
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)

test :: $(TEST_TYPE)

test_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-e" "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)

test_ : test_dynamic

test_static :: test_dynamic
testdb_static :: testdb_dynamic


# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd:
	$(NOECHO) $(ECHO) '<SOFTPKG NAME="$(DISTNAME)" VERSION="0,007,0,0">' > $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <TITLE>$(DISTNAME)</TITLE>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <ABSTRACT>A generic module for mapping relational schema to XML</ABSTRACT>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <AUTHOR>Pinglei Zhou &lt;zhou@morgan.harvard.edu&gt;</AUTHOR>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <IMPLEMENTATION>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="DBI" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="XML-DOM" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <DEPENDENCY NAME="XML-Parser-PerlSAX" VERSION="0,0,0,0" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <OS NAME="$(OSNAME)" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <ARCHITECTURE NAME="sun4-solaris" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <CODEBASE HREF="" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    </IMPLEMENTATION>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '</SOFTPKG>' >> $(DISTNAME).ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib: $(TO_INST_PM)
	$(NOECHO) $(PERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', '\''$(PM_FILTER)'\'')'\
	  lib/XML/XORT/Loader/XMLValidator.pm blib/lib/XML/XORT/Loader/XMLValidator.pm \
	  lib/XML/XORT/XMLDiff/XORTTreeDiff.pm blib/lib/XML/XORT/XMLDiff/XORTTreeDiff.pm \
	  lib/XML/XORT/Loader/XMLAccession.pm blib/lib/XML/XORT/Loader/XMLAccession.pm \
	  lib/XML/XORT/Loader/XMLValidatorNoDB.pm blib/lib/XML/XORT/Loader/XMLValidatorNoDB.pm \
	  lib/XML/XORT/Util/GeneralUtil/Constants.pm blib/lib/XML/XORT/Util/GeneralUtil/Constants.pm \
	  lib/XML/XORT/Util/DbUtil/DB.pm blib/lib/XML/XORT/Util/DbUtil/DB.pm \
	  lib/XML/XORT/Dumper/DumperXML.pm blib/lib/XML/XORT/Dumper/DumperXML.pm \
	  lib/XML/XORT/Util/GeneralUtil/Structure.pm blib/lib/XML/XORT/Util/GeneralUtil/Structure.pm \
	  lib/XML/XORT/Util/GeneralUtil/Properties.pm blib/lib/XML/XORT/Util/GeneralUtil/Properties.pm \
	  lib/XML/XORT/Loader/XMLParser.pm blib/lib/XML/XORT/Loader/XMLParser.pm \
	  lib/XML/XORT/Dumper/DumperSpec.pm blib/lib/XML/XORT/Dumper/DumperSpec.pm \
	  lib/XML/XORT/Util/DbUtil/DbHandler.pm blib/lib/XML/XORT/Util/DbUtil/DbHandler.pm 
	$(NOECHO) $(TOUCH) $@

# --- MakeMaker selfdocument section:


# --- MakeMaker postamble section:

conf_install ::
	$(PERL) /users/zhou/work/XML-XORT-0.007/make_util/conf_install.pl


# End.

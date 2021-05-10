#!/bin/bash
# Script to generate auto-generated Makefile
#   :PROPERTIES:
#   :header-args: :tangle create_makefile.sh :noweb  yes :shebang #!/bin/bash :comments org
#   :END:

#   This script generates the Makefile that compiles the library.
#   The ~OUTPUT~ variable contains the name of the generated Makefile,typically
#   =Makefile.generated=.


# This file was created by tools/Building.org



OUTPUT=Makefile.generated.in



# We start by tangling all the org-mode files.


${top_srcdir}/tools/tangle.sh *.org
${top_srcdir}/tools/build_qmckl_h.sh



# Then we create the list of ~*.o~ files to be created, for library
# functions:


OBJECTS="qmckl_f.o"
for i in $(ls qmckl_*.c qmckl_*f.f90) ; do
    FILE=${i%.*}
    OBJECTS+=" ${FILE}.o"
done >> $OUTPUT



# for tests in C:


TESTS=""
for i in $(ls test_qmckl_*.c) ; do
    FILE=${i%.c}
    TESTS+=" ${FILE}.o"
done >> $OUTPUT



# and for tests in Fortran:


TESTS_F=""
for i in $(ls test_qmckl_*_f.f90) ; do
    FILE=${i%.f90}
    TESTS_F+=" ${FILE}.o"
done >> $OUTPUT



# Finally, we append the variables to the Makefile


cat << EOF > ${OUTPUT}
.POSIX:
.SUFFIXES:

package  = @PACKAGE_TARNAME@
version  = @PACKAGE_VERSION@

# VPATH-related substitution variables
srcdir   = @srcdir@
VPATH    = @srcdir@

prefix   = @prefix@

CC       = @CC@
DEFS     = @DEFS@
CFLAGS   = @CFLAGS@ -I\$(top_srcdir)/munit/ -I\$(top_srcdir)/include -I.
CPPFLAGS = @CPPFLAGS@
LIBS     = @LIBS@

FC     = @FC@
FCFLAGS= @FCFLAGS@ 

OBJECT_FILES=$OBJECTS

TESTS   = $TESTS
TESTS_F = $TESTS_F

LIBS   = @LIBS@
FCLIBS = @FCLIBS@
EOF

export
echo '
top_srcdir=$(srcdir)/..
shared_lib=$(top_srcdir)/lib/libqmckl.so
static_lib=$(top_srcdir)/lib/libqmckl.a
qmckl_h=$(top_srcdir)/include/qmckl.h
qmckl_f=$(top_srcdir)/share/qmckl/fortran/qmckl_f.f90
munit=$(top_srcdir)/munit/munit.c

datarootdir=$(prefix)/share
datadir=$(datarootdir)
docdir=$(datarootdir)/doc/$(package)
htmldir=$(docdir)/html
libdir=$(prefix)/lib
includedir=$(prefix)/include
fortrandir=$(datarootdir)/$(package)/fortran


shared: $(shared_lib)
static: $(static_lib)


all: shared static

$(shared_lib): $(OBJECT_FILES)
	$(CC) -shared $(OBJECT_FILES) -o $(shared_lib)

$(static_lib): $(OBJECT_FILES)
	$(AR) rcs $(static_lib) $(OBJECT_FILES)


# Test

qmckl_f.o: $(qmckl_f)
	$(FC) $(FCFLAGS) -c $(qmckl_f) -o $@

test_qmckl: test_qmckl.c $(qmckl_h) $(static_lib) $(TESTS) $(TESTS_F)
	$(CC) $(CFLAGS) $(CPPFLAGS) $(DEFS) $(munit) $(TESTS) $(TESTS_F) \
	$(static_lib) $(LIBS) $(FCLIBS) test_qmckl.c -o $@

test_qmckl_shared: test_qmckl.c $(qmckl_h) $(shared_lib) $(TESTS) $(TESTS_F)
	$(CC) $(CFLAGS) $(CPPFLAGS) $(DEFS) \
	-Wl,-rpath,$(top_srcdir)/lib -L$(top_srcdir)/lib $(munit) $(TESTS) \
	$(TESTS_F) -lqmckl $(LIBS) $(FCLIBS) test_qmckl.c -o $@

check: test_qmckl test_qmckl_shared
	./test_qmckl

clean:
	$(RM) -- *.o *.mod $(shared_lib) $(static_lib) test_qmckl




install:
	install -d $(DESTDIR)$(prefix)/lib
	install -d $(DESTDIR)$(prefix)/include
	install -d $(DESTDIR)$(prefix)/share/qmckl/fortran
	install -d $(DESTDIR)$(prefix)/share/doc/qmckl/html/
	install -d $(DESTDIR)$(prefix)/share/doc/qmckl/text/
	install    $(shared_lib) $(DESTDIR)$(libdir)/
	install    $(static_lib) $(DESTDIR)$(libdir)/
	install    $(qmckl_h) $(DESTDIR)$(includedir)
	install    $(qmckl_f) $(DESTDIR)$(fortrandir)
	install    $(top_srcdir)/share/doc/qmckl/html/*.html $(DESTDIR)$(docdir)/html/
	install    $(top_srcdir)/share/doc/qmckl/html/*.css  $(DESTDIR)$(docdir)/html/
	install    $(top_srcdir)/share/doc/qmckl/text/*.txt  $(DESTDIR)$(docdir)/text/

uninstall:
	rm $(DESTDIR)$(libdir)/libqmckl.so
	rm $(DESTDIR)$(libdir)/libqmckl.a
	rm $(DESTDIR)$(includedir)/qmckl.h
	rm -rf $(DESTDIR)$(datarootdir)/$(package)
	rm -rf $(DESTDIR)$(docdir)

.SUFFIXES: .c .f90 .o

.c.o:
	$(CC) $(CFLAGS) $(CPPFLAGS) $(DEFS) -c $*.c -o $*.o

.f90.o: qmckl_f.o
	$(FC) $(FCFLAGS) -c $*.f90 -o $*.o

.PHONY: check cppcheck clean all
' >> ${OUTPUT}
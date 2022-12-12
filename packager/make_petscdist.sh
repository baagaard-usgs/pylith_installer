#!/bin/bash
#
# Customized for PETSc tarball for PyLith by Brad Aagaard.
# Original is $PETSC_DIR/bin/maint/builddist.
#
# ~/src/cig/pylith_installer/packager/make_petscdist.sh /tools/common/petsc-dist knepley/pylith
#
# This script builds the PETSc tar file distribution
#
# Usage: builddist petscrepo [branch] [name]
# example usages:
#   builddist /sandbox/petsc/petsc.clone balay/foo [petsc-balay-foo.tar.bz]
#   builddist /sandbox/petsc/petsc.clone master [petsc-master.tar.bz]
#   builddist /sandbox/petsc/petsc.clone maint [petsc-3.4.1.tar.bz]
#   builddist /sandbox/petsc/petsc.clone maint release-snapshot [petsc-release-snapshot.tar.bz]
#
# Notes: version info is automatically obtained from include/petscversion.h
#
#echo "------- Have you done ALL of the following?? -----------------------------"
#echo "(0) Excluded any directories not for public release"
#echo "(1) Set the version number in website/index.html?"
#echo "(2) Set the version number and release date in petscversion.h?"
#echo "(3) Made sure Fortran include files match C ones?"
#echo "(4) Latest version of win32fe.exe is copied over into /sandbox/petsc/petsc-dist on login.mcs"
#echo "(5) Update version info on all petsc web pages"
#echo "(6) tag the new release with git and make a new clone for the release"
#echo "(7) got the users manual CLEARED by ANL publications for release"

# If version specified on the commandline, set the version
echo "Starting date: `date +'%a, %d %b %Y %H:%M:%S %z'`"

if [ $# = 3 ]; then
  petscrepo=$1
  branch=$2
  version=-$3
elif [ $# = 2 ]; then
  petscrepo=$1
  branch=$2
elif [ $# = 1 ]; then
  petscrepo=$1
  branch='main'
else
  echo 'Error: petscrepo not specified. Usge: builddist petscrepo'
  exit
fi

# check petscrepo to be valid
if [ ! -d $petscrepo ]; then
  echo 'Error: dir $petscrepo does not exist'
  exit
fi

if [ ! -d $petscrepo/.git ]; then
  echo 'Error: dir $petscrepo is not a git repo'
  exit
fi

# Initialize vars
PETSC_ARCH=arch-build; export PETSC_ARCH
PETSC_DIR=`cd $petscrepo;pwd -P`; export PETSC_DIR

# Clean and Update the git repository and check for branch
cd $PETSC_DIR
/bin/rm -rf $PETSC_DIR/$PETSC_ARCH $PETSC_DIR/arch-classic-docs
git clean -q -f -d -x
git fetch -q origin
git checkout -f origin/$branch
if [ "$?" != "0" ]; then
  echo 'Error: branch: $branch does not exist in $PETSC_DIR'
  exit
fi

pdir=`basename $PETSC_DIR`

# Create a tmp dir
if [ ! -d /tmp ]; then
  echo 'Error: /tmp does not exist!'
  exit
fi
tmpdir=~/tmp/petsc-dist-tmp.$USER.$$
if [ -d $tmpdir ]; then
  /bin/rm -rf $tmpdir
fi
mkdir -p $tmpdir
if [ ! -d $tmpdir ]; then
  echo 'Error: Cannot create $tmpdir'
  exit
fi

# check petscversion.h and set the version string
version_release=`grep '^#define PETSC_VERSION_RELEASE ' include/petscversion.h |tr -s ' ' | cut -d ' ' -f 3`
version_major=`grep '^#define PETSC_VERSION_MAJOR ' include/petscversion.h |tr -s ' ' | cut -d ' ' -f 3`
version_minor=`grep '^#define PETSC_VERSION_MINOR ' include/petscversion.h |tr -s ' ' | cut -d ' ' -f 3`
version_subminor=`grep '^#define PETSC_VERSION_SUBMINOR ' include/petscversion.h |tr -s ' ' | cut -d ' ' -f 3`

#generated a couple of more values
version_date=`date +"%b, %d, %Y"`
version_git=`git describe --match "v*"`
version_date_git=`git log -1 --pretty=format:%ci`
if [ ${version}foo = foo ]; then
  if  [ ${version_release} = 0 -o ${version_release} = -2 -o ${version_release} = -3 -o ${version_release} = -4 -o ${version_release} = -5 ]; then
    if [ ${branch}=="knepley/pylith" ]; then
      version=-pylith
    else
      version=-`echo ${branch} | sed s~/~-~g`
    fi
  elif [ ${version_release} = 1 ]; then
    version=-${version_major}.${version_minor}.${version_subminor}
  else
    echo "Unknown PETSC_VERSION_RELEASE: ${version_release}"
    exit
  fi
fi
echo "Building ~/petsc$version.tar.gz and ~/petsc-with-docs$version.tar.gz"

# build docs
#VENV=$PETSC_DIR/venv-petsc-docs
#python3 -m venv $VENV
#source $VENV/bin/activate
#cd $PETSC_DIR/doc
#python3 -m pip install -r requirements.txt
#make html BUILDDIR="../docs" SPHINXOPTS="-T -E"
#mv ../docs/html/* ../docs/html/.[!.]* ../docs
#make latexpdf && cp _build/latex/manual.pdf ../docs/docs/manual/
#rm -rf ../docs/doctrees
#make clean
#rm -rf images

# petsc4py docs (and fortranstubs - hence --download-sowing below) and tarball
#cd $PETSC_DIR
#export PETSC_ARCH=arch-pydoc
#python3 ./config/configure.py --with-mpi=0 --with-cxx=0 --download-sowing=1
#make all
#cd $PETSC_DIR/src/binding/petsc4py
#  make sdist PYTHON=python3 PYTHON2=python2 SHELL=/bin/bash
#  cp dist/*.gz ~/
#  make srcclean
cd $PETSC_DIR
#
make ACTION=clean tree_basic

# now tar up the PETSc tree
cd $PETSC_DIR/..
cat ${PETSC_DIR}/lib/petsc/bin/maint/xclude | sed -e s/petsc-dist/$pdir/ > $tmpdir/xclude
tar --create --file $tmpdir/petsc.tar --exclude-from  $tmpdir/xclude $pdir
cd $tmpdir
tar xf $tmpdir/petsc.tar
# just make sure we are not doing 'mv petsc petsc'
if [ ! -d petsc$version ]; then
  /bin/mv $pdir petsc$version
fi
#
# Before Creating the final tarfile, make changes to the bmakefiles/makefiles,
# create tagfiles etc. permissions etc.
#
# Eliminate chmods in the makefile & conf/rules
cd $tmpdir/petsc$version
/bin/mv makefile makefile.bak
grep -v 'chmod' makefile.bak > makefile
/bin/rm -f makefile.bak

/bin/mv lib/petsc-conf/rules lib/petsc-conf/rules.bak
grep -v 'chmod' lib/petsc-conf/rules.bak > lib/petsc-conf/rules
/bin/rm -f  lib/petsc-conf/rules.bak

#add in PETSC_VERSION_DATE, PETSC_VERSION_GIT, PETSC_VERSION_DATE_GIT
echo Using PETSC_VERSION_DATE: ${version_date}
echo Using PETSC_VERSION_GIT: ${version_git}
echo Using PETSC_VERSION_DATE_GIT: ${version_date_git}
/bin/mv include/petscversion.h include/petscversion.h.bak
cat include/petscversion.h.bak | \
  sed -e "s/#define PETSC_VERSION_DATE\ .*/#define PETSC_VERSION_DATE       \"${version_date}\"/" | \
  sed -e "s/#define PETSC_VERSION_GIT\ .*/#define PETSC_VERSION_GIT        \"${version_git}\"/" | \
  sed -e "s/#define PETSC_VERSION_DATE_GIT\ .*/#define PETSC_VERSION_DATE_GIT   \"${version_date_git}\"/" \
  > include/petscversion.h
/bin/rm -f include/petscversion.h.bak

# just to be sure
/bin/rm -rf make.log* configure.log* RDict.* RESYNC PENDING
# eliminate .pyc files if any
/usr/bin/find . -type f -name "*.pyc" -exec /bin/rm -f {} \;
# eliminate misc files mercurial leaves
/usr/bin/find . -type f -name "*.orig" -exec /bin/rm -f {} \;
# Create EMACS-TAGS
#cd $tmpdir/petsc$version; ${PETSC_DIR}/lib/petsc/bin/maint/generateetags.py

# Set the correct file permissions.
cd $tmpdir
chmod -R a-w petsc$version
chmod -R u+w petsc$version
chmod -R a+r petsc$version
find petsc$version -type d -name "*" -exec chmod a+x {} \;

# Now create the tar files
cd $tmpdir
tar -czf ~/petsc-with-docs$version.tar.gz petsc$version

# create lite version
/bin/rm -rf $tmpdir/petsc$version/docs $tmpdir/petsc$version/zope $tmpdir/petsc$version/config/BuildSystem/docs $tmpdir/petsc$version/config/examples/old
/bin/rm -rf $tmpdir/petsc$version/src/binding/petsc4py/docs
find $tmpdir/petsc$version -type f -name "*.html" -exec rm {} \;
# recreate EMACS-TAGS [after deletion]
#cd $tmpdir/petsc$version; ${PETSC_DIR}/lib/petsc/bin/maint/generateetags.py
# generate PKG-INFO for updating petsc version at pypy
cd $tmpdir/petsc$version && python3 setup.py egg_info && /bin/cp petsc.egg-info/PKG-INFO . && /bin/rm -rf petsc.egg-info config/pypi

cd $tmpdir
tar -czf ~/petsc$version.tar.gz petsc$version

#cleanup
/bin/rm -rf $tmpdir

echo "Ending date: `date +'%a, %d %b %Y %H:%M:%S %z'`"

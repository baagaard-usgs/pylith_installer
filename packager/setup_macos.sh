pylith=`pwd`

if test ! -f bin/pylith; then
    echo
    echo "*** Error! ***"
    echo
    echo "Source this script from the top-level PyLith directory:"
    echo
    echo "    cd [directory containing 'setup.sh']"
    echo "    source setup.sh"
    echo 
else
    export PATH="$pylith/bin:/bin:/usr/bin:/sbin/:/usr/sbin:$PATH"
    export PYTHONPATH="$pylith/lib/python2.7/site-packages"
    echo "Ready to run PyLith."
fi

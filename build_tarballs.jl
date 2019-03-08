# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ElTopoBuilder"
version = v"0.1.0"

# Collection of sources required to build ElTopoBuilderV2
sources = [
    "https://github.com/tysonbrochu/eltopo.git" =>
    "14b1d7cbd45def90cfce04d381e92c4fefc5fab7",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd $WORKSPACE/srcdir/eltopo/eltopo3d/

cat <<EOF > Makefile.local_defs
INCLUDE_PATH = -I. -I../common -I../common/newsparse -I../common/meshes -I../common/tunicate
DEPEND = g++ -D__LITTLE_ENDIAN__ -DUSE_FORTRAN_BLAS -DNO_GUI
CC = g++ -Wall -D__LITTLE_ENDIAN__ -DUSE_FORTRAN_BLAS -DNO_GUI -fPIC 
RELEASE_FLAGS = -O3 -funroll-loops
DEBUG_FLAGS = -g
LINK = g++
LINK_LIBS = -lGL -lGLU -lglut -llapack -lblas 
EOF

make depend
make release

cd $WORKSPACE
(cd srcdir/eltopo/eltopo3d && find . -name '*.h' -print | tar --create --files-from -) | (cd $WORKSPACE/destdir/include && tar xvfp -)
(cd srcdir/eltopo/common && find . -name '*.h' -print | tar --create --files-from -) | (cd $WORKSPACE/destdir/include && tar xvfp -)
g++ srcdir/eltopo/eltopo3d/obj/*.o destdir/lib/libopenblas.a -o destdir/lib/eltopo.so -fPIC -shared -lstdc++ -lm -lgfortran
exit

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc)
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "eltopo", :eltopo)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BinaryBuilder.InlineBuildDependency(join(readlines("build_OpenBLAS.v0.3.0.jl"),"\n"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)


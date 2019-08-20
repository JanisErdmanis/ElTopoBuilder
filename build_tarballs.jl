# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ElTopoBuilder"
version = v"0.1.3"

# Collection of sources required to build ElTopoBuilder
sources = [
    "https://github.com/tysonbrochu/eltopo.git" =>
    "14b1d7cbd45def90cfce04d381e92c4fefc5fab7",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/eltopo/eltopo3d/

cat <<EOF > Makefile.local_defs
INCLUDE_PATH = -I. -I../common -I../common/newsparse -I../common/meshes -I../common/tunicate
DEPEND = g++ -D__LITTLE_ENDIAN__ -DUSE_FORTRAN_BLAS -DNO_GUI
CC = g++ -Wall -D__LITTLE_ENDIAN__ -DUSE_FORTRAN_BLAS -DNO_GUI -fPIC 
RELEASE_FLAGS = -O3 -funroll-loops
DEBUG_FLAGS = -g
LINK = g++
LINK_LIBS = -lGL -lGLU -lglut destdir/lib/libopenblas.a
EOF

make depend
make release

cd $WORKSPACE
(cd srcdir/eltopo/eltopo3d && find . -name '*.h' -print | tar --create --files-from -) | (cd $WORKSPACE/destdir/include && tar xvfp -)
(cd srcdir/eltopo/common && find . -name '*.h' -print | tar --create --files-from -) | (cd $WORKSPACE/destdir/include && tar xvfp -)


if [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then
g++ srcdir/eltopo/eltopo3d/obj/*.o destdir/lib/libopenblas.a -o destdir/lib/eltopo.dll -fPIC -shared -lm -static-libgfortran -static-libstdc++ -fno-exceptions
else
g++ srcdir/eltopo/eltopo3d/obj/*.o destdir/lib/libopenblas.a -o destdir/lib/eltopo.so -fPIC -shared -lm -static-libgfortran -static-libstdc++
fi
"""
# -Wl,-Bstatic -lgfortran

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Windows(:x86_64),
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
# platforms = expand_gcc_versions(platforms)
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)


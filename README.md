# QEPY - Quantum ESPRESSO Python interface
   In order to use Quantum ESPRESSO in embedding code, we modified some code of quantum-espresso and compile the Python wrappers. The source code was modified based on QE-6.5 and commented out unused code.

## Requirements
 - Python 3.6 or later
 - Numpy >= 1.18
 - Intel compiler (ifort)
 - f90wrap package (latest)
 - Quantum-espresso source distribution (qe-6.5)

## Install
 - **f90wrap**

    Install the origin version:

    ```shell
	pip install git+https://github.com/jameskermode/f90wrap
    ```
	If not working, please try our modified version:

    ```shell
	pip install git+https://github.com/shaoxc/f90wrap
    ```



 - **QE**

	All static libraries must be compiled with the `-fPIC` compuiler option, so you need add `-fPIC` for all configuration. e.g.

     ```shell
	 ./configure F77=ifort F90=ifort CC=icc \
	   --with-scalapack=no -enable-openmp=yes -enable-parallel=no \
	   CFLAGS=-fPIC FFLAGS='-mcmodel=large -fPIC' FOXFLAGS=-fPIC
     ```

	Or parallel version:


     ```shell
	 ./configure F77=ifort F90=ifort CC=icc MPIF90=mpiifort \
	   --with-scalapack=intel -enable-openmp=no -enable-parallel=yes \
	   CFLAGS=-fPIC FFLAGS='-mcmodel=large -fPIC' FOXFLAGS=-fPIC
	 ```

   + After configuration, you also need add `-fPIC` to `FOX_FLAGS` in the *make.inc* file.
   + Build the normal ***pw*** or ***pwlibs***.

 - **QEPY**

   + Copy the *qepy* into the ${QE} directory.
   + Go to *qepy* directory and `make` (serial) or `make mpi` (parallel).
   + Go to *qepy* directory and `make install`.

## Tips
 - The ***QE*** and ***QEPY*** should be same version, both serial or parallel.
 - `make help` will show the information of Makefile.
 - The *variables* of Makefile can do some custom functionality.

	e.g.

	- "`export oldxml=yes`" can read old version QE xml file.
	- "`export prefix=~/.local/lib/python3.8/site-packages/`" can set the folder for installation.

## FAQ
 - Some Intel MPI/MKL errors occur
	+ Make sure same version of QE and QEPY
	+ Try `export LD_PRELOAD=/opt/intel/mkl/lib/intel64/libmkl_rt.so`

 - What's the *oldxml*?
	+ QE deleted the old format (-D\_\_OLDXML) supported from [version 6.4](https://github.com/QEF/q-e/releases/tag/qe-6.4). In order to read the output of old format XML file, so we revert some codes in QEPY.

 - Can not read the wavefunctions or wouldn't stop reading?
	+ If the wavefunctions were stored by old version QE (<6.4) or [eQE](http://eqe.rutgers.edu), please try *oldxml*.
	+ There are two different ways to store wavefunctions in QE, which is controls by PW parameter [`wf_collect`](http://www.quantum-espresso.org/Doc/INPUT_PW.html#idm68). If not sure, simply just use one processor to read.

## Todo
 - Update the Makefile to support Gfortran compiler
 - Write a python script that can automatically update the *qepy* code according to the new version of the *QE*

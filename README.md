# Installing TensorFlow on Dawn

## 1. Introduction

This is guidance for installing [TensorFlow](https://tensorflow.org/docs/stable/)
in a [conda](https://docs.conda.io/en/latest/) environment on
the [Dawn supercomputer](https://www.hpc.cam.ac.uk/d-w-n).  Dawn is
hosted at the University of Cambridge, and is part
of the [AI Resource Research (AIRR)](https://www.gov.uk/government/publications/ai-research-resource/airr-advanced-supercomputers-for-the-uk).  It was
initially installed with 256 nodes, in the form of [Dell PowerEdge XE9640](https://www.delltechnologies.com/asset/en-us/products/servers/technical-support/poweredge-xe9640-spec-sheet.pdf) servers.  Each node consisted of: 2 CPUs ([Intel Xeon Platinum 8468](https://www.intel.com/content/www/us/en/products/sku/231735/intel-xeon-platinum-8468-processor-105m-cache-2-10-ghz/specifications.html)), each with 48 cores and 512 GiB RAM; 4 GPUs ([Intel Data Centre GPU Max 1550](https://www.intel.com/content/www/us/en/products/sku/232873/intel-data-center-gpu-max-1550/specifications.html)),
each with two stacks (or tiles), 1024 compute units, and 128 GiB RAM.

The material collected here is licensed under the
[Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).

## 2. Installation

In case you don't already have your own `conda` installation, you can find
guidance for installing `conda` on Dawn at:
- [https://github.com/kh296/dawn-conda](https://github.com/kh296/dawn-conda)

Installation of TensorFlow may be performed
[via a Slurm job](#21-installation-via-a-slurm-job) or
[from the command line](#22-installation-from-the-command-line).  As the
installation takes around 15 minutes, the former is recommended

### 2.1 Installation via a Slurm job

On a Dawn login node or compute node, clone this repository,
and move to the `scripts` directory:
```
git clone https://github.com/kh296/dawn-tensorflow
cd dawn-tensorflow/scripts
```

Submit a Slurm job to run the installation script:
```
# Substitute for <project_account> a valid project account.
# Set CONDA_INSTALL to the path of your conda installation.
sbatch --account=<project_account> --export=CONDA_INSTALL="~/miniforge3" ./tensorflow_install.sh
```

Once it starts running, the script should take around 15 minutes to
complete.  The job output is written to `tensorflow_install.log`.  If the
installation is successful, the last line of the output is the command
to set up the environment for using TensorFlow.  This command references the
setup file `../envs/tensorflow-setup.sh`, created during installation.

### 2.2 Installation from the command line

On a Dawn compute node, clone this repository, and move to
the `scripts` directory:
```
git clone https://github.com/kh296/dawn-tensorflow
cd dawn-tensorflow/scripts
```

Run the installation script:
```
# Set CONDA_INSTALL to the path of your conda installation.
CONDA_INSTALL="~/miniforge3" ./tensorflow_install.sh |& tee tensorflow_install.log
```

Output is written both to terminal and to the file `tensorflow_install.log`.
If the installation is successful, the last line of the output is the command
to set up the environment for using TensorFlow.  This command references the
setup file `../envs/tensorflow-setup.sh`, created during installation.

## 3. Further information

Installation of `TensorFlow` on Dawn is based on the documentation for
[Intel XPU Software Installation](https://github.com/intel/intel-extension-for-tensorflow/blob/main/docs/install/install_for_xpu.md).

The installation script
[scripts/tensorflow_install.sh](scripts/tensorflow_install.sh)
installs the latest version of
[intel-extension-for-tensorflow](https://github.com/intel/intel-extension-for-tensorflow)
with pre-built binaries, and the compatible version of [tensorflow](https://github.com/tensorflow/tensorflow).  As of June 2026, the last version of
intel-extension-for-tensorflow is [2.15.0.3](https://github.com/intel/intel-extension-for-tensorflow/releases/tag/v2.15.0.3), released in March 2025.  The
result is that the latest version of `tensorflow` that can be used with
Intel GPUs is behind the latest main version of `tensorflow`.  If you want
to install additional packages, the suggested approach is to set up the `conda`
environment for using TensorFlow, and then install the additional packages with
`pip` or `conda`.  For example, to add `pandas`, starting from the `scripts`
directory, use:
 ```
source ../envs/tensorflow-setup.sh
pip install pandas
```

The installation script provides several options, for example allowing
installation to a `conda` environment with a name different from the default
(`tensorflow`).  For
more information, from the `scripts` directory run:
```
./tensorflow_install.sh -h
```

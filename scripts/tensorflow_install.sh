#!/bin/bash
#SBATCH --job-name=tensorflow_install # create a name for your job
#SBATCH --output=%x.log               # job output file
#SBATCH --partition=pvc9              # cluster partition to be used
#SBATCH --nodes=1                     # number of nodes
#SBATCH --gres=gpu:1                  # number of allocated gpus per node
#SBATCH --time=01:30:00               # total run time limit (HH:MM:SS)

# Script for installing TensorFlow on the Dawn supercomputer.
#
# This installation relies on the user having a conda installation
# at ${CONDA_HOME}.  If CONDA_HOME is null but CONDA_PREFIX is non-null,
# the former is set to be equal to the latter.  If both CONDA_HOME and
# CONDA_PREFIX are null, CONDA_HOME is set to ${HOME}/miniforge3.  In this
# case, if conda isn't available at ${HOME}/miniforge3 then
# the Miniforge3 flavour of conda will be installed by running
# ./miniforge3_install.sh with default settings.
# For information about the Miniforge3 flavour
# of conda, see: https://conda-forge.org/download/
# For information about ./miniforge3_install.sh, use:
# ./miniforge3_install.sh -h
#
# After installation, if the environment variable CONDA_ENV wasn't set,
# the environment for using TensorFlow can be activated by sourcing the file
# tensorflow-setup.sh, created in the directory ../envs relative to where
# the current script is run.  Otherwise, the file to source is
# ../envs/${CONDA_ENV}-setup.sh
#
# On Dawn, the current script may be run interactively on a compute node
# (not on a login node):
# bash ./tensorflow_install.sh
# or it may be submitted from a login node to the Slurm batch system:
# sbatch --account=<project account> ./tensorflow_install.sh

# Exit at first failure.
set -e

PROJECT_NAME="TensorFlow"
PROJECT_NAME_LC="$(echo ${PROJECT_NAME} | tr [:upper:] [:lower:])"

# Parse command-line options.
usage() {
    echo "usage: tensorflow_install.sh [-h] [-c <conda home>] [-e <conda env>]"
    echo "    Install TensorFlow in a conda environment."
    echo "Options:"
    echo "    -h: Print this help."
    echo "    -c: Use conda installation at <conda home>."
    echo "    -e: Create, and install to, conda environment <conda env>."
    echo "If -c omitted, path to conda installation is first non-empty string from:"
    echo "    \"\${CONDA_HOME}\", \"\${CONDA_PREFIX}\", \"\${HOME}/miniforge3\""
    echo "    If last of these is selected, conda will be installed here"
    echo "    if not already present."
    echo "If -e omitted, the name for the conda environment defaults to \"${PROJECT_NAME_LC}\"."
    echo "Any pre-existing conda environment <conda env> (specified with -e)"
    echo "    or \"${PROJECT_NAME_LC}\" (-e omitted) will be removed."
}
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h)
            usage
	    exit 0
            ;;
        -c)
            if [[ -n "$2" && "$2" != -* ]]; then
                CONDA_HOME="$2"
		shift 2
            else
                echo "-c must be followed by path to conda installation"
                usage
		exit 1
            fi
            ;;
        -e)
            if [[ -n "$2" && "$2" != -* ]]; then
                CONDA_ENV="$2"
                shift 2
            else
                echo "-e must be followed by name of conda environment"
                exit 1
            fi
            ;;
        -*)
            echo "Unknown option: $1"
            usage
	    exit 1
            ;;
    esac
done

if [[ -z "${CONDA_ENV}" ]]; then
    CONDA_ENV=${PROJECT_NAME_LC}
fi

# Determine system being used.
if [[ "$(hostname)" == "pvc-s"* ]]; then
    SYSTEM="Dawn"
elif [[ "$(hostname)" == *"-pl1"* ]]; then
    SYSTEM="aac6"
elif [[ "${OSTYPE}" == "darwin"* ]]; then
    SYSTEM="macOS"
else
    echo "Installation of ${PROJECT_NAME} for ${OSTYPE} on $(hostname) not handled"
    echo "Exiting: $(date)"
    exit
fi

# Check that conda is available.
if [ -z "${CONDA_HOME}" ]; then
    if [ -z "${CONDA_PREFIX}" ]; then
        CONDA_HOME="${HOME}/miniforge3"
        if ! [ -d "${CONDA_HOME}" ]; then
            ./miniforge3_install.sh
        fi
    else
        CONDA_HOME="${CONDA_PREFIX}"
    fi
fi

# Expand path, without following symbolic links.
CONDA_HOME="${CONDA_HOME/#\~/${HOME}}"
CONDA_HOME=$(cd "$(dirname "${CONDA_HOME}")" && pwd -P)/$(basename "${CONDA_HOME}")

if ! [ -d "${CONDA_HOME}" ]; then
    echo "Conda installation not found at ${CONDA_HOME}"
    echo "Exiting: $(date)"
    exit 2
fi

# Perform installation.
echo "Installation of ${PROJECT_NAME} for ${OSTYPE} on $(hostname) started: $(date)"
T0=${SECONDS}

# Create script for environment setup.
ENVS_DIR=$(realpath ..)/envs
mkdir -p ${ENVS_DIR}
SETUP="${ENVS_DIR}/${CONDA_ENV}-setup.sh"
DAWN_SETUP="/dev/null"
AAC6_SETUP="/dev/null"
MACOS_SETUP="/dev/null"
if [[ "Dawn" == "${SYSTEM}" ]]; then
    DAWN_SETUP="${SETUP}"
elif [[ "aac6" == "${SYSTEM}" ]]; then
    AAC6_SETUP="${SETUP}"
elif [[ "macOS" == "${SYSTEM}" ]]; then
    MACOS_SETUP="${SETUP}"
fi

rm -rf ${SETUP}
cat <<EOF >${SETUP}
# Setup script for ${CONDA_ENV} on ${SYSTEM}.
# Generated on $(hostname), $(date +"%Y-%m-%d (%a) %H:%M:%S %Z").

EOF

cat <<EOF >>${DAWN_SETUP}
# Load modules.
module purge
module load rhel9/default-dawn
EOF

cat <<EOF >>${MACOS_SETUP}
# Initialise environment variables that may be used at run time.
# Define network interface.
export GLOO_SOCKET_IFNAME="en0"
EOF

cat <<EOF >>${AAC6_SETUP}
# Load modules.
module purge
module load rocm
module load openmpi

# Set network interface for communication:
# https://docs.nvidia.com/deeplearning/nccl/user-guide/docs/env.html#nccl-socket-ifname
# Possibilities for listing network interfaces include:
# Linux: ip addr, netstat -i, ifconfig
# MacOS: networksetup -listallhardwarereports, netstat -i, ifconfig
export NCCL_SOCKET_IFNAME="enp129s0"
EOF

cat <<EOF >>${SETUP}

# Initialise conda.
source ${CONDA_HOME}/bin/activate

# Activate environment.
EOF

# Set up installation environment.
source ${SETUP}
conda update -n base -c conda-forge conda -y

# Delete any pre-existing environment.
if [ -d "${CONDA_HOME}/envs/${CONDA_ENV}" ]; then
    rm -rf ${CONDA_HOME}/envs/${CONDA_ENV}
fi

# Create and activate the environment.
CMD="conda create -n ${CONDA_ENV} -y python=3.12"
echo "${CMD}"
eval "${CMD}"
CMD="conda activate ${CONDA_ENV}"
echo "${CMD}" >> "${SETUP}"
eval "${CMD}"

# Install additional packages.
CMD="python -m pip install --upgrade pip"
echo ""
echo "Ensuring pip up to date:"
echo "${CMD}"
eval "${CMD}"
echo ""
echo "Installing packages:"

if [[ "Dawn" == "${SYSTEM}" ]]; then
    CMD1="python -m pip install tensorflow==2.15.0"
    CMD2="python -m pip install --upgrade intel-extension-for-tensorflow[xpu]"
elif [[ "aac6" == "${SYSTEM}" ]]; then
    CMD1="python -m pip install --upgrade --find-links https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2/ tensorflow-rocm==2.20.0"
    CMD2=""
elif [[ "macOS" == "${SYSTEM}" ]]; then
    CMD1="python -m pip install tensorflow==2.18.0"
    CMD2="python -m pip install tensorflow-metal==1.2.0"
fi

for CMD in "${CMD1}" "${CMD2}"; do
    if [[ -n "${CMD}" ]]; then
        echo ""
        echo "${CMD}"
        eval "${CMD}"
    fi
done

T1=${SECONDS}

# Check imports.
echo ""
echo "Performing initial imports:"
CMD="python -c 'import tensorflow'"
echo "${CMD}"
eval "${CMD}"

# Check devices.
echo ""
echo "Checking devices:"
CMD="python -c 'from tensorflow.python.client import device_lib; device_lib.list_local_devices()'"
echo "${CMD}"
eval "${CMD}"
T2=${SECONDS}

echo ""
echo "Installation of ${PROJECT_NAME} for ${OSTYPE} on $(hostname) completed: $(date)"
echo "Time for installation: $((${T1}-${T0})) seconds"
echo "Time for installation checks: $((${T2}-${T1})) seconds"

echo ""
echo "Set up environment for ${PROJECT_NAME} with:"
echo "source ${SETUP}"

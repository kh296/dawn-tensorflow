# Installing TensorFlow on AMD Accelerator Cluster

TensorFlow can be installed in a `conda` environment on the
[AMD Accelerator Cluster (AAC)](https://aac.amd.com/help/) by following
the instructions for [Installing TensorFlow on Dawn](../README.md),
except that for installation via a Slurm job the submission command needs
to be different.  In particular, it's usually not necessary
to specify the account, but it is necessary to specify the partition,
and the resources.

In case you don't already have your own `conda` installation,
first follow the guidance for [Installing conda on AMD Accelerator Cluster](https://github.com/kh296/dawn-conda).

On AAC6, after following the guidance of
[Installing TensorFlow on Dawn](../README.md)
for obtaining the TensorFlow installation script, an example submission command is:
```
# Set CONDA_INSTALL to the path of your conda installation.
sbatch --partition=1CN192C4G1H_MI300A_Ubuntu22  --cpus-per-gpu=48 --export=CONDA_INSTALL="~/miniforge3" ./tensorflow_install.sh
```

Installation of `TensorFlow` on AAC6 using
[scripts/tensorflow_install.sh](../scripts/tensorflow_install.sh)
is based on the documentation for
[TensorFlow on ROCm installation](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/install/3rd-party/tensorflow-install.html).

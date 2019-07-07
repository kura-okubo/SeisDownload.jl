# SeisDownload.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://kura-okubo.github.io/SeisDownload.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://kura-okubo.github.io/SeisDownload.jl/dev)
[![Build Status](https://travis-ci.com/kura-okubo/SeisDownload.jl.svg?branch=master)](https://travis-ci.com/kura-okubo/SeisDownload.jl)
[![Codecov](https://codecov.io/gh/kura-okubo/SeisDownload.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/kura-okubo/SeisDownload.jl)

**Download seismic waveform from data server.**


- Download from earthquake data center with multiple processors
- All data (metadata, waveform, fft, ...) is saved in the form of [SeisData](https://seisio.readthedocs.io/en/latest/src/working_with_data.html) structure with [SeisIO.jl®](https://github.com/jpjones76/SeisIO.jl).

## Installation

Then from the Julia command prompt:

1. Press ] to enter pkg.
2. Type or copy: `add https://github.com/kura-okubo/SeisDownload.jl`
3. Press backspace to exit pkg.
4. Type or copy: `using Pkg; Pkg.build("SeisDownload"); using SeisDownload`

## Example
You can download data using `seisdownload`:
to run the example script:

  1. cp `~/.julia/packages/SeisDownload/(versionID)/EXAMPLE/` somewhere and cd `EXAMPLE/Noise_BP`
  2. type `julia -p 3 exec.jl`

- `-p` is num of **additional** processes (= np - 1 parallelizes your processes with your all processors).  

More information; see `EXAMPLE` directory.

## Installation Q&A
- Please run with obspy enviroment.
Anaconda environment is useful; see [link](https://github.com/obspy/obspy/wiki/Installation-via-Anaconda). This package is stable with python 3.7.3.

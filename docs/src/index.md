# SeisDownload.jl

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

  1. cp `EXAMPLE/` somewhere and cd `EXAMPLE/Noise_BP`
  2. type `julia -p 3 exec.jl`

**Please specify number of processes with -p**

More information; see `EXAMPLE` directory.

## Installation Q&A
- Please run with obspy enviroment.
Anaconda environment is useful; see [link](https://github.com/obspy/obspy/wiki/Installation-via-Anaconda). This package is stable with python 3.7.3.

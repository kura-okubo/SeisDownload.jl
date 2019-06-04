# SeisDownload.jl

**Download seismic waveform from data server.**

- Download from earthquake data center
- Pre-processing (tapering, filling time gap, bandpass filter, downsampling) with [Noise.jl®](https://github.com/tclements/Noise.jl)
- Computing fft of waveform at the same time
- All data (metadata, waveform, fft, ...) is saved in the form of [SeisData](https://seisio.readthedocs.io/en/latest/src/working_with_data.html) structure with [SeisIO.jl®](https://github.com/jpjones76/SeisIO.jl).

## Installation

This package depends on [SeisIO.jl®](https://github.com/jpjones76/SeisIO.jl) and [Noise.jl®](https://github.com/tclements/Noise.jl), so please download these modules first.

Then from the Julia command prompt:

1. Press ] to enter pkg.
2. Type or copy: add https://github.com/kura-okubo/SeisDownload.jl; build; precompile
3. Press backspace to exit pkg.
4. Type or copy: using SeisDownload

## Example
You can download data using `seisdownload`:
>seisdownload(network, station, location, channels, datacenter, servername, starttime, endtime, save\_time\_unit [s], "outputfilename")

to run the example script:

  1. cd to `EXAMPLE/Download_BP`
  2. type `sh run_downloadsctipt.sh`

More information; see `EXAMPLE` directory.

```@index
```

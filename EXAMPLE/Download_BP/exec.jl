"""
Download seismic data from server and save to JLD2 file.

June 3, 2019
Kurama Okubo
"""

include("../../src/SeisDownload.jl")
#using SeisIO, Dates, SeisDownload
using SeisIO, Dates, .SeisDownload #Please load SeisIO here to correctly define type of structure "SeisData"

#---parameters---#
network     = ["BP"]
#station    = ["LCCB", "MMNB", "VCAB", "CCRB"]
station     = ["LCCB", "MMNB"]
#channels   = ["BP1", "BP2", "BP3"]
location    = [""]
channels    = ["BP1"]
datacenter  = "NCEDC" #Data center
src         = "NCEDC"

starttime   = DateTime(2004,9,28,0,0,0)
endtime     = DateTime(2004,9,29,0,0,0)
CC_time_unit = 3600 # minimum time unit for cross-correlation [s]
foname      = "BPnetwork"

pre_filt    = (0.001, 0.002, 10.0, 20.0) #prefilter of remove_response: taper between f1 and f2, f3 and f4
downsample_fs = 20; #downsampling rate after filtering

#----------------#

# create dataset directory
mkpath("./dataset")
fopath=("./dataset/"*foname*".jld2")

# download data
seisdownload(network, station, location, channels, datacenter, src, starttime, endtime, float(CC_time_unit), fopath;
            pre_filt=pre_filt, downsample_fs=float(downsample_fs), IsRemoveStationXML=true)

using SeisDownload
using Test

using SeisIO, Dates #Please load SeisIO here to correctly define type of structure "SeisData"

@testset "SeisDownload.jl" begin
    # Write your own tests here.
    #---parameters---#
    network     = ["NZ"]
    station     = ["BFZ"]
    location    = ["20"]
    channels    = ["BNE"]
    datacenter  = "FDSN" #Data center
    src         = "IRIS"

    starttime   = DateTime(2016,11,13,12,0,0)
    endtime     = DateTime(2016,11,13,13,0,0)
    CC_time_unit = 3600 # minimum time unit for cross-correlation [s]
    foname      = "test"

    pre_filt    = (0.001, 0.002, 10.0, 20.0) #prefilter of remove_response: taper between f1 and f2, f3 and f4
    downsample_fs = 20; #downsampling rate after filtering

    #----------------#

    # create dataset directory
    mkpath("./dataset")
    fopath=("./dataset/"*foname*".jld2")

    # download data
    # Because obspy emvironment is not in Travis server, we temporary skip this test
    # @test 0 == seisdownload(network, station, location, channels, datacenter, src, starttime, endtime, float(CC_time_unit), fopath;
    #            pre_filt=pre_filt, downsample_fs=float(downsample_fs), IsRemoveStationXML=true)
    #rm(fopath)
    @test 1 == 1 + 1 - 1 

end

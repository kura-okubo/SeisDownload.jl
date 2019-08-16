using SeisDownload
using Test

using SeisIO, Dates  #Please load SeisIO here to correctly define type of structure "SeisData"

@testset "SeisDownload.jl" begin
    # Write your own tests here.
    #==================================================#
    # Input Parameters
    MAX_MEM_PER_CPU = 1.0 # [GB] maximum allocated memory for one cpu
    DownloadType = "Noise" # Choise of "Noise" or "Earthquake"

    #station =[""]
    # Time info for Noise case
    starttime   = DateTime(2004,8,20,12,0,0)
    endtime     = DateTime(2004,8,20,14,0,0)

    #locationbox   = [35.1811, 36.4323, -118.5294, -116.6171]
    IsLocationBox = false

    datasource = "NCEDC" # currently, only one src can be specified.
    #station = ["CCRB","EADB","FROB","GHIB","JCNB","JCSB","LCCB","MMNB", "RMNB", "SCYB","SMNB","VARB","VCAB"]

    DL_time_unit = 3600 * 1 #3600 * 24 # Download time unit [s] more than one day is better to avoid artifacts of response removal
    download_margin = 60 * 5 #Int, [s] margin of both edges while downloading data to avoid the edge effect due to instrument response removal.

    savesamplefreq = 20.0 #[1/s] when saving the data, downsample at this freq

    IsResponseRemove = true #whether instrumental response is removed or not
    #pre_filt    = (0.001, 0.002, 10.0, 20.0) #prefilter tuple used obspy remove_response: taper between f1 and f2, f3 and f4 with obspy

    fodir       = "./dataset"
    foname      = "testdata" # data is saved at ./dataset/$foname.jld2
    outputformat = "JLD2"   # output format can be JLD2, (under implementing; ASDF, SAC, ...)
    Istmpfilepreserved = false # if true, do not delete intermediate tmp files
    #==================================================#

    # store metadata in Dictionary
    # This can be customized by users

    stationlist      = String[]
    stationmethod    = String[]
    stationsrc       = String[]

    #for CI
    network     = ["BP"]
    station = ["*"]
    location    = [""]
    channel     = ["BP1"]
    datasource = "NCEDC" # currently, only one src can be specified.

    for i=1:length(network)
        for j=1:length(station)
            for k=1:length(location)
                for l=1:length(channel)
                    stationname = join([network[i], station[j], location[k], channel[l]], ".")
                    push!(stationlist, stationname)

                    #Here should be improved for multiple seismic network; we have to make
                    #proper conbination of request station and data server.
                    push!(stationmethod, "FDSN")
                    push!(stationsrc, datasource)
                end
            end
        end
    end


    stationinfo = Dict(["stationlist" => stationlist, "stationmethod" => stationmethod, "stationsrc" => stationsrc])

    mkpath(fodir)
    fopath=joinpath(fodir, foname*".jld2")

    #if lat-log box or not
    IsLocationBox ? reg=locationbox : reg=[]

    InputDictionary = Dict([
        "MAX_MEM_PER_CPU" => MAX_MEM_PER_CPU,
        "DownloadType"=> DownloadType,
        "stationinfo" => stationinfo,
        "starttime"   => starttime,
        "endtime"     => endtime,
        "DL_time_unit"     => DL_time_unit,
        "IsLocationBox"    => IsLocationBox,
        "reg"              => reg,
        "IsResponseRemove" => IsResponseRemove,
        "download_margin"  => download_margin,
        "fopath"           => fopath,
        "savesamplefreq"   => savesamplefreq,
        "outputformat"     => outputformat,
        "Istmpfilepreserved" => Istmpfilepreserved,
        "IsXMLfileRemoved" =>true
    ])

    # mass request with input Dictionary
    @test 0 == SeisDownload.seisdownload(InputDictionary)

end

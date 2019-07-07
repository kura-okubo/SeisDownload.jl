using SeisDownload
using Test

using SeisIO, Dates #Please load SeisIO here to correctly define type of structure "SeisData"

@testset "SeisDownload.jl" begin
    # Write your own tests here.

    #==================================================#
    using Distributed
    addprocs(1)
    @everywhere using SeisDownload
    using Dates

    #==================================================#
    # Input Parameters
    MAX_MEM_PER_CPU = 2.0 # [GB] maximum allocated memory for one cpu
    DownloadType = "Noise" # Choise of "Noise" or "Earthquake"

    network     = ["BP"]
    station     = ["LCCB", "MMNB"]
    #station = ["CCRB","EADB","FROB","GHIB","JCNB","JCSB","LCCB","MMNB","SCYB","SMNB","VARB","VCAB"]

    location    = [""]
    channel     = ["BP1"]
    datacenter  = "FDSN" #Data center
    src         = "NCEDC"

    # Time info for Noise case
    starttime   = DateTime(2004,9,2,0,0,0)
    endtime     = DateTime(2004,9,2,2,0,0)

    IsLocationBox = false
    method  = "FDSN" # Method to download data.
    datasource = "NCEDC" # currently, only one src can be specified.

    DL_time_unit = 3600 * 1 #3600 * 24 # Download tiem unit [s] more than one day is better to avoid artifacts of response removal

    IsResponseRemove = false #whether instrumental response is removed or not
    pre_filt    = (0.001, 0.002, 10.0, 20.0) #prefilter tuple used obspy remove_response: taper between f1 and f2, f3 and f4 with obspy

    fodir       = "./dataset"
    foname      = "BPnetwork" # data is saved at ./dataset/$foname.jld2
    #==================================================#

    # store metadata in Dictionary
    # This can be customized by users

    stationlist       = String[]
    stationmethod    = String[]
    stationsrc        = String[]
    for i=1:length(network)
        for j=1:length(station)
            for k=1:length(location)
                for l=1:length(channel)
                    stationname = join([network[i], station[j], location[k], channel[l]], ".")
                    push!(stationlist, stationname)

                    #Here should be improved for multiple seismic network; we have to make
                    #proper conbination of request station and data server.
                    push!(stationmethod, method)
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
    IsResponseRemove ? pre_filt = pre_filt : pre_filt = []

    InputDictionary = Dict([
            "DownloadType"=> DownloadType,
            "stationinfo" => stationinfo,
            "starttime"   => starttime,
            "endtime"     => endtime,
            "DL_time_unit"=> DL_time_unit,
            "IsLocationBox"   => IsLocationBox,
            "reg"             => reg,
            "IsResponseRemove"=> IsResponseRemove,
            "pre_filt"        => pre_filt,
            "fopath"          => fopath,
            "IsXMLfileRemoved" => true
        ])

    # mass request with input Dictionary
    @test 0 == seisdownload(InputDictionary, MAX_MEM_PER_CPU=float(MAX_MEM_PER_CPU))

end

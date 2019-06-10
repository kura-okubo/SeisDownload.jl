using SeisIO, Dates, Distributed

# with β version, please import SeisDownload.jl from the src directory as follows
include("./src/SeisDownload.jl")
using .SeisDownload


#==================================================#
# Input Parameters
NP = 4 # number of processor
MAX_MEM_PER_CPU = 2.0 # [GB] maximum allocated memory for one cpu
DownloadType = "Noise" # Choise of "Noise" or "Earthquake"

network     = ["BP"]
station     = ["LCCB", "HQUAKE"]
#station = ["CCRB","EADB","FROB","GHIB","JCNB","JCSB","LCCB","MMNB","SCYB","SMNB","VARB","VCAB"]

location    = [""]
channel     = ["BP1"]
datacenter  = "FDSN" #Data center
src         = "NCEDC"

# Time info for Noise case
starttime   = DateTime(2004,9,25,0,0,0)
endtime     = DateTime(2004,9,25,3,0,0)
#endtime     = DateTime(2004,10,2,0,0,0)
DL_time_unit = 3600 * 1 #3600 * 24 # Download tiem unit [s] more than one day is better to avoid artifacts of response removal

pre_filt    = (0.001, 0.002, 10.0, 20.0) #prefilter tuple used obspy remove_response: taper between f1 and f2, f3 and f4 with obspy

foname      = "BPnetwork" # data is saved at ./dataset/$foname.jld2
#==================================================#


# allocate cpus
addprocs(NP-1)

@everywhere include("./src/SeisDownload.jl")
@everywhere include("./src/utils.jl")
#using SeisIO, Dates, SeisDownload
@everywhere using .SeisDownload, .Utils

# store metadata in Dictionary
# This can be customized by users

stationlist       = String[]
stationdatacenter = String[]
stationsrc        = String[]
for i=1:length(network)
    for j=1:length(station)
        for k=1:length(location)
            for l=1:length(channel)
                stationname = join([network[i], station[j], location[k], channel[l]], ".")
                push!(stationlist, stationname)

                #Here should be improved for multiple seismic network; we have to make
                #proper conbination of request station and data server.
                push!(stationdatacenter, datacenter)
                push!(stationsrc, src)
            end
        end
    end
end

stationinfo = Dict(["stationlist" => stationlist, "stationdatacenter" => stationdatacenter, "stationsrc" => stationsrc])

mkpath("./dataset")
fopath=("./dataset/"*foname*".jld2")

InputDictionary = Dict([
      "DownloadType"=> DownloadType,
      "stationinfo" => stationinfo,
      "starttime"   => starttime,
      "endtime"     => endtime,
      "DL_time_unit"=> DL_time_unit,
      "pre_filt"    => pre_filt,
      "fopath"      => fopath
    ])


# mass request with input Dictionary
SeisDownload.ParallelSeisrequest(NP, InputDictionary, MAX_MEM_PER_CPU=float(MAX_MEM_PER_CPU))

using SeisIO, Dates, Distributed, LightXML

# with β version, please import SeisDownload.jl from the src directory as follows
#include("../src/SeisDownload.jl")
include("./src/SeisDownload.jl")
using .SeisDownload


#==================================================#
# Input Parameters
NP = 2 # number of processor
MAX_MEM_PER_CPU = 2.0 # [GB] maximum allocated memory for one cpu
DownloadType = "Earthquake" # Choise of "Noise" or "Earthquake"

network     = ["NZ"] #Currently only one network is available when you want to specify.
#station     = ["BTWS", "CCCC"]
station     = ["BTWS", "CCCC"]
location    = ["*", "*"]
channel     = ["BN?", "BN?"]


#Specify region [lat_min, lat_max, lon_min, lon_max, dep_min, dep_max], with lat, lon in decimal degrees (°) and depth in km with + = down.
#dep_min and dep_max is optional.
#reg = [-46.1691, -40.0662, 166.6531, 176.3965, -2, 30]
IsLocationBox = true
#locationbox = [-46.1691, -40.0662, 166.6531, 176.3965]
locationbox = [-43.6281, -42.5271, 170.4885, 172.1777]

method  = "FDSN" # Method to download data.

datasource = "GEONET" # currently, only one src can be specified.

SecondsBeforePick = 10 # [s] start downloading `SecondsBeforePick`[s] before picked time
SecondsAfterPick  = 10 * 60 # [s] end downloading `SecondsBeforePick`[s] after picked time

# Time info for Noise case
catalog  = "./Earthquake_NZ_GEONET/fdsnws-event_NZ_GEONET.xml"

IsResponseRemove = false #whether instrumental response is removed or not
pre_filt    = (0.001, 0.002, 10.0, 20.0) #prefilter tuple used obspy remove_response: taper between f1 and f2, f3 and f4 with obspy

fodir       = "./dataset"
foname      = "NZ_GEONETquake" # data is saved at ./dataset/$foname.jld2
#==================================================#

#-------------allocate cpus-------------#
if nprocs() < NP addprocs(NP - nprocs()) end

@everywhere include("./src/SeisDownload.jl")
@everywhere using .SeisDownload
#@everywhere include("./src/utils.jl")
#using SeisIO, Dates, SeisDownload
#@everywhere using .SeisDownload, .Utils

#----------------------------------------#

# Read QuakeML
# This can be customized by users

xdoc = parse_file(catalog)
xroot = root(xdoc)  # an instance of XMLElement
# print its name
ces = collect(child_elements(xroot))
ev = ces[1]["event"]
Ne = length(ev)

event = [] # event information (starttime, lat, lon, mag...)

for i = 1:Ne

    #datafile = fodir * "/picks_waveforms_quake_indx_" * string(i) * ".jld2"
    #println(datafile)
    # number of phase picked for that event
    #Npicks = length(dict2["events"][i]["picks"])

    #---Lat-long test with one phase pick among all stations---#

    Npicks = 2
    println("index of quake ", i, " Number of picks  ",Npicks)

    #event information
    publicid    = attribute(ev[i]["origin"][1], "publicID")
    catalog     = attribute(ev[i]["origin"][1], "catalog")
    time        = content(ev[i]["origin"][1]["time"][1])[2:end-1]
    latitude    = content(ev[i]["origin"][1]["latitude"][1])[2:end-1]
    longitude   = content(ev[i]["origin"][1]["longitude"][1])[2:end-1]
    depth       = content(ev[i]["origin"][1]["depth"][1])[2:end-1]
    magnitude   = content(ev[i]["magnitude"][1]["mag"][1])[2:end-1]
    type        = content(ev[i]["magnitude"][1]["type"][1])
    origin      = Dict("publicid" => publicid, "catalog" => catalog, "time" => time,
    "latitude"=>latitude, "longitude"=>longitude, "depth"=>depth, "magnitude"=>magnitude, "type"=>type)

    # loop through all phase picked
    # create a dictionary for each quake with channel information and time.
    ptime=Vector{String}(undef,Npicks)
    net=Vector{String}(undef,Npicks)
    sta=Vector{String}(undef,Npicks)
    cha=Vector{String}(undef,Npicks)
    loc=Vector{String}(undef,Npicks)
    src=Vector{String}(undef,Npicks)

    pickphase_dict = []

    for j=1:Npicks
        println(j)
        #ptime[j]=dict2["events"][i]["picks"][j]["time"]  # start time of pick
        ptime[j] = content(ev[i]["origin"][1]["time"][1])[2:end-1]

        #net[j] = dict2["events"][i]["picks"][j]["waveform_id"]["network_code"] # network code
        #sta[j] = dict2["events"][i]["picks"][j]["waveform_id"]["station_code"] # station code
        #cha[j] = dict2["events"][i]["picks"][j]["waveform_id"]["channel_code"] # channel code
        net[j] = network[1] # network code
        sta[j] = station[j] # station code
        loc[j] = location[j] # station code
        cha[j] = channel[j] # channel code
        src[j] = datasource # data center

        # prints for sanity checkes
        # println(ptime[j]," ",net[j]," ",sta[j]," ",cha[j])
        # println(typeof(ptime[j][1:4]))
        # println(parse(Int32,ptime[j][1:4]))
        # yy=parse(Int32,ptime[j][1:4])
        # mm=parse(Int32,ptime[j][6:7])
        # dd=parse(Int32,ptime[j][9:10])
        # hh=parse(Int32,ptime[j][12:13])
        # mn=parse(Int32,ptime[j][15:16])
        # ss=parse(Int32,ptime[j][18:19])
        # ms=parse(Int32,ptime[j][21:23])
        # make datetime object of ptime:
        #starttime = DateTime(yy,mm,dd,hh,mn,ss,ms)

        starttime = DateTime(ptime[j])
        starttime = starttime - Dates.Second(SecondsBeforePick)
        endtime  = starttime + Dates.Second(SecondsAfterPick)
        # prints for sanity check
        println(starttime)
        println(endtime)

        pdict_temp = Dict("starttime" => starttime, "endtime" => endtime,
         "net" => net[j], "sta" => sta[j], "loc" => loc[j], "cha" => cha[j], "src" => src[j])

        push!(pickphase_dict, pdict_temp)

    end

    event_temp = Dict("origin" => origin, "pickphase" => pickphase_dict)
    push!(event, event_temp)
end

free(xdoc)

mkpath(fodir)
fopath=joinpath(fodir, foname*".jld2")

#if lat-log box or not
IsLocationBox ? reg=locationbox : reg=[]
IsResponseRemove ? pre_filt = pre_filt : pre_filt = []

InputDictionary = Dict([
      "DownloadType"    => DownloadType,
      "method"          => method,
      "event"           => event,
      "IsLocationBox"   => IsLocationBox,
      "reg"             => reg,
      "IsResponseRemove"=> IsResponseRemove,
      "pre_filt"        => pre_filt,
      "fopath"          => fopath

    ])


# mass request with input Dictionary
SeisDownload.seisdownload(NP, InputDictionary, MAX_MEM_PER_CPU=float(MAX_MEM_PER_CPU))

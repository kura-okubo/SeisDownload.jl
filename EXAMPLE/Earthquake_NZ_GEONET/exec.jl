@everywhere using SeisDownload, Dates
using Dates, JSON

#==================================================#
# Input Parameters
MAX_MEM_PER_CPU = 2.0 # [GB] maximum allocated memory for one cpu
DownloadType = "Earthquake" # Choise of "Noise" or "Earthquake"

IsLocationBox = false

method  = "FDSN" # Method to download data.

datasource = "GEONET" # currently, only one src can be specified.

IsResponseRemove = false #whether instrumental response is removed or not
pre_filt    = (0.001, 0.002, 10.0, 20.0) #prefilter tuple used obspy remove_response: taper between f1 and f2, f3 and f4 with obspy

fodir       = "./dataset"
foname      = "NZ_GEONETquake" # data is saved at ./dataset/$foname.jld2
#==================================================#

# read the dictionary of the phase picks from Calum's json file.
dict2 = Dict()
f = open("at_least_five_stations_repicked_with_origins.json")
dict2 = JSON.parse(f)
close(f)

# start reading the catalog
Ne=length(dict2["events"])

for i=1:Ne
    # number of phase picked for that event
    Npicks = length(dict2["events"][i]["picks"])
    println("index of quake ", i, "Number of picks  ",Npicks)


    #event information
    publicid    = nothing#dict2["events"][i]["origins"][1]["publicID"]
    catalog     = "Chamberlain19"#dict2["events"][i]["origins"][1]["catalog"]
    latitude    =dict2["events"][i]["origins"][1]["latitude"]
    longitude   =dict2["events"][i]["origins"][1]["longitude"]
    depth       =dict2["events"][i]["origins"][1]["depth"]/1E3
    type=nothing
    magnitude=nothing
    isempty(dict2["events"][i]["magnitudes"])  ? magnitude : magnitude=dict2["events"][i]["magnitudes"][1]

    time       =dict2["events"][i]["origins"][1]["time"]
    origin      = Dict("publicid" => publicid, "catalog" => catalog, "time" => time,
    "latitude"=>latitude, "longitude"=>longitude, "depth"=>depth, "magnitude"=>magnitude, "type"=>type)


    # create a dictionary for each quake with channel information and time.
    ptime=Vector{String}(undef,Npicks)
    net=Vector{String}(undef,Npicks)
    sta=Vector{String}(undef,Npicks)
    cha=Vector{String}(undef,Npicks)
    src=Vector{String}(undef,Npicks)

    pickphase_dict=[]
    # loop through all phase picked
    df = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.ss")
    for j=1:Npicks
        ptime[j]=dict2["events"][i]["picks"][j]["time"][1:end-5]  # start time of pick
        net[j] = dict2["events"][i]["picks"][j]["waveform_id"]["network_code"] # network code
        sta[j] = dict2["events"][i]["picks"][j]["waveform_id"]["station_code"] # station code
        cha[j] = dict2["events"][i]["picks"][j]["waveform_id"]["channel_code"] # channel code
        src[j] = datasource # data center

        # prints for sanity checkes
        println(ptime[j]," ",net[j]," ",sta[j]," ",cha[j])
#         # make datetime object of ptime:
        starttime=DateTime(ptime[j],df)
        starttime = starttime - Dates.Second(60)
        endtime  = starttime + Dates.Second(30*60)
        println(starttime,endtime)
        pdict_temp = Dict("starttime" => starttime, "endtime" => endtime,
         "net" => net[j], "sta" => sta[j], "loc" => loc[j], "cha" => cha[j], "src" => src[j])

        push!(pickphase_dict, pdict_temp)
    end

    event_temp = Dict("origin" => origin, "pickphase" => pickphase_dict)
    push!(event, event_temp)
end

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
seisdownload(InputDictionary, MAX_MEM_PER_CPU=float(MAX_MEM_PER_CPU))

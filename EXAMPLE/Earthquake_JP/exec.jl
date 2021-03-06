@everywhere using SeisDownload
using Dates, LightXML

#==================================================#
# Input Parameters
MAX_MEM_PER_CPU = 2.0 # [GB] maximum allocated memory for one cpu
DownloadType = "Earthquake" # Choise of "Noise" or "Earthquake"

network     = ["*"] #Currently only one network is available when you want to specify.
station     = ["*"]
location    = ["*"]
channel     = ["BH?"]

#Specify region [lat_min, lat_max, lon_min, lon_max, dep_min, dep_max], with lat, lon in decimal degrees (°) and depth in km with + = down.
#dep_min and dep_max is optional.
IsLocationBox = true
locationbox   = [30.9332, 41.4757, 129.9166, 145.3711]

method      = "FDSN" # Method to download data.
datasource  = "IRIS"

SecondsBeforePick = 10 # [s] start downloading `SecondsBeforePick`[s] before picked time
SecondsAfterPick  = 10 * 60 # [s] end downloading `SecondsBeforePick`[s] after picked time

# Time info for Noise case
catalog  = "./fdsnws-event_JP.xml" #QuakeML format

IsResponseRemove = true #whether instrumental response is removed or not
pre_filt    = (0.001, 0.002, 10.0, 20.0) #prefilter tuple used obspy remove_response: taper between f1 and f2, f3 and f4 with obspy

fodir       = "./dataset"
foname      = "JPquake" # data is saved at ./dataset/$foname.jld2
#==================================================#

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

    Npicks = 1
    #println("index of quake ", i, " Number of picks  ",Npicks)

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
        ptime[j] = content(ev[i]["origin"][1]["time"][1])[2:end-1]

        net[j] = network[1] # network code
        sta[j] = station[1] # station code
        loc[j] = location[1] # station code
        cha[j] = channel[1] # channel code
        src[j] = datasource # data center

        starttime = DateTime(ptime[j])
        starttime = starttime - Dates.Second(SecondsBeforePick)
        endtime  = starttime + Dates.Second(SecondsAfterPick)
        # prints for sanity check

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
seisdownload(InputDictionary, MAX_MEM_PER_CPU=float(MAX_MEM_PER_CPU))

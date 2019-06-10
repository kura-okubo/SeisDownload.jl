ENV["CC"]="/usr/local/bin/mpicc"
ENV["FC"]="/usr/local/bin/mpif90"
ENV["PYTHON"]="/Users/marinedenolle/anaconda3/envs/obspy/bin/python"
using JSON, Plots, MPI, Dates, SeisIO, SeisDownload

# read the dictionary of the phase picks from Calum's json file.
dict2 = Dict()
f = open("at_least_five_stations_repicked_with_origins.json")
dict2 = JSON.parse(f)
close(f)

# make quake dictionary  with : time, lat, long, depth, mag
Ne=length(dict2["events"])
otime=Vector{String}(undef,Ne)
elat=Array{Float64}(undef,Ne)
elon=Array{Float64}(undef,Ne)
edp=Array{Float64}(undef,Ne)
mag=Array{Float64}(undef,Ne)
D = Dict("otime" =>otime,"elat"=>elat,"elon"=>elon,"edp"=>edp,"mag"=>mag)
for i=1:Ne
    elat[i]=dict2["events"][i]["origins"][1]["latitude"]
    elon[i]=dict2["events"][i]["origins"][1]["longitude"]
    edp[i]=dict2["events"][i]["origins"][1]["depth"]
    isempty(dict2["events"][i]["magnitudes"])  ? mag[i] : mag[i]=dict2["events"][i]["magnitudes"][1]
end


# plot catalog (WORK IN PROGRESS, NEED TO MAKE A MAP)
elon2 = push!(elon,-minimum(elon))
elat2 = push!(elat,-minimum(elat))
plot(elon2[1:1000]*111.25,elat2[1:1000]*111.25,-edp[1:1000]/1E3,seriestype=:scatter,title="Quake locations",
    xlabel="Longitude (km)",ylabel="Latitude (km)",zlabel="depth (km)",legend=false)
# need to improve: add grids, axis equal, reduce marker size, add map of faults.


# for each quake, make a dictionary of the picks
println("ok go")

pre_filt    = (0.001, 0.002, 10.0, 20.0) #prefilter of remove_response: taper between f1 and f2, f3 and f4
downsample_fs = 20; #downsampling rate after filtering
datacenter  = "FDSN" #Data center
src         = "GEONET"

for i=1:Ne
    datafile = dir1 * "picks_waveforms_quake_indx_" * i * ".jld2"
    pinitln(datafile)
    # number of phase picked for that event
    Npicks = length(dict2["events"][i]["picks"])
    println("index of quake ", i, "Number of picks  ",Npicks)
    # create a dictionary for each quake with channel information and time.
    ptime=Vector{String}(undef,Npicks)
    net=Vector{String}(undef,Npicks)
    sta=Vector{String}(undef,Npicks)
    cha=Vector{String}(undef,Npicks)
    Dp = Dict("ptime" =>ptime,"net"=>net,"sta"=>sta,"cha"=>cha)
    # loop through all phase picked
        for j=1:Npicks
            ptime[j]=dict2["events"][i]["picks"][j]["time"]  # start time of pick
            net[j] = dict2["events"][i]["picks"][j]["waveform_id"]["network_code"] # network code
            sta[j] = dict2["events"][i]["picks"][j]["waveform_id"]["station_code"] # station code
            cha[j] = dict2["events"][i]["picks"][j]["waveform_id"]["channel_code"] # channel code

            # prints for sanity checkes
            println(ptime[j]," ",net[j]," ",sta[j]," ",cha[j])
            println(typeof(ptime[j][1:4]))
            println(parse(Int32,ptime[j][1:4]))
            yy=parse(Int32,ptime[j][1:4])
            mm=parse(Int32,ptime[j][6:7])
            dd=parse(Int32,ptime[j][9:10])
            hh=parse(Int32,ptime[j][12:13])
            mn=parse(Int32,ptime[j][15:16])
            ss=parse(Int32,ptime[j][18:19])
            ms=parse(Int32,ptime[j][21:23])
#         # make datetime object of ptime:
            starttime=DateTime(yy,mm,dd,hh,mn,ss,ms)
            starttime = starttime - Dates.Second(60)
            endtime  = starttime + Dates.Second(30*60)
            # prints for sanity check
            println(starttime)
            println(endtime)
    end
    # download data.
    seisdownload(net, sta, location, cha, "NZ", src, starttime, endtime, float(CC_time_unit), fopath;
            pre_filt=pre_filt, downsample_fs=float(downsample_fs), IsRemoveStationXML=false)
    break
end

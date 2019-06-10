__precompile__()
module Utils
# with β version, please import SeisDownload.jl from the src directory as follows

include("downloadfunc.jl")
using .DownloadFunc

using SeisIO, Printf, Dates, JLD2, FileIO

export get_starttimelist, get_timestamplist, get_stationlist, testdownload, initlogo

"""

get_starttimelist(st::DateTime, et::DateTime, unittime::Float64)
calculate start time list for parallel downloading

    st: start time
    et: end time
    unittime: unit time in Second

    this function returns
    stlist: list of start time

    e.g.
    st = DateTime(2019,1,1,0,0,0)
    et = DateTime(2019,1,1,12,0,0)
    unittime = 3600

    stlist = get_starttimelist(st, et, unittime)

"""
function get_starttimelist(st::DateTime, et::DateTime, unittime::Real)

    reftime = st
    stlist = []

    while reftime <= et
        push!(stlist, string(reftime))
        reftime += Dates.Second(float(unittime))
    end

    return stlist
end

"""
    get_timestamplist(stlist::Array{DateTime, 1})

    returns list of timestamp: Format = "Year_Julianday_Starttime".

"""
function get_timestamplist(stlist::Array{Any,1})

    timestamplist = []
    for stid = 1:length(stlist)
        yj = parse(Int64,stlist[stid][1:4])
        dj = md2j(yj, parse(Int64,stlist[stid][6:7]), parse(Int64,stlist[stid][9:10]))
        groupname    = string(yj)*"."*string(dj)*"."*stlist[stid][11:19] #Year_Julianday_Starttime
        push!(timestamplist, groupname)
    end

    return timestamplist

end

"""
    get_stationlist(network::Array{String, 1}, station::Array{String, 1}, location::Array{String, 1}, channel::Array{String, 1})

    returns list of request strings:

"""
function get_stationlist(network::Array{String, 1}, station::Array{String, 1}, location::Array{String, 1}, channel::Array{String, 1})

    stationlist = []
    for networkid = 1:length(network)
        for stationid = 1:length(station)
            for locationid = 1:length(location)
                for channelid = 1:length(channel)
                    requeststr = @sprintf("%s.%s.%s.%s", network[networkid], station[stationid], location[locationid], channel[channelid])
                    push!(stationlist, requeststr)
                end
            end
        end
    end

    return stationlist

end

"""
    testdownload(NP::Int, InputDict::Dict{String,Any}, MAX_MEM_PER_CPU::Float64=1.0, numofitr::Int64)

    print stats of download and return max_num_of_processes_per_parallelcycle

# Output
 -`max_num_of_processes_per_parallelcycle`: maximum number of processes for one request

"""
function testdownload(NP::Int64, InputDict::Dict{String,Any}, numofitr::Int64, MAX_MEM_PER_CPU::Float64=1.0)

    KB = 1024.0 #[bytes]
    MB = 1024.0 * KB
    GB = 1024.0 * MB

    DownloadType    = InputDict["DownloadType"]

    trial_id        = 1

    println("-------TEST DOWNLOAD START-----------")

    if DownloadType == "Noise" || DownloadType == "noise"

        while true
            global t1 = @elapsed global Stest = seisdownload_NOISE(trial_id, InputDict) #[s]
            if Stest[1].misc["dlerror"] == 0
                break;
            else
                trial_id += 1
            end
        end

    elseif  DownloadType == "Earthquake" || DownloadType == "earthquake"

        while true
            global t1 = @elapsed global Stest = seisdownload_EARTHQUAKE(trial_id, InputDict) #[s]
            if Stest[1].misc["dlerror"] == 0
                break;
            else
                trial_id += 1
            end
        end
    end

    if trial_id == numofitr - 1
        error("all request returns error. Please check the station availability in your request.")
    end

    mem_per_requestid = 1.2 * sizeof(Stest) / GB #[GB] *for the safty, required memory is multiplied by 1.2

    max_num_of_processes_per_parallelcycle = floor(Int64, MAX_MEM_PER_CPU/mem_per_requestid)
    estimated_downloadtime = now() + Second(round(2 * t1 * numofitr / NP))

    #println(mem_per_requestid)
    #println(max_num_of_processes_per_parallelcycle)
    println("-------DOWNLOAD STATS SUMMARY--------")

    println(@sprintf("Number of processors is %d.", NP))

    totaldownloadsize = mem_per_requestid * numofitr
    if totaldownloadsize < MB
        totaldownloadsize = totaldownloadsize * GB / MB #[MB]
        sizeunit = "MB"
    else
        sizeunit = "GB"
    end

    println(@sprintf("Total download size will be %4.2f [%s].", 0.6 * totaldownloadsize, sizeunit)) #0.6: considering compression efficiency
    println(@sprintf("Download will finish at %s.", round(estimated_downloadtime, Dates.Second(1))))

    println("-------START DOWNLOADING-------------")

    return max_num_of_processes_per_parallelcycle

end

"""
initlogo()

print initial logo
"""
function initlogo()

    print("

      _____        _       _____                          _                    _
     / ____|      (_)     |  __ \\                        | |                  | |
    | (___    ___  _  ___ | |  | |  ___ __      __ _ __  | |  ___    __ _   __| |
     \\___ \\  / _ \\| |/ __|| |  | | / _ \\\\ \\ /\\ / /| '_ \\ | | / _ \\  / _` | / _` |
     ____) ||  __/| |\\__ \\| |__| || (_) |\\ V  V / | | | || || (_) || (_| || (_| |
    |_____/  \\___||_||___/|_____/  \\___/  \\_/\\_/  |_| |_||_| \\___/  \\__,_| \\__,_|
                      _         _  _
                     | |       | |(_)           |
    __      __       | | _   _ | | _   __ _     | v1.0 (Last update 06/06/2019)
    \\ \\ /\\ / /   _   | || | | || || | / _` |    | © Kurama Okubo
     \\ V  V /_  | |__| || |_| || || || (_| |    |
      \\_/\\_/(_)  \\____/  \\__,_||_||_| \\__,_|    |

")

    println("Job start running at "*string(now())*"\n")

end

end

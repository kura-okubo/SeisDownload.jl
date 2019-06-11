__precompile__()
module Utils

using Dates, JLD2, FileIO, SeisIO, Printf

export get_starttimelist, get_timestamplist, get_stationlist, initlogo

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

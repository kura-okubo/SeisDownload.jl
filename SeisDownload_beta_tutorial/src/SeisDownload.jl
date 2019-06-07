__precompile__()
module SeisDownload

include("utils.jl")
using .Utils, SeisIO, Dates, Printf, JLD2, FileIO,  Distributed, ProgressMeter

export ParallelSeisrequest, seisdownload_NOISE

#------------------------------------------------------------------#
#For the time being, we need remove_response function from obspy
#This will be replaced by SeisIO modules in the near future.
#Please activate obspy enviroment before launching Julia.
include("remove_response_obspy.jl")
using .Remove_response_obspy
#------------------------------------------------------------------#


"""
    ParallelSeisrequest(NP::Int, InputDict::Dict)

    Request seismic data with Multiple cores.
# Arguments
- `NP`           : number of processors
- `InputDict`    : dictionary which contains request information
"""
function ParallelSeisrequest(NP::Int, InputDict::Dict)

    Utils.initlogo()

    #stationlist
    stationlist     = InputDict["stationinfo"]["stationlist"]
    starttime       = InputDict["starttime"]
    endtime         = InputDict["endtime"]
    DL_time_unit    = InputDict["DL_time_unit"]
    DownloadType    = InputDict["DownloadType"]
    fopath          = InputDict["fopath"]

    if mod((endtime - starttime).value,  DL_time_unit) != 0 || (endtime - starttime).value < DL_time_unit
        error("Total download time cannot be devided by Download Time unit; this may cause unexpected result. abort.")
    end

    # calculate start time list (starttimelist) with each Donwload_time_unit
    starttimelist = Utils.get_starttimelist(starttime, endtime, DL_time_unit)
    # generate DLtimestamplist and ststationlist
    DLtimestamplist = Utils.get_timestamplist(starttimelist)

    #save info into jld2
    jldopen(fopath, "w") do file
        file["info/DLtimestamplist"] = DLtimestamplist;
        file["info/stationlist"] = stationlist;
        file["info/starttime"]   = string(starttime)
        file["info/endtime"]     = string(endtime)
        file["info/DL_time_unit"]= string(DL_time_unit)
    end

    #parallelization by time
    pitr = 1

    # progress bar
    prog = Progress(floor(Int, length(starttimelist)/NP), 1.0,  "Downloading Seismic Data...")

    while pitr <=  length(starttimelist)

        startid1 = pitr
        startid2 = pitr + NP-1

        if startid2 <= length(starttimelist)
            #use all processors
            if DownloadType == "Noise" || DownloadType == "noise"
                S = pmap(x -> seisdownload_NOISE(x, InputDict), startid1:startid2)

            elseif  DownloadType == "Earthquake" || DownloadType == "earthquake"
                println("Download type Earthquake Not implemented.")
            end

        else
            #use part of processors
            if DownloadType == "Noise" || DownloadType == "noise"
                startid2 = startid1 + mod(length(starttimelist), NP) - 1
                S = pmap(x -> seisdownload_NOISE(x, InputDict), startid1:startid2)

            elseif  DownloadType == "Earthquake" || DownloadType == "earthquake"
                println("Download type Earthquake Not implemented.")
            end
        end

        #save data to jld2
        file = jldopen(fopath, "r+")

        for ii = 1:size(S)[1] #loop at each starttime
            for jj = 1:size(S[1])[1] #loop at each station id

                requeststr =S[ii][jj].id
                varname = joinpath(DLtimestamplist[startid1+ii-1], requeststr)
                #save_SeisData2JLD2(fopath, varname, S[ii][jj])
                file[varname] = S[ii][jj]
            end
        end
        JLD2.close(file)

        pitr += NP
        next!(prog)
    end

    println("Downloading and Saving data is successfully done.\njob ended at "*string(now()))

end


"""
    seisdownload(startid)

Download seismic data, removing instrumental response and saving into JLD2 file.

# Arguments
- `startid`         : start time id in starttimelist
- `InputDict::Dict` : dictionary which contains request information
"""
function seisdownload_NOISE(startid, InputDict::Dict)

    #stationlist
    stationlist     = InputDict["stationinfo"]["stationlist"]
    datacenter      = InputDict["stationinfo"]["stationdatacenter"]
    src             = InputDict["stationinfo"]["stationsrc"]
    starttime       = InputDict["starttime"]
    endtime         = InputDict["endtime"]
    DL_time_unit    = InputDict["DL_time_unit"]
    pre_filt        = InputDict["pre_filt"]

    #make stliet at all processors
    starttimelist = get_starttimelist(starttime, endtime, DL_time_unit)

    # generate timestamplist and ststationlist
    timestamplist = get_timestamplist(starttimelist)

    S = SeisData(length(stationlist))
    for i = 1:length(stationlist)
        #---download data---#
        requeststr = stationlist[i]
        Stemp = get_data(datacenter[i], requeststr, s=starttimelist[startid], t=DL_time_unit, v=0, src=src[i], w=false, xf="$requeststr.$startid.xml")
        #---remove response---#
        Remove_response_obspy.remove_response_obspy!(Stemp, "$requeststr.$startid.xml", pre_filt=pre_filt, output="VEL")
        rm("$requeststr.$startid.xml")
        S[i] = Stemp[1]
    end

    return S
end


end

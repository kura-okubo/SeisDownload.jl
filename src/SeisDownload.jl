__precompile__()
module SeisDownload

include("utils.jl")
using .Utils

#------------------------------------------------------------------#
#For the time being, we need remove_response function from obspy
#This will be replaced by SeisIO modules in the near future.
#Please activate obspy enviroment before launching Julia.
include("remove_response_obspy.jl")
using .Remove_response_obspy
#------------------------------------------------------------------#

using SeisIO, Noise, Printf, Dates, FFTW, JLD2, MPI, ProgressMeter

export seisdownload

"""

    seisdownload(network::Array{String,1}, station::Array{String,1}, location::Array{String,1}, channel::Array{String,1}, datacenter::String, src::String,
                Starttime::DateTime, Endtime::DateTime, CC_time_unit::Float64, foname::String;
                pre_filt::NTuple{4,Float64}=(0.001, 0.002, 10.0, 20.0),
                downsample_fs::Float64=20,
                IsRemoveStationXML::Bool=true)

Download seismic data, preprocessing and saving into JLD2 file.

# Arguments
- `network::Array{String,1}`    : List of network e.g. network=["BP"]
- `station::Array{String,1}`    : List of station e.g. station=["LCCB", "MMNB"]
- `location::Array{String,1}`   : List of location e.g. location=[""]
- `channel::Array{String,1}`   : List of channel e.g. channel=["BP1", "BP2"]
- `datacenter::String`          : name of data center e.g. datacenter="NCEDC"
- `src::String`                 : name of source server e.g. src="NCEDC"
- `Starttime::DateTime`         : Starttime e.g. Starttime = DateTime(2004,6,1,0,0,0) (using module `Dates`)
- `Endtime::DateTime`           : Endtime e.g. Endtime = DateTime(2004,6,2,0,0,0) (using module `Dates`)
- `CC_time_unit::Float64`       : Unit time for cross-correlation data [sec] e.g. CC_time_unit = 3600
- `foname::String`              : output file name.
- `pre_filt::NTuple{4,Float64}` : option for pre-filter before removing instrumental response.
- `downsample_fs`               : downsampling frequency.
- `IsRemoveStationXML`          : Station XML file is removed after removing resp from dataset.

# Output
- `foname.jld2`                 : contains SeisData structure with a hierarchical structure (Date, CC time unit, metadata)

"""
function seisdownload(network::Array{String,1}, station::Array{String,1}, location::Array{String,1}, channel::Array{String,1}, datacenter::String, src::String,
    starttime::DateTime, endtime::DateTime, CC_time_unit::Float64, foname::String;
    pre_filt::NTuple{4,Float64}=(0.001, 0.002, 10.0, 20.0),
    downsample_fs::Float64=20,
    IsRemoveStationXML::Bool=true)

    MPI.Init()

    # establish the MPI communicator and obtain rank
    comm = MPI.COMM_WORLD
    size = MPI.Comm_size(comm)
    rank = MPI.Comm_rank(comm)

    # print initial logo and info
    if rank == 0 Utils.initlogo() end

    #-------------------------------------------------------------------#
    #NEVER CHANGE THIS THRESHOLD OTHERWISE IT OVERLOADS THE DATA SERVER
    MAXMPINUM = 32
    if size > MAXMPINUM throw(DomainError(size, "np must be smaller than $MAXMPINUM.")) end
    #-------------------------------------------------------------------#

    # calculate start time with each CC_time_unit
    stlist = get_starttimelist(starttime, endtime, CC_time_unit)

    # generate timestamplist and ststationlist
    timestamplist = get_timestamplist(stlist)
    stationlist   = get_stationlist(network, station, location, channel)

    # save download information in JLD2
    if rank == 0
        jldopen(foname, "w") do file
            file["info/timestamplist"] = timestamplist;
            file["info/stationlist"] = stationlist;
            file["info/starttime"]   = string(starttime)
            file["info/endtime"]     = string(endtime)
            file["info/CC_time_unit"]= string(CC_time_unit)
        end
    end

    mpiitrcount = 0
    baton = Array{Int32, 1}([0]) # for Relay Dumping algorithm

    # progress bar
    if rank == 0 prog = Progress(floor(Int, length(stlist)/size), 1.0,  "Downloading Seismic Data...") end

    #time
    if rank == 0 t1 = now() end

    for stid = 1:length(stlist) #to be parallelized
        processID = stid - (size * mpiitrcount)

        # if this mpiitrcount is final round or not
        length(stlist) - size >= size * mpiitrcount ? anchor_rank = size-1 : anchor_rank = mod(length(stlist), size)-1

        if rank == processID-1

            for networkid = 1:length(network)

                for stationid = 1:length(station)

                    for locationid = 1:length(location)

                        for channelid = 1:length(channel)

                            requeststr = @sprintf("%s.%s.%s.%s", network[networkid], station[stationid], location[locationid], channel[channelid])

                            #---download data---#
                            S = get_data(datacenter, requeststr, s=stlist[stid],t=CC_time_unit, v=0, src=src, w=false, xf="$requeststr.$stid.xml")

                            #---remove response---#
                            Remove_response_obspy.remove_response_obspy!(S, "$requeststr.$stid.xml", pre_filt=pre_filt, output="VEL")
                            if IsRemoveStationXML rm("$requeststr.$stid.xml") end

                            #---check for gaps---#
                            SeisIO.ungap!(S)

                            #---remove earthquakes---#
                            # NOT IMPLEMENTED YET!

                            #---detrend---#
                            SeisIO.detrend!(S)

                            #---bandpass filter---#
                            SeisIO.filtfilt!(S,fl=0.01,fh=0.9*(0.5*S.fs[1])) #0.9*Nyquist frequency

                            #---taper---#
                            SeisIO.taper!(S,t_max=30.0,α=0.05)

                            #---sync starttime---#
                            SeisIO.sync!(S,s=DateTime(stlist[stid]),t=DateTime(stlist[stid])+Dates.Second(CC_time_unit))

                            #---down sampling---#
                            # Note: filtering should be first then down sampling
                            S = Noise.downsample(S, float(downsample_fs))
                            SeisIO.note!(S, "downsample!, downsample_fs=$downsample_fs")

                            #---FFT---#
                            S.misc[1]["fft"] = fft(S[1].x)

                            # #save data to JLD2 file
                            varname = timestamplist[stid]*"/"*requeststr

                            # Relay Data Dumping algorithm to aboid writing conflict with MPI
                            if size == 1
                                save_SeisData2JLD2(foname, varname, S)

                            else
                                if rank == 0
                                    save_SeisData2JLD2(foname, varname, S)

                                    if anchor_rank != 0
                                        MPI.Send(baton, rank+1, 11, comm)
                                        MPI.Recv!(baton, anchor_rank, 12, comm)
                                    end

                                elseif rank == anchor_rank
                                    MPI.Recv!(baton, rank-1, 11, comm)
                                    save_SeisData2JLD2(foname, varname, S)
                                    MPI.Send(baton, 0, 12, comm)

                                else
                                    MPI.Recv!(baton, rank-1, 11, comm)
                                    save_SeisData2JLD2(foname, varname, S)
                                    MPI.Send(baton, rank+1, 11, comm)
                                end
                            end
                        end
                    end
                end
            end
            #println("stid:$stid done by rank $rank out of $size processors")
            mpiitrcount += 1

            #progress bar
            if rank == 0 next!(prog) end
        end
    end

    if rank == 0 println("Downloading and Saving data is successfully done.\njob ended at "*string(now())) end

    MPI.Finalize()


    # #Use this section for the download speed comarison
    # downloadidname = "1yeardownload
    # "
    # if rank == 0
    #     totaltime = (now()- t1).value / 1e3 / 60 #[min]
    #     jldopen("./Downloadtime_$downloadidname.jld2", "a") do file
    #     vartimename = @sprintf("np%02d", size)
    #     file[vartimename] = totaltime
    #     end
    # end

    return 0
end


end

__precompile__()
module SeisDownload

include("utils.jl")
include("downloadfunc.jl")

using .Utils
using .DownloadFunc

using SeisIO, Dates, Printf, JLD2, FileIO,  Distributed

#------------------------------------------------------------------#
#For the time being, we need remove_response function from obspy
#This will be replaced by SeisIO modules in the near future.
#Please activate obspy enviroment before launching Julia.
include("remove_response_obspy.jl")
using .Remove_response_obspy
#------------------------------------------------------------------#
export seisdownload


"""
    ParallelSeisrequest(NP::Int, InputDict::Dict)

    Request seismic data with Multiple cores.
# Arguments
- `NP`           : number of processors
- `InputDict`    : dictionary which contains request information
- `MAX_MEM_PER_CPU` : maximum available memory for 1 cpu [GB] (default = 1.0GB)
"""
function seisdownload(NP::Int, InputDict::Dict; MAX_MEM_PER_CPU::Float64=1.0)

    Utils.initlogo()

	DownloadType    = InputDict["DownloadType"]

    if DownloadType == "Noise" || DownloadType == "noise"

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

		InputDict["starttimelist"] = starttimelist
		InputDict["DLtimestamplist"] = DLtimestamplist

		#save info into jld2
		jldopen(fopath, "w") do file
			file["info/DLtimestamplist"] = DLtimestamplist;
			file["info/stationlist"] = stationlist;
			file["info/starttime"]   = string(starttime)
			file["info/endtime"]     = string(endtime)
			file["info/DL_time_unit"]= string(DL_time_unit)
		end

        #Test download to evaluate use of memory and estimate download time.
		max_num_of_processes_per_parallelcycle = testdownload(NP, InputDict, length(starttimelist), MAX_MEM_PER_CPU)

        if max_num_of_processes_per_parallelcycle < 1
            error("Memory allocation is not enought (currently $MAX_MEM_PER_CPU [GB]). Please inclease MAX_MEM_PER_CPU or decrease number of stations")
        end

        if max_num_of_processes_per_parallelcycle >= length(starttimelist)

            S = pmap(x -> seisdownload_NOISE(x, InputDict), 1:length(starttimelist))

            # save data to jld2
            file = jldopen(fopath, "r+")
            unavalilablefile = jldopen(join([fopath[1:end-5], "_unavailablestations.jld2"]), "w+")

            for ii = 1:size(S)[1] #loop at each starttime
                for jj = 1:size(S[1])[1] #loop at each station id

                    requeststr =S[ii][jj].id
                    varname = joinpath(DLtimestamplist[ii], requeststr)
                    #save_SeisData2JLD2(fopath, varname, S[ii][jj])
                    file[varname] = S[ii][jj]

                    if S[ii][jj].misc["dlerror"] == 1
                        unavalilablefile[varname] = S[ii][jj]
                    end
                end
            end
            JLD2.close(file)
            JLD2.close(unavalilablefile)

        else

            #parallelization by time
    	    pitr = 1

    	    # progress bar

    	    while pitr <=  length(starttimelist)

    	        startid1 = pitr
    	        startid2 = pitr + max_num_of_processes_per_parallelcycle - 1

    	        if startid2 <= length(starttimelist)
    	            #use all processors
	                S = pmap(x -> seisdownload_NOISE(x, InputDict), startid1:startid2)

    	        else
    	            #use part of processors
	                startid2 = startid1 + mod(length(starttimelist), NP) - 1
	                S = pmap(x -> seisdownload_NOISE(x, InputDict), startid1:startid2)
    	        end

                # save data to jld2
                file = jldopen(fopath, "r+")
                unavalilablefile = jldopen(join([fopath[1:end-5], "_unavailablestations.jld2"]), "w+")

                for ii = 1:size(S)[1] #loop at each starttime
                    for jj = 1:size(S[1])[1] #loop at each station id

                        requeststr =S[ii][jj].id
                        varname = joinpath(DLtimestamplist[startid1+ii-1], requeststr)
                        #save_SeisData2JLD2(fopath, varname, S[ii][jj])
                        file[varname] = S[ii][jj]

                        if S[ii][jj].misc["dlerror"] == 1
                            unavalilablefile[varname] = S[ii][jj]
                        end
                    end
                end

                JLD2.close(file)
                JLD2.close(unavalilablefile)


    	        pitr += max_num_of_processes_per_parallelcycle

                #println("pitr: $pitr")
            end
        end

    elseif  DownloadType == "Earthquake" || DownloadType == "earthquake"

		method		    = InputDict["method"]
		event		    = InputDict["event"]
		reg			    = InputDict["reg"]
		fopath          = InputDict["fopath"]

		#save info into jld2
		jldopen(fopath, "w") do file
			file["info/method"]  = method;
			file["info/event"]   = event;
			file["info/reg"]     = reg
			file["info/fopath"]  = fopath
		end

		#Test download to evaluate use of memory and estimate download time.
		max_num_of_processes_per_parallelcycle = testdownload(NP, InputDict, length(event), MAX_MEM_PER_CPU)

		if max_num_of_processes_per_parallelcycle < 1
			error("Memory allocation is not enought (currently $MAX_MEM_PER_CPU [GB]). Please inclease MAX_MEM_PER_CPU or decrease number of stations")
		end

		if max_num_of_processes_per_parallelcycle >= length(event)

			S = pmap(x -> seisdownload_EARTHQUAKE(x, InputDict), 1:length(event))

			# save data to jld2
			file = jldopen(fopath, "r+")
			unavalilablefile = jldopen(join([fopath[1:end-5], "_unavailablestations.jld2"]), "w+")

			for ii = 1:size(S)[1] #loop at each starttime
				varname = joinpath("event",InputDict["event"][ii]["origin"]["time"][1:end-4])
				file[varname] = S[ii]
			end

			JLD2.close(file)
			JLD2.close(unavalilablefile)

		else

			#parallelization by time
			pitr = 1

			while pitr <=  length(event)

				startid1 = pitr
				startid2 = pitr + max_num_of_processes_per_parallelcycle - 1

				if startid2 <= length(event)
					#use all processors
					S = pmap(x -> seisdownload_EARTHQUAKE(x, InputDict), startid1:startid2)

				else
					#use part of processors
					startid2 = startid1 + mod(length(event), NP) - 1
					S = pmap(x -> seisdownload_EARTHQUAKE(x, InputDict), startid1:startid2)
				end

				# save data to jld2
				file = jldopen(fopath, "r+")
				unavalilablefile = jldopen(join([fopath[1:end-5], "_unavailablestations.jld2"]), "w+")


				for ii = 1:size(S)[1] #loop at each starttime
					varname = joinpath("event",InputDict["event"][startid1+ii-1]["origin"]["time"][1:end-4])
					file[varname] = S[ii]
				end

				JLD2.close(file)
				JLD2.close(unavalilablefile)

				pitr += max_num_of_processes_per_parallelcycle

				#println("pitr: $pitr")
			end
		end


    else
        println("Download type is not known (chose Noise or Earthquake).")
    end

    println("Downloading and Saving data is successfully done.\njob ended at "*string(now()))
    return 0

end

end

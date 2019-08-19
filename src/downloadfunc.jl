__precompile__()
module DownloadFunc

#------------------------------------------------------------------#
#For the time being, we need remove_response function from obspy
#This will be replaced by SeisIO modules in the near future.
#Please activate obspy enviroment before launching Julia.
# include("remove_response_obspy.jl")
# using .Remove_response_obspy
#------------------------------------------------------------------#

using SeisIO, Dates

export seisdownload_NOISE, seisdownload_EARTHQUAKE

"""
    seisdownload_NOISE(startid, InputDict::Dict)

Download seismic data, removing instrumental response and saving into JLD2 file.

# Arguments
- `startid`         : start time id in starttimelist
- `InputDict::Dict` : dictionary which contains request information
"""
function seisdownload_NOISE(startid, InputDict::Dict)

    #stationlist
    stationlist     = InputDict["stationinfo"]["stationlist"]
    method      	= InputDict["stationinfo"]["stationmethod"]
    src             = InputDict["stationinfo"]["stationsrc"]
    starttime       = InputDict["starttime"]
    endtime         = InputDict["endtime"]
    DL_time_unit    = InputDict["DL_time_unit"]

	#SeisIO getdata option
	if !haskey(InputDict, "get_data_opt")
		InputDict["get_data_opt"] = [true, true, true, true, false]#: [unscale, demean, detrend, taper, ungap]
	end

	if !haskey(InputDict, "savesamplefreq")
		InputDict["savesamplefreq"] = false # default margin: 5 minutes
	end

	if !haskey(InputDict, "download_margin")
		InputDict["download_margin"] = 5 * 60 # default margin: 5 minutes
	end

    #make stlist at all processors

    starttimelist = InputDict["starttimelist"]

    #show progress
    if starttimelist[startid][end-8:end] == "T00:00:00"
        println("start downloading $(starttimelist[startid])")
    end

	dlerror = []

    for i = 1:length(stationlist)
        #---download data---#
        requeststr = stationlist[i]

		#println(starttimelist[startid])

		# including download margin
		starttime = string(DateTime(starttimelist[startid]) - Second(InputDict["download_margin"]))
		dltime = DL_time_unit + 2 * InputDict["download_margin"]

		#println(starttime)
		#println(dltime)

		if InputDict["IsLocationBox"]

	        ex = :(get_data($(method[i]), $(requeststr), s=$(starttime), t=$(dltime), reg=$(InputDict["reg"]),
			 v=$(0), src=$(src[i]), xf=$("$requeststr.$startid.xml"), unscale=$(InputDict["get_data_opt"][1]),
			  demean=$(InputDict["get_data_opt"][2]), detrend=$(InputDict["get_data_opt"][3]),taper=$(InputDict["get_data_opt"][4]),
			  ungap=$(InputDict["get_data_opt"][5]), rr=$(InputDict["IsResponseRemove"])))

	        t_dl = @elapsed Stemp = check_and_get_data(ex, requeststr)
		else

			ex = :(get_data($(method[i]), $(requeststr), s=$(starttime), t=$(dltime),
			 v=$(0), src=$(src[i]), xf=$("$requeststr.$startid.xml"),unscale=$(InputDict["get_data_opt"][1]),
			  demean=$(InputDict["get_data_opt"][2]), detrend=$(InputDict["get_data_opt"][3]),taper=$(InputDict["get_data_opt"][4]),
			  ungap=$(InputDict["get_data_opt"][5]), rr=$(InputDict["IsResponseRemove"])))

			t_dl = @elapsed Stemp = check_and_get_data(ex, requeststr)
		end

		# Check maximum memory allocation
		if sizeof(Stemp)/1024/1024/1024 > InputDict["MAX_MEM_PER_CPU"]
			@warn "maximam allocation of memory per cpu exceeds predescribed MAX_MEM_PER_CPU.
			This may cause transient memory leak, so please track the memory usage." AllocatedMemory_GB=sizeof(Stemp)/1024/1024/1024
		end

		# manipulate download_margin
		if Stemp.misc[1]["dlerror"] != 1
			for j = 1:Stemp.n
				marginidx = trunc(Int64, InputDict["download_margin"] * Stemp[j].fs)
				# check if data length is too short before removing margin
				if length(Stemp[j].x) > 2 * marginidx
					Stemp.x[j] = Stemp.x[j][marginidx+1:end-marginidx]
					Stemp.t[j][1,2] = Stemp.t[j][1,2] + float(InputDict["download_margin"])*1e6
					Stemp.t[j][end,1] = length(Stemp.x[j])
				else
					#zero pad because this does not have so much data
					Stemp.x[j] = zeros(length(Stemp[j].x))
					Stemp.t[j][1,2] = Stemp.t[j][1,2] + float(InputDict["download_margin"])*1e6
					Stemp.t[j][end,1] = length(Stemp.x[j])
				end
			end

			# downsample
			if InputDict["savesamplefreq"] isa Number
				#make resample id list
				resampleids = findall(x -> Stemp.fs[x]>InputDict["savesamplefreq"], 1:Stemp.n)
				#println(resampleids)
				if !isempty(resampleids)
					SeisIO.resample!(Stemp, chans=resampleids, fs=float(InputDict["savesamplefreq"]))
				end
			end
		end

		ymd = split(starttimelist[startid], r"[A-Z]")
		(y, m, d) = split(ymd[1], "-")
		j = md2j(y, m, d)
		fname_out = join([String(y),
					string(j),
					replace(split(starttimelist[startid], 'T')[2], ':' => '.'),requeststr,
					"FDSNWS",
					src[i],"dat"],
					'.')

		# save as intermediate binary file
		t_write = @elapsed wseis(InputDict["tmppath"]*"/"*fname_out, Stemp)

		if InputDict["IsXMLfileRemoved"] && ispath("$requeststr.$startid.xml")
			rm("$requeststr.$startid.xml")
		end

		push!(dlerror, Stemp.misc[1]["dlerror"])

		print("[dltime, wtime, fraction of writing]: ")
		println([t_dl, t_write, t_write/(t_dl+t_write)])
    end

    return dlerror
end



"""
    seisdownload_EARTHQUAKE(startid, InputDict::Dict)

Download seismic data, removing instrumental response and saving into JLD2 file.

# Arguments
- `startid`         : start time id in starttimelist
- `InputDict::Dict` : dictionary which contains request information
"""
function seisdownload_EARTHQUAKE(startid, InputDict::Dict)

	method		    = InputDict["method"]
	event		    = InputDict["event"]
	reg			    = InputDict["reg"]
    pre_filt        = InputDict["pre_filt"]

    #show progress
    if mod(startid, round(0.1*length(event))+1) == 0
        println("start downloading event number: $startid")
    end
    S = SeisData()

    #---download data---#
	for j = 1:length(event[startid]["pickphase"])
		net = event[startid]["pickphase"][j]["net"]
		sta = event[startid]["pickphase"][j]["sta"]
		loc = event[startid]["pickphase"][j]["loc"]
		cha = event[startid]["pickphase"][j]["cha"]
		src = event[startid]["pickphase"][j]["src"]

		starttime = string(event[startid]["pickphase"][j]["starttime"])
		endtime = string(event[startid]["pickphase"][j]["endtime"])

		# make multiple request str

    	requeststr = join([net,sta,loc,cha], ".")

		if InputDict["IsLocationBox"]
			# request with lat-lon box
    		#argv = [method, requeststr, starttime, endtime, InputDict["reg"], 0, src, false, "$requeststr.$startid.xml"]
		    ex = :(get_data($(method), $(requeststr), s=$(starttime), t=$(endtime), reg=$(InputDict["reg"]), v=$(0), src=$(src), xf=$("$requeststr.$startid.xml")))
		    Stemp = check_and_get_data(ex, requeststr)
		else
			# request with lat-lon box
    		#argv = [method, requeststr, starttime, endtime, 0, src, false, "$requeststr.$startid.xml"]
			ex = :(get_data($(method), $(requeststr), s=$(starttime), t=$(endtime), v=$(0), src=$(src), xf=$("$requeststr.$startid.xml")))
		    Stemp = check_and_get_data(ex, requeststr)
		end

	    if Stemp.misc[1]["dlerror"] == 0 && InputDict["IsResponseRemove"]
	        Remove_response_obspy.remove_response_obspy!(Stemp, "$requeststr.$startid.xml", pre_filt=pre_filt, zeropadlen = float(30*60), output="VEL")
			if InputDict["IsXMLfileRemoved"]
				rm("$requeststr.$startid.xml")
			else
				mkpath("./stationxml")
				mv("$requeststr.$startid.xml", "./stationxml/$requeststr.$startid.xml", force=true)
			end
		else
			if InputDict["IsXMLfileRemoved"]
				rm("$requeststr.$startid.xml")
			else
				mkpath("./stationxml")
				mv("$requeststr.$startid.xml", "./stationxml/$requeststr.$startid.xml", force=true)
			end
	    end

		#fill gap with zero
		SeisIO.ungap!(Stemp, m=true)
		replace!(Stemp.x, NaN=>0)

		append!(S, Stemp)
	end

    return S
end


"""
    check_and_get_data(ex::Expr, requeststr::String)

Download seismic data, removing instrumental response and saving into JLD2 file.

# Arguments
- `ex::Expr`        : expression of get data includin all request information

# Output
- `S::SeisData`     : downloaded SeisData
- `requeststr::String`     : request channel (e.g. "BP.LCCB..BP1")
"""
function check_and_get_data(ex::Expr, requeststr::String)
	try
		#comment out below if you want to print contents of get_data()
		#println(ex)
		S = eval(ex);
		for j = 1:S.n
			S.misc[j]["dlerror"] = 0
		end
		return S

	catch y
		println(y)
		S = SeisData(1)
		S.misc[1]["dlerror"] = 1
		S.id[1] = requeststr
		note!(S, 1, "station is not available for this request.")
		return S
	end
end

end

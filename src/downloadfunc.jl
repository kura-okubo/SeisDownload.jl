__precompile__()
module DownloadFunc

#------------------------------------------------------------------#
#For the time being, we need remove_response function from obspy
#This will be replaced by SeisIO modules in the near future.
#Please activate obspy enviroment before launching Julia.
include("remove_response_obspy.jl")
using .Remove_response_obspy
#------------------------------------------------------------------#

using SeisIO

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
    pre_filt        = InputDict["pre_filt"]

    #make stlist at all processors

    starttimelist = InputDict["starttimelist"]
    timestamplist = InputDict["DLtimestamplist"]

    #show progress
    if starttimelist[startid][end-8:end] == "T00:00:00"
        println("start downloading $(starttimelist[startid])")
    end

    S = SeisData(length(stationlist))
    for i = 1:length(stationlist)
        #---download data---#
        requeststr = stationlist[i]

		if InputDict["IsLocationBox"]
	        #argv = [method[i], requeststr, starttimelist[startid], DL_time_unit, InputDict["reg"], 0, src[i], false, "$requeststr.$startid.xml"]
	        ex = :(get_data($(method[i]), $(requeststr), s=$(starttimelist[startid]), t=$(DL_time_unit), reg=$(InputDict["reg"]), v=$(0), src=$(src[i]), xf=$("$requeststr.$startid.xml")))
	        Stemp = check_and_get_data(ex, requeststr)
		else
			#argv = [method[i], requeststr, starttimelist[startid], DL_time_unit, 0, src[i], false, "$requeststr.$startid.xml"]
			ex = :(get_data($(method[i]), $(requeststr), s=$(starttimelist[startid]), t=$(DL_time_unit), v=$(0), src=$(src[i]), xf=$("$requeststr.$startid.xml")))
			Stemp = check_and_get_data(ex, requeststr)
		end

        if Stemp.misc[1]["dlerror"] == 0 && InputDict["IsResponseRemove"]
            Remove_response_obspy.remove_response_obspy!(Stemp, "$requeststr.$startid.xml", pre_filt=pre_filt, zeropadlen = float(30*60), output="VEL")
            rm("$requeststr.$startid.xml")
        else
            rm("$requeststr.$startid.xml")
        end

        S[i] = Stemp[1]
    end

    return S
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
	        rm("$requeststr.$startid.xml")
	    else
	        #rm("$requeststr.$startid.xml")
	    end

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
	   println(ex)
       S = eval(ex);
       S.misc[1]["dlerror"] = 0
       return S

   catch y
	   #println(y)
       S = SeisData(1)
       S.misc[1]["dlerror"] = 1
       S.id[1] = requeststr
       note!(S, 1, "station is not available for this request.")
       return S
   end
end

end

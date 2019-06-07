__precompile__()
module Remove_response_obspy

using PyCall, SeisIO, Suppressor

export remove_response_obspy, remove_response_obspy!

"""
remove_response_obspy(S::SeisDatat)
remove Instrumental response with obspy.
Currently available only one channel.
This function will be replaced by julia original function
"""
function remove_response_obspy!(S::SeisData, xf::String; pre_filt::NTuple{4,Float64}=(0.001, 0.002, 10.0, 20.0), output::String="VEL")

    @suppress begin
    Stream          = pyimport_conda("obspy.core.stream", "Stream")
    Trace           = pyimport_conda("obspy.core.trace", "Trace")
    read_inventory  = pyimport_conda("obspy", "read_inventory")
    UTCDateTime     = pyimport_conda("obspy.core.utcdatetime", "UTCDateTime")

    trace=Trace.Trace()
    trace.data = S.x[1]
    trace.stats.sampling_rate = S.fs
    trace.stats.delta = 1.0./ S.fs
    trace.stats.starttime = UTCDateTime.UTCDateTime(string(u2d( S.t[1][1,2]*1e-6)))
    str1 = split(S.id[1], ".")
    trace.stats.network = str1[1]
    trace.stats.station=  str1[2]
    trace.stats.location= str1[3]
    trace.stats.channel=  str1[4]

    stream = Stream.Stream(traces=trace)
    #read stationXML
    inv = read_inventory.read_inventory(xf)
    #stresm.remove_sensitivity(inventory=inv)
    stream.remove_response(inventory=inv, output=output, pre_filt=pre_filt, plot=false)
    S.x[1] = stream.traces[1].data
    #add note
    SeisIO.note!(S, "remove_response_obspy!, pre_filt=$pre_filt")
    end
    return nothing
end

function remove_response_obspy(S::SeisData; pre_filt::NTuple{4,Float64}=(0.001, 0.002, 10.0, 20.0), output::String="VEL")
  U = deepcopy(S)
  remove_response_obspy!(U, pre_filt=pre_filt, output=output)
  return U
end

end

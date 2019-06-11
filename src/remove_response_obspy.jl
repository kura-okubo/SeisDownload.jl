__precompile__()
module Remove_response_obspy

using PyCall, SeisIO, Suppressor

export remove_response_obspy, remove_response_obspy!

"""
remove_response_obspy(S::SeisData, xf::String; pre_filt::NTuple{4,Float64}=(0.001, 0.002, 10.0, 20.0), zeropadlen::Float64 = 30*60, output::String="VEL")
remove Instrumental response with obspy.
Currently available only one channel.
This function will be replaced by julia original function

#Input
 - zeropadlen: [min] zeropad at the side of dataset to avoid edge effect

"""
function remove_response_obspy!(S::SeisData, xf::String; pre_filt::NTuple{4,Float64}=(0.001, 0.002, 10.0, 20.0), zeropadlen::Float64 = 30*60.0, output::String="VEL")

    @suppress begin
    Stream          = pyimport_conda("obspy.core.stream", "Stream")
    Trace           = pyimport_conda("obspy.core.trace", "Trace")
    read_inventory  = pyimport_conda("obspy", "read_inventory")
    UTCDateTime     = pyimport_conda("obspy.core.utcdatetime", "UTCDateTime")

    for i = 1:length(S.x)
        #add zero at the edge of data to avoid edge effect
        numofzeropad = round(Int64, zeropadlen * S.fs[i])
        z1 = zeros(numofzeropad)
        x_withzero = vcat(z1,S.x[i],z1)
        trace=Trace.Trace()
        #trace.data = S.x[i]
        trace.data = x_withzero
        trace.stats.sampling_rate = S.fs[i]
        trace.stats.delta = 1.0./ S.fs[i]
        trace.stats.starttime = UTCDateTime.UTCDateTime(string(u2d(S.t[i][1,2]*1e-6)))
        str1 = split(S.id[i], ".")
        trace.stats.network = str1[1]
        trace.stats.station=  str1[2]
        trace.stats.location= str1[3]
        trace.stats.channel=  str1[4]

        stream = Stream.Stream(traces=trace)
        #read stationXML
        inv = read_inventory.read_inventory(xf)
        #stresm.remove_sensitivity(inventory=inv)
        stream.remove_response(inventory=inv, output=output, pre_filt=pre_filt, plot=false)
        x_withzero_removed =  stream.traces[1].data
        S.x[i] = x_withzero_removed[numofzeropad+1:end-numofzeropad]
        #add note
        SeisIO.note!(S[i], "remove_response_obspy!, pre_filt=$pre_filt")
    end

    end
    return nothing
end

function remove_response_obspy(S::SeisData, xf::String; pre_filt::NTuple{4,Float64}=(0.001, 0.002, 10.0, 20.0), zeropadlen::Float64 = 30*60.0, output::String="VEL")
  U = deepcopy(S)
  remove_response_obspy!(U, pre_filt=pre_filt,  zeropadlen, output=output)
  return U
end

end

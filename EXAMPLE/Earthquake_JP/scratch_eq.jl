using SeisIO, Dates

starttime   = DateTime(2010,9,25,0,0,0)
endtime     = DateTime(2010,9,25,0,30,0)
reg = [-46.1691, -40.0662, 166.6531, 176.3965] #Specify region [lat_min, lat_max, lon_min, lon_max, dep_min, dep_max], with lat, lon in decimal degrees (°) and depth in km with + = down.

#argv = [datacenter[i], requeststr, starttimelist[startid], DL_time_unit, 0S, src[i], false, "$requeststr.$startid.xml"]

#S = get_data("FDSN", s=string(starttime), t=(30*60), reg=reg, v=2)

#argv = [datacenter[i], requeststr, starttimelist[startid], DL_time_unit, 0, src[i], false, "$requeststr.$startid.xml"]
#ex = :(get_data($(argv[1]), $(argv[2]), s=$(argv[3]), t=$(argv[4]), v=$(argv[5]), src=$(argv[6]), w=$(argv[7]), xf=$(argv[8])))
#eval(ex)

S = get_data("FDSN", "NZ.*.*.HH*", s=string(starttime), t=string(endtime), reg=reg, v=2)

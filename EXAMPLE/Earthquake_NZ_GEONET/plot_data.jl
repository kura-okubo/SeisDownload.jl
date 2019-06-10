using SeisIO, Printf, PlotlyJS, JLD2, FileIO, Statistics, ORCA

#----------------#
finame = "./dataset/JPquake.jld2"

eventID = 1 # choose station and components from stationlist in SeisData
channel = "BHZ" # choose station and components from stationlist in SeisData
#----------------#

# load data
c = jldopen(finame)
event=c["info/event"]

origin = event[eventID]["origin"]
lat1 = parse(Float64, origin["latitude"])
lon1 = parse(Float64, origin["longitude"])
time = origin["time"][1:end-4]
mag = parse(Float64,origin["magnitude"])

# search channel
S = c["event/$time"]
Sall = SeisData()
for i = 1:size(S)[1]
	Stemp = S[i]
	if occursin(channel, Stemp.id)
		push!(Sall, Stemp)
	else
		continue;
	end
end

# compute angular distance

# chose plotting data
numoftrace = size(Sall)[1]

# for sorting plot order
plotorder = zeros(numoftrace, 2)
for i = 1:numoftrace
	lat2 = Sall[i].loc.lat
	lon2 = Sall[i].loc.lon

	Δ = acosd(sind(lat1)*sind(lat2) + cosd(lat1)*cosd(lat2)*cosd(lon1 - lon2))
 	Sall[i].misc["angulardist"] = Δ
	plotorder[i,:] = [float(i), Δ]
end

#plotting

tvec = collect(0:Sall[1].t[end,1]) ./ Sall[1].fs

trace1 = Array{GenericTrace{Dict{Symbol,Any}}, 1}(undef, numoftrace)
traceid = 0

dist_α = 1.0


plotidlist = round.(Int64, sortslices(plotorder, dims=1, lt=(x,y) -> isless(x[2], y[2]), rev=true)[:,1])
for i = plotidlist
	normalized_amp = maximum(Sall[plotidlist[end]].x)
	global traceid += 1
	trace1[traceid] = scatter(;x=tvec, y=Sall[i].x ./ normalized_amp .+ dist_α*Sall[i].misc["angulardist"], mode="lines",
     name=@sprintf("%s", Sall[i].id))
end

layout = Layout(width=800, height=600,
				xaxis=attr(title="Time [sec]"),
				yaxis=attr(title="Angular distance [°]"),
                font =attr(size=18),
                showlegend=true,
                title = @sprintf("M:%4.1f Time:%s Lat:%4.2f Lon:%4.2f", mag ,time, lat1, lon1)
				)

p = plot(trace1, layout)


figname = @sprintf("./%s_M%4.2f.png", time, mag)

savefig(p, figname)

println("to finish plotting: press any key...")
#readline()

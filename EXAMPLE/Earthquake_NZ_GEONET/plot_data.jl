using SeisIO, Printf, PlotlyJS, JLD2, FileIO, Statistics, ORCA

#----------------#
finame = "./dataset/NZ_GEONETquake.jld2"

#eventID = 2 # choose station and components from stationlist in SeisData
channel = "BHZ" # choose station and components from stationlist in SeisData
#----------------#

# load data
c = jldopen(finame)
event=c["info/event"]

for eventID = 1:length(event)

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

		#apply filters
		detrend!(Stemp)
		filtfilt!(Stemp, fl=0.1, fh=2.0)
 		taper!(Stemp)
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
		traceid += 1
		trace1[traceid] = scatter(;x=tvec, y=Sall[i].x ./ normalized_amp .+ dist_α*Sall[i].misc["angulardist"], mode="lines",
	     name=@sprintf("%s", Sall[i].id))
	end

	layout = Layout(width=800, height=600,
					xaxis=attr(title="Time [sec]"),
					yaxis=attr(title="Angular distance [°]"),
	                font =attr(size=18),
	                showlegend=true,
					xaxis_range=[0, 180],
					yaxis_range=[-0.5, 8],
	                title = @sprintf("M:%4.1f Time:%s Lat:%4.2f Lon:%4.2f", mag ,time, lat1, lon1)
					)

	p = plot(trace1, layout)
	display(p)

	mkpath("./fig")
	figname = @sprintf("./fig/%s_M%4.2f.png", time, mag)

	savefig(p, figname)

	println("Press enter to display next event:")
	readline()

end

println("to finish plotting: press any key...")
readline()

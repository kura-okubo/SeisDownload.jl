"""
Download seismic data from server
May 23, 2019
Kurama Okubo
"""

using SeisIO, Printf, PlotlyJS, JLD2, FileIO, Statistics, ORCA

#----------------#
finame = "./dataset/BPnetwork.jld2"

plottimeunit = "min" #hour, min, sec

sr = 10 #downsampling for plotting

eq_normalize_amp = 2e-3 # amplitude normalization for earthquake
aftershock_α = 0.02 # amplitude normalization for aftershock (aftershock_α  * eq_normalize_amp)
starttimeid = 1 # start time id from timestamplist in SeisData
endtimeid = 25 # start time id from timestamplist in SeisData
stationID = 1 # choose station and components from stationlist in SeisData

figname = "seismograms.png"
#----------------#

# load data
c = jldopen(finame)

#plotting

layout = Layout(width=1200, height=800,
				xaxis=attr(title="Time [$plottimeunit]"),
				yaxis=attr(title="Hours"),
                font =attr(size=18),
                showlegend=true,
                title = @sprintf("Starttime:%s Endtime:%s", c["info/timestamplist"][starttimeid], c["info/timestamplist"][endtimeid])
				)

p = plot([NaN], layout)

println("start plotting: press return key...")

# if you want to plot by running this script (>julia plot_data.jl)
# uncomment display and readline() to avoid bugs
# display(p)
# readline()

aftershockflag = 0

for stid = starttimeid:endtimeid

    key = c["info/timestamplist"][stid]*"/"*c["info/stationlist"][stationID]
	S = c[key]

    dt = 1.0./S.fs
    t = LinRange(0.0:dt:(S.t[2]-1)*dt)

	pt = t[1:sr:end]

	if plottimeunit == "min"
		pt = pt ./ 60
	elseif plottimeunit == "hour"
		pt = pt ./ 60 ./ 60
	end

    #arbitrary amplitude normalization for plotting
	if maximum(abs.(S.x)) > 10*std(S.x) && aftershockflag == 0
		# large earthquake occured -> 1 % of amp
		normalized_amp= eq_normalize_amp
		global aftershockflag = 1
	elseif maximum(abs.(S.x)) > 10*std(S.x) && aftershockflag == 1
		# aftershock
		normalized_amp= aftershock_α*eq_normalize_amp
	else
		# Noise level
		normalized_amp= 2.0 * maximum(abs.(S.x))
	end

	# if maximum(abs.(S.x)) > 2.0*normalized_amp
	# 	normalized_amp=0.2*maximum(abs.(S.x))
	# end

    trace1 = scatter(;x=pt, y= S.x[1:sr:end]./normalized_amp .+ (stid-1.0), mode="lines",
	line=attr(dash = false), name=@sprintf("%s: %s", c["info/timestamplist"][stid], c["info/stationlist"][stationID]))

    addtraces!(p, trace1)
end

deletetraces!(p, 1)

savefig(p, figname)

println("to finish plotting: press any key...")
#readline()

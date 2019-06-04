using SeisIO, FFTW, Dates

#test fft

starttime   = DateTime(2004,6,1,0,0,0)
endtime   = DateTime(2004,6,1,2,0,0)

S = get_data("NCEDC", "BP.LCCB..BP1", s=string(starttime),t=string(endtime), v=0, src="NCEDC", w=false, xf="test.xml")

fft(S[1].x)
S.misc[1]["fft"] = fft(S[1].x)

# NewZealand

starttime   = DateTime(2016,11,13,12,0,0)
endtime     = DateTime(2016,11,13,13,0,0)

S = get_data("FDSN", "NZ.BFZ.20.BNE", s=string(starttime),t=string(endtime), v=0, src="IRIS", w=false, xf="test.xml")

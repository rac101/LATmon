#!/afs/slac/g/glast/ground/glastsoft/AUTO_GLAST/arch/os/GLAST_EXT/python/2.7.2-gl4/bin/python
# Author: David Sanchez dsanchez@llr.in2p3.fr
#developed for Fermi
#CAL monitoring script : FLE,FHE,LAC and PED

print "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#"
print "Beginning of the CAL monitoring script"
print "#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#"

print '\n\tFLE and FHE part.....'
#import of packages
import ROOT
import numpy
import sys,os
from array import *
import string,time

# definition of met ref 
met_ref = 240106987.-23*60.-6
mdj_ref= 54689.

from optparse import OptionParser

parser = OptionParser(usage = 'usage: %prog [options] MET_start MET_end ')
(opts, args) = parser.parse_args()

MetStart = float(args[0])
MetStop = float(args[1])


#ROOT.gROOT.ProcessLine(".x .rootlogon.C")
# no canvas will show up
ROOT.gROOT.SetBatch(ROOT.kTRUE) 


ROOT.gROOT.SetStyle("Plain");
ROOT.gStyle.SetPalette(1);


# Canvas
ROOT.gStyle.SetCanvasColor(10);

# Frame
ROOT.gStyle.SetFrameBorderMode(0);
ROOT.gStyle.SetFrameFillColor(0);

# Pad
ROOT.gStyle.SetPadBorderMode(0);
ROOT.gStyle.SetPadColor(0);
ROOT.gStyle.SetPadTopMargin(0.07);
ROOT.gStyle.SetPadLeftMargin(0.13);
ROOT.gStyle.SetPadRightMargin(0.11);
ROOT.gStyle.SetPadBottomMargin(0.1);
ROOT.gStyle.SetPadTickX(1);#make ticks be on all 4 sides.
ROOT.gStyle.SetPadTickY(1);

# histogram
ROOT.gStyle.SetHistFillStyle(0);
ROOT.gStyle.SetOptTitle(0);

# histogram title
ROOT.gStyle.SetTitleSize(0.22);
ROOT.gStyle.SetTitleFontSize(2);
ROOT.gStyle.SetTitleFont(42);
ROOT.gStyle.SetTitleFont(62,"xyz");
ROOT.gStyle.SetTitleYOffset(1.0);
ROOT.gStyle.SetTitleXOffset(1.0);
ROOT.gStyle.SetTitleXSize(0.04);
ROOT.gStyle.SetTitleYSize(0.04);
ROOT.gStyle.SetTitleX(.15);
ROOT.gStyle.SetTitleY(.98);
ROOT.gStyle.SetTitleW(.70);
ROOT.gStyle.SetTitleH(.05);

# statistics box
ROOT.gStyle.SetStatFont(42);
ROOT.gStyle.SetStatX(.91);
ROOT.gStyle.SetStatY(.90);
ROOT.gStyle.SetStatW(.15);
ROOT.gStyle.SetStatH(.15);

# axis labels
ROOT.gStyle.SetLabelFont(42,"xyz");
ROOT.gStyle.SetLabelSize(0.035,"xyz");
ROOT.gStyle.SetGridColor(16);

ROOT.gStyle.SetLegendBorderSize(0);

#open  and read the archival file for FLE threshold
f=open("flemon.dat","r")
lines = f.readlines()
ilen=len(lines)
f.close()
timefle=array('f',ilen*[0])
arcfle=array('f',ilen*[0])
arcfleerr=array('f',ilen*[0])
i=0
for line in lines: # READ
	words = string.split(line)
        if len( words ) != 3:
                continue
	timefle[i]=float(words[0])
        arcfle[i]=float(words[1])
        arcfleerr[i]=float(words[2])
	i+=1

#open  and read the archival file for FHE threshold
f=open("fhemon.dat","r")
lines = f.readlines()
ilen=len(lines)
f.close()
timefhe=array('f',ilen*[0])
arcfhe=array('f',ilen*[0])
arcfheerr=array('f',ilen*[0])
i=0

for line in lines: # READ
        words = string.split(line)
        timefhe[i]=float(words[0])
        arcfhe[i]=float(words[1])
        arcfheerr[i]=float(words[2])
        i+=1


# MetStart=timefle[-1]
# MetStop=timefle[-1]+86400*10000

# clean the current directory
os.system("rm *.root")
# download the data with xrootd
os.system("/afs/slac.stanford.edu/u/gl/glast/datacatalog/prod/datacat find --group RECONHIST --site SLAC_XROOT /Data/Flight/Level1/LPA --sort 'nRun'  --filter '(nRun>"+str(MetStart)+"&&nRun<"+str(MetStop)+")'>listrun")

f=open('listrun','r')
lines=f.readlines()
ilen=len(lines)
f.close()
for line in lines: # DOWNLOAD
	words = string.split(line)
	os.system('xrdcp '+words[0]+' .')

os.system("ls *root>listrun")
list=open('listrun','r')
lines = list.readlines()
ilen=len(lines)
list.close()

fle=array('f',ilen*[0])
errfle=array('f',ilen*[0])
fhe=array('f',ilen*[0])
errfhe=array('f',ilen*[0])
ind=array('f',ilen*[0])
zero=array('f',ilen*[0])
flemax=array('f',ilen*[0])
fhemax=array('f',ilen*[0])


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~     FLE fit      ~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

j=0
for line in lines:

	words = string.split(line)
	ind[j]=int(words[0][1:11])
	# function used for the fit
	f1 = ROOT.TF1("f1","([2]/pow(x,[3]))/(1+exp(([0]-x)/[4]))+[1]",30,240)
	f1.SetParLimits(0,30,150);
	f1.SetParameter(2,230);
	f1.SetParameter(1,200);
	f1.SetParLimits(4,1,3);
	f1.SetParameter(4,2);

	f = ROOT.TFile(words[0], "READ");
	tup1 = f.Get("SuspCalLo_Highest0_EnergyDistribution_TH1;1");
	tup1.Draw()
	tup1.Fit('f1','QR')
	f1.Draw('same')
	
	# The results
	errfle[j] = f1.GetParError(0)
	fle[j] = f1.GetParameter(0)

	maxi=0
	kk=0
	while (300> tup1.GetBinWidth(kk)*kk):
		if (tup1.GetBinContent(kk)>maxi):
			flemax[j] = tup1.GetBinWidth(kk)*kk
			maxi=tup1.GetBinContent(kk)
		kk += 1

	j+=1

	# clean memory
	del(f1)
	del(tup1)


for i in xrange(len(ind)):
	timefle.append(ind[i])
        arcfle.append(fle[i])
        arcfleerr.append(errfle[i])

# Save data in the same file
f=open("flemon.dat","w")
for i in xrange(len(timefle)):
	f.write(str(timefle[i])+"\t"+str(arcfle[i])+"\t"+str(arcfleerr[i])+"\n")
f.close()

for i in xrange(len(timefle)):
	timefle[i]=mdj_ref+(timefle[i]-met_ref)/3600./24

zero=array('f',len(timefle)*[0])

# plot the last 30 days

cfle=ROOT.TCanvas("cfle")
ghfle = ROOT.TH2F("ghfle","",10000,timefle[-1]-30,timefle[-1],100,94,103);
ghfle.SetStats(000)
ghfle.SetXTitle("MJD")
ghfle.SetYTitle("Fitted parameter")
ghfle.Draw()

tgfle = ROOT.TGraphErrors(len(timefle),timefle,arcfle,zero,arcfleerr)
tgfle.SetMarkerStyle(2)
tgfle.SetMarkerColor(2)
tgfle.Draw('P')

cfle.Print('flemon.eps')
cfle.Print('flemon.png')
cfle.Print('flemon.C')


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~     FHE fit      ~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
j=0
for line in lines:
	words = string.split(line)
	ind[j]=int(words[0][1:11])
	# function used for the fit
	f1 = ROOT.TF1("f1","([2]/pow(x,[3]))/(1+exp(([0]-x)/[4]))+[1]",300,2500)
	f1.SetParLimits(0,300,1500);
	f1.SetParameter(0,700);
	f1.SetParameter(2,2300);
	f1.SetParameter(1,100);
	f1.SetParLimits(4,1,100);
	f1.SetParameter(3,.8);
	f1.SetParLimits(3,0,15);
	f1.SetParameter(4,10);

	f = ROOT.TFile(words[0], "READ");
	tup1 = f.Get("SuspCalHi_Highest0_EnergyDistribution_TH1;1");
	tup1.Draw()
	tup1.Fit('f1','QR')
	f1.Draw('same')
	errfhe[j] = f1.GetParError(0)
	fhe[j] = f1.GetParameter(0)


	maxi=0
	kk=0
	while (3000> tup1.GetBinWidth(kk)*kk):
		if (tup1.GetBinContent(kk)>maxi):
			fhemax[j] = tup1.GetBinWidth(kk)*kk
			maxi=tup1.GetBinContent(kk)
		kk += 1

	# clean memory
	del(f1)
	del(tup1)

	#kill bad fit
	if(fhe[j]*0.5<errfhe[j]):
		fhe[j] = 0.
		errfhe[j] = 0.
	j+=1


# update table
for i in xrange(len(ind)):
        timefhe.append(ind[i])
        arcfhe.append(fhe[i])
        arcfheerr.append(errfhe[i])

# update file
f=open("fhemon.dat","w")
for i in xrange(len(timefhe)):
        f.write(str(timefhe[i])+"\t"+str(arcfhe[i])+"\t"+str(arcfheerr[i])+"\n")
f.close()

# change time in mdj
for i in xrange(len(timefhe)):
	timefhe[i]=mdj_ref+(timefhe[i]-met_ref)/3600./24

# plot the last 30 days

cfhe=ROOT.TCanvas("cfhe")
zero2=array('f',len(timefhe)*[0])

ghfhe = ROOT.TH2F("ghfhe","",10000,timefhe[-1]-30,timefhe[-1],100,930,1070);
ghfhe.SetStats(000)
ghfhe.SetXTitle("MJD")
ghfhe.SetYTitle("Fitted parameter")
ghfhe.Draw()

tgfhe = ROOT.TGraphErrors(len(timefhe),timefhe,arcfhe,zero2,arcfheerr)
tgfhe.SetMarkerStyle(2)
tgfhe.SetMarkerColor(2)
tgfhe.Draw('P')

cfhe.Print('fhemon.eps')
cfhe.Print('fhemon.png')
cfhe.Print('fhemon.C')


print '\n\tLAC POS and LAC NEG part.....'
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~     LAC NEG fit      ~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# clean the directory
os.system("rm *.root")

#read archival data
f=open("lacmonneg.dat","r")
lines = f.readlines()
ilen=len(lines)
f.close()

timelac=array('f',ilen*[0])
arclac=array('f',ilen*[0])
arclacerr=array('f',ilen*[0])
arclacp=array('f',ilen*[0])
arclacm=array('f',ilen*[0])
zero=array('f',ilen*[0])

i=0
for line in lines:
        words = string.split(line)
        timelac[i]=float(words[0])
        arclac[i]=float(words[1])
        arclacerr[i]=float(words[2])
        arclacp[i]=float(words[3])
        arclacm[i]=float(words[4])
        i+=1

# MetStart=timelac[-1]
# MetStop=timelac[-1]+86400*10000

# download the data with Xrootd
os.system("/afs/slac.stanford.edu/u/gl/glast/datacatalog/prod/datacat find --group RECONHISTALARMDIST --site SLAC_XROOT /Data/Flight/Level1/LPA --sort 'nRun'  --filter '(nRun>"+str(MetStart)+"&&nRun<"+str(MetStop)+")'> listrun")

f=open('listrun','r')
lines=f.readlines()
ilen=len(lines)
f.close()
for line in lines:
	words = string.split(line)
	os.system('xrdcp '+words[0]+' .')

#update list of run
os.system("ls *root>listrun")

list=open('listrun','r')
lines = list.readlines()
ilen=len(lines)
list.close()

mean=array('f',ilen*[0])
rms=array('f',ilen*[0])
FirstBin=array('f',ilen*[0])
LastBin=array('f',ilen*[0])
ind=array('f',ilen*[0])
mjd=array('f',ilen*[0])



j=0
for line in lines:
	words = string.split(line)
	ind[j]=int(words[0][-38:-29])
	mjd[j]=mdj_ref+(int(words[0][-38:-29])-met_ref)/3600./24
	# retrieve the needed value
	f = ROOT.TFile(words[0], "READ");
	tup1 = f.Get("Lac_Thresholds_FaceNeg_TH1_TowerCalLayerCalColumn_leftmost_edge_TH1;1");
	mean[j]=tup1.GetMean()
	rms[j]=tup1.GetRMS()

	kk=0
	while (kk < tup1.GetEntries() ):
		if (tup1.GetBinContent(kk)>0.):
			FirstBin[j] = tup1.GetBinWidth(kk)*kk
			break
		kk += 1

	kk=int(tup1.GetEntries()-1)

	while (kk >0):
		if (tup1.GetBinContent(kk)>0.):
			LastBin[j] = tup1.GetBinWidth(kk)*kk
			break
		kk -= 1
	j+=1


# update table
for i in xrange(len(ind)):
        timelac.append(ind[i])
        arclac.append(mean[i])
        arclacerr.append(rms[i])
	arclacp.append(LastBin[i])
	arclacm.append(FirstBin[i])


#save the new and old results
f=open("lacmonneg.dat","w")
for i in xrange(len(timelac)):
        f.write(str(timelac[i])+"\t"+str(arclac[i])+"\t"+str(arclacerr[i])+"\t"+str(arclacp[i])+"\t"+str(arclacm[i])+"\n")
f.close()

# change MET in MJD
for i in xrange(len(timelac)):
	timelac[i] = mdj_ref+(timelac[i]-met_ref)/3600./24

# plot the last 30 days
clacneg=ROOT.TCanvas("clacneg")
ghlacneg = ROOT.TH2F("ghlacneg","",10000,timelac[-1]-30,timelac[-1],100,1.2,2.8);
ghlacneg.SetStats(000)
ghlacneg.SetXTitle("MJD")
ghlacneg.SetYTitle("NEG  LAC (MeV)")
ghlacneg.Draw()

# mean values and errors
tglacneg = ROOT.TGraphErrors(len(timelac),timelac,arclac,zero,arclacerr)
tglacneg.SetMarkerStyle(20)
tglacneg.SetMarkerColor(2)
tglacneg.Draw('P')

#outliers
tglacfneg = ROOT.TGraph(len(timelac),timelac,arclacp)
tglacfneg.SetMarkerStyle(20)
tglacfneg.SetMarkerColor(4)
tglacfneg.Draw('P')

#outliers
tglacpneg = ROOT.TGraph(len(timelac),timelac,arclacm)
tglacpneg.SetMarkerStyle(20)
tglacpneg.SetMarkerColor(3)
tglacpneg.Draw('P')

clacneg.Print("LAC_neg.C")
clacneg.Print("LAC_neg.eps")
clacneg.Print("LAC_neg.png")





#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~     LAC POS fit      ~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# clean the directory
os.system("rm *.root")

# read archival data
f=open("lacmonpos.dat","r")
lines = f.readlines()
ilen=len(lines)
f.close()

timelac=array('f',ilen*[0])
arclac=array('f',ilen*[0])
arclacerr=array('f',ilen*[0])
arclacp=array('f',ilen*[0])
arclacm=array('f',ilen*[0])
zero=array('f',ilen*[0])

i=0
for line in lines:
        words = string.split(line)
        timelac[i]=float(words[0])
        arclac[i]=float(words[1])
        arclacerr[i]=float(words[2])
        arclacp[i]=float(words[3])
        arclacm[i]=float(words[4])

        i+=1

# MetStart=timelac[-1]
# MetStop=timelac[-1]+86400*10000

# retrieve list of runs
os.system("/afs/slac.stanford.edu/u/gl/glast/datacatalog/prod/datacat find --group RECONHISTALARMDIST --site SLAC_XROOT /Data/Flight/Level1/LPA --sort 'nRun'  --filter '(nRun>"+str(MetStart)+"&&nRun<"+str(MetStop)+")'>listrun")


# downolad data with Xrootd
f=open('listrun','r')
lines=f.readlines()
ilen=len(lines)
f.close()

for line in lines:
	words = string.split(line)
	os.system('xrdcp '+words[0]+' .')

#update list of run
os.system("ls *root>listrun")

list=open('listrun','r')
lines = list.readlines()
ilen=len(lines)
list.close()

mean=array('f',ilen*[0])
rms=array('f',ilen*[0])
FirstBin=array('f',ilen*[0])
LastBin=array('f',ilen*[0])
ind=array('f',ilen*[0])
mjd=array('f',ilen*[0])

j=0
for line in lines:
	words = string.split(line)
	ind[j]=int(words[0][-38:-29])
	mjd[j]=mdj_ref+(int(words[0][-38:-29])-met_ref)/3600./24

	#read needed values
	f = ROOT.TFile(words[0], "READ"); 
	tup1 = f.Get("Lac_Thresholds_FacePos_TH1_TowerCalLayerCalColumn_leftmost_edge_TH1;1");
	mean[j]=tup1.GetMean()
	rms[j]=tup1.GetRMS()

	kk=0
	while (kk < tup1.GetEntries() ):
		if (tup1.GetBinContent(kk)>0.):
			FirstBin[j] = tup1.GetBinWidth(kk)*kk
			break
		kk += 1


	kk=int(tup1.GetEntries()-1)

	while (kk >0):
		if (tup1.GetBinContent(kk)>0.):
			LastBin[j] = tup1.GetBinWidth(kk)*kk
			break
		kk -= 1
	j+=1

# update table
for i in xrange(len(ind)):
        timelac.append(ind[i])
        arclac.append(mean[i])
        arclacerr.append(rms[i])
	arclacp.append(LastBin[i])
	arclacm.append(FirstBin[i])


#save the new and old results
f=open("lacmonpos.dat","w")
for i in xrange(len(timelac)):
        f.write(str(timelac[i])+"\t"+str(arclac[i])+"\t"+str(arclacerr[i])+"\t"+str(arclacp[i])+"\t"+str(arclacm[i])+"\n")
f.close()

# change MET in MJD
for i in xrange(len(timelac)):
	timelac[i] = mdj_ref+(timelac[i]-met_ref)/3600./24



#plot the last 30 days
clacpos=ROOT.TCanvas("clacpos")
ghlacpos = ROOT.TH2F("ghlacpos","",10000,timelac[-1]-30,timelac[-1],100,1.2,2.8);
ghlacpos.SetStats(000)
ghlacpos.SetXTitle("MJD")
ghlacpos.SetYTitle("POS LAC (MeV)")
ghlacpos.Draw()

# mean value
tglacpos = ROOT.TGraphErrors(len(timelac),timelac,arclac,zero,arclacerr)
tglacpos.SetMarkerStyle(20)
tglacpos.SetMarkerColor(2)
tglacpos.Draw('P')

#outliers
tglacfpos = ROOT.TGraph(len(timelac),timelac,arclacp)
tglacfpos.SetMarkerStyle(20)
tglacfpos.SetMarkerColor(4)
tglacfpos.Draw('P')

#outliers
tglacppos = ROOT.TGraph(len(timelac),timelac,arclacm)
tglacppos.SetMarkerStyle(20)
tglacppos.SetMarkerColor(3)
tglacppos.Draw('P')

# save plot
clacpos.Print("LAC_pos.C")
clacpos.Print("LAC_pos.eps")
clacpos.Print("LAC_pos.png")


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~    PED   part        ~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

# clean the directory
os.system("rm *.root")

# offset=978365835.5
# MetStart=time.time()-84600*30-offset
MetStart = MetStop-84600*30


# retrieve list of runsHEX1_ped.png
os.system("/afs/slac.stanford.edu/u/gl/glast/datacatalog/prod/datacat find --group CALPEDSANALYZER  --site SLAC_XROOT /Data/Flight/Level1/LPA --sort 'nRun' --filter '(nRun>"+str(MetStart)+" && nRun<"+str(MetStop)+")' >listrun")

#download the data with Xrootd
f=open('listrun','r')
lines=f.readlines()
lilen=len(lines)
f.close()
j=0
ind=array('f',lilen*[0])
for line in lines:
	words = string.split(line)
	os.system('xrdcp '+words[0]+' .')
	ind[j]=mdj_ref+(int(words[0][-36:-26])-met_ref)/3600./24
	j+=1

#update list
os.system("ls *root>listrun")


list=open('listrun','r')
lines = list.readlines()
ilen=len(lines)
list.close()

meanLEX1=array('f',lilen*[0])
rmsLEX1=array('f',lilen*[0])
meanLEX8=array('f',lilen*[0])
rmsLEX8=array('f',lilen*[0])
zero=array('f',lilen*[0])
meanHEX1=array('f',lilen*[0])
rmsHEX1=array('f',lilen*[0])
meanHEX8=array('f',lilen*[0])
rmsHEX8=array('f',lilen*[0])

j=0
for line in lines:
	words = string.split(line)

	ilen = 3072
	val=array('f',ilen*[0])
	f = ROOT.TFile(words[0],"READ");

	tup1 =  f.Get("CalXAdcPedPedMeanDeviation_LEX1_TH1;1");

	for i in xrange(ilen):
		val[i] = tup1.GetBinContent(i)


	yy,xx = numpy.histogram(val,bins= 50)
	y = array('f',yy)
	x = array('f',xx)
	tg = ROOT.TGraph(len(x),x,y)
	flex1 = ROOT.TF1("flex1","gaus",min(x),max(x));

	tg.Fit("flex1",'LQR')
	meanLEX1[j] = flex1.GetParameter(1)
	rmsLEX1[j] = flex1.GetParameter(2)

	tup1 = f.Get("CalXAdcPedPedMeanDeviation_LEX8_TH1;1");

	for i in xrange(ilen):
		val[i] = tup1.GetBinContent(i)

        yy,xx = numpy.histogram(val,bins= 50)
        y = array('f',yy)
        x = array('f',xx)
        tg = ROOT.TGraph(len(x),x,y)
        flex8 = ROOT.TF1("flex8","gaus",min(x),max(x));

        tg.Fit("flex8",'LQR')
        meanLEX8[j] = flex8.GetParameter(1)
        rmsLEX8[j] = flex8.GetParameter(2)


	tup1  = f.Get("CalXAdcPedPedMeanDeviation_HEX1_TH1;1");
	for i in xrange(ilen):
		val[i] = tup1.GetBinContent(i)

        yy,xx = numpy.histogram(val,bins= 50)
        y = array('f',yy)
        x = array('f',xx)
        tg = ROOT.TGraph(len(x),x,y)
        fhex1 = ROOT.TF1("fhex1","gaus",min(x),max(x));

        tg.Fit("fhex1",'LQR')
        meanHEX1[j] = fhex1.GetParameter(1)
        rmsHEX1[j] = fhex1.GetParameter(2)

	tup1 = f.Get("CalXAdcPedPedMeanDeviation_HEX8_TH1;1");
	for i in xrange(ilen):
		val[i] = tup1.GetBinContent(i)
        yy,xx = numpy.histogram(val,bins= 50)
        y = array('f',yy)
        x = array('f',xx)
        tg = ROOT.TGraph(len(x),x,y)
        fhex8 = ROOT.TF1("fhex8","gaus",min(x),max(x));

        tg.Fit("fhex8",'LQR')
        meanHEX8[j] = fhex8.GetParameter(1)
        rmsHEX8[j] = fhex8.GetParameter(2)

	j+=1

#~~~~~~~~~ LEX1

cLEX1=ROOT.TCanvas("cLEX1")
cLEX1.SetTicky(1)
cLEX1.SetTickx(1)
ghLEX1 = ROOT.TH2F("ghLEX1","",10000,ind[-1]-30,ind[-1],100,-1,1);
ghLEX1.SetStats(000)
ghLEX1.SetXTitle("MJD")

ghLEX1.SetYTitle("Ped deviation LEX1 (ADC)")
ghLEX1.Draw()

tgLEX1 = ROOT.TGraph(lilen,ind,meanLEX1)
tgLEX1.SetMarkerStyle(20)
tgLEX1.SetMarkerColor(2)
tgLEX1.Draw('P')

cLEX1.Print("LEX1_ped.eps")
cLEX1.Print("LEX1_ped.png")
cLEX1.Print("LEX1_ped.C")

cLEX1_err=ROOT.TCanvas("cLEX1_err")
cLEX1_err.SetTicky(1)
cLEX1_err.SetTickx(1)
ghLEX1_err = ROOT.TH2F("ghLEX1_err","",10000,ind[-1]-30,ind[-1],100,0,1);
ghLEX1_err.SetStats(000)
ghLEX1_err.SetXTitle("MJD")

ghLEX1_err.SetYTitle("Spread of Ped deviation LEX1 (ADC)")
ghLEX1_err.Draw()

tgLEX1_err = ROOT.TGraph(lilen,ind,rmsLEX1)
tgLEX1_err.SetMarkerStyle(2)
tgLEX1_err.Draw('P')

cLEX1_err.Print("LEX1_errped.eps")
cLEX1_err.Print("LEX1_errped.png")
cLEX1_err.Print("LEX1_errped.C")

#~~~~~~~~~ LEX8

cLEX8=ROOT.TCanvas("cLEX8")
cLEX8.SetTicky(1)
cLEX8.SetTickx(1)
ghLEX8 = ROOT.TH2F("ghLEX8","",10000,ind[-1]-30,ind[-1],100,-1,1);
ghLEX8.SetStats(000)
ghLEX8.SetXTitle("MJD")

ghLEX8.SetYTitle("Ped deviation LEX8 (ADC)")
ghLEX8.Draw()

tgLEX8 = ROOT.TGraph(lilen,ind,meanLEX8)
tgLEX8.SetMarkerStyle(20)
tgLEX8.SetMarkerColor(2)
tgLEX8.Draw('P')

cLEX8.Print("LEX8_ped.eps")
cLEX8.Print("LEX8_ped.png")
cLEX8.Print("LEX8_ped.C")


cLEX8_err=ROOT.TCanvas("cLEX8_err")
cLEX8_err.SetTicky(1)
cLEX8_err.SetTickx(1)
ghLEX8_err = ROOT.TH2F("ghLEX8_err","",10000,ind[-1]-30,ind[-1],100,0.5,1.5);
ghLEX8_err.SetStats(000)
ghLEX8_err.SetXTitle("MJD")

ghLEX8_err.SetYTitle("Spread of Ped deviation LEX8 (ADC)")
ghLEX8_err.Draw()

tgLEX8_err = ROOT.TGraph(lilen,ind,rmsLEX8)
tgLEX8_err.SetMarkerStyle(2)
tgLEX8_err.Draw('P')

cLEX8_err.Print("LEX8_errped.eps")
cLEX8_err.Print("LEX8_errped.png")
cLEX8_err.Print("LEX8_errped.C")

#~~~~~~~~~ HEX1

cHEX1=ROOT.TCanvas("cHEX1")
cHEX1.SetTicky(1)
cHEX1.SetTickx(1)
ghHEX1 = ROOT.TH2F("ghHEX1","",10000,ind[-1]-30,ind[-1],100,-1,1);
ghHEX1.SetStats(000)
ghHEX1.SetXTitle("MJD")

ghHEX1.SetYTitle("Ped deviation HEX1 (ADC)")
ghHEX1.Draw()

tgHEX1 = ROOT.TGraph(lilen,ind,meanHEX1)
tgHEX1.SetMarkerStyle(20)
tgHEX1.SetMarkerColor(2)
tgHEX1.Draw('P')

cHEX1.Print("HEX1_ped.eps")
cHEX1.Print("HEX1_ped.png")
cHEX1.Print("HEX1_ped.C")

cHEX1_err=ROOT.TCanvas("cHEX1_err")
cHEX1_err.SetTicky(1)
cHEX1_err.SetTickx(1)
ghHEX1_err = ROOT.TH2F("ghHEX1_err","",10000,ind[-1]-30,ind[-1],100,0,1);
ghHEX1_err.SetStats(000)
ghHEX1_err.SetXTitle("MJD")

ghHEX1_err.SetYTitle("Spread of Ped deviation HEX1 (ADC)")
ghHEX1_err.Draw()

tgHEX1_err = ROOT.TGraph(lilen,ind,rmsHEX1)
tgHEX1_err.SetMarkerStyle(2)
tgHEX1_err.Draw('P')

cHEX1_err.Print("HEX1_errped.eps")
cHEX1_err.Print("HEX1_errped.png")
cHEX1_err.Print("HEX1_errped.C")

#~~~~~~~~~ HEX8

cHEX8=ROOT.TCanvas("cHEX8")
cHEX8.SetTicky(1)
cHEX8.SetTickx(1)
ghHEX8 = ROOT.TH2F("ghHEX8","",10000,ind[-1]-30,ind[-1],100,-1,1);
ghHEX8.SetStats(000)
ghHEX8.SetXTitle("MJD")

ghHEX8.SetYTitle("Ped deviation HEX8 (ADC)")
ghHEX8.Draw()

tgHEX8 = ROOT.TGraph(lilen,ind,meanHEX8)
tgHEX8.SetMarkerStyle(20)
tgHEX8.SetMarkerColor(2)
tgHEX8.Draw('P')

cHEX8.Print("HEX8_ped.eps")
cHEX8.Print("HEX8_ped.png")
cHEX8.Print("HEX8_ped.C")

cHEX8_err=ROOT.TCanvas("cHEX8_err")
cHEX8_err.SetTicky(1)
cHEX8_err.SetTickx(1)
ghHEX8_err = ROOT.TH2F("ghHEX8_err","",10000,ind[-1]-30,ind[-1],100,0.5,1.5);
ghHEX8_err.SetStats(000)
ghHEX8_err.SetXTitle("MJD")

ghHEX8_err.SetYTitle("Spread of Ped deviation HEX8 (ADC)")
ghHEX8_err.Draw()

tgHEX8_err = ROOT.TGraph(lilen,ind,rmsHEX8)
tgHEX8_err.SetMarkerStyle(2)
tgHEX8_err.Draw('P')

cHEX8_err.Print("HEX8_errped.eps")
cHEX8_err.Print("HEX8_errped.png")
cHEX8_err.Print("HEX8_errped.C")

os.system('rm listrun')


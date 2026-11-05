
function ini=NAYFES0()
global  INT INB U V W U0 V0 W0 BDX BDY BDZ VLX VLY VLZ 
global ACX ACY ACZ FRX FRY FRZ FX FY FZ MAS MSS CN ENR
global EDG E1 E2 LI DEQB F YNGB GFRB LCRB EPRB EP SS EM
global EN KR KR1 DSS DM FS CAF DT GFR DEQ LCR TEST EST 
global DF DF1 DF2 DMP1 DMP2 TDAF CON M N L M1 N1 L1 MNL
global NNO NNS NNT NBA NBS NBT INCO NCON STEP NSTEP NDAMF
global RUN NRUN LCO TIME TTOT PSN ROH YNG EPR EPMAX EPMIN 
global MEAN  COEV ENEX ENCN ENEL ENGD ENDP ENIN DEN DERIV 
global XB YB ZB UBAR VBAR WBAR REACAOX REACAOY REACAOZ 
global STRAIN STRESS SEED 


%----------------------------------------------------------------------
% Local constants and derived parameters
%----------------------------------------------------------------------
DELTA = 9.0 * PSN / (4.0 - 8.0 * PSN);
ALFA  = (9.0 + 8.0 * DELTA) / (18.0 + 24.0 * DELTA);
%----------------------------------------------------------------------
% Initialize output arrays
%----------------------------------------------------------------------
VLX=zeros(1,NNT);
VLY=zeros(1,NNT);
VLZ=zeros(1,NNT);
ACX=zeros(1,NNT);
ACY=zeros(1,NNT);
ACZ=zeros(1,NNT);
YNGB = ones(1, NBT);
YNGB=YNGB.*YNG;
E1 = ones(1, NBT);
E2 = ones(1, NBT);
GFRB = ones(1, NBT);
GFRB=GFRB.*GFR;
DEQB = ones(1, NBT);
DEQB=DEQB.*DEQ;
ENR =(YNGB.*(LI.^2)).*ALFA;
aux=(2.0*DELTA*(4.0/3.0))/sqrt(3.0);
EDG =  ENR*aux;
LCRB = ones(1, NBT);
LCR = DEQ * 2.0 * CAF / ALFA;
LCRB= LCRB.*LCR;
EPRB =sqrt(GFRB./(YNGB.*DEQB)); 
LMIN= min(LI)
dt_cmin = LMIN/(sqrt(min(YNGB)/ROH));

if dt_cmin < DT
    fprintf('dt_cmin = %g, dt = %g\n', dt_cmin, DT);
    error('NAYFES0: dt_cmin < DT . Execution stopped.');
end
 ini=1;
 end

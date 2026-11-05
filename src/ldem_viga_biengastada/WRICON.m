
function ini=WRICON(fid)
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
%!--------------------------------------------------------------------------
%function WRICON(fid)
% WRICON
% =================
%
%  DATA:  22/03/1993
%  AUTOR: IGNACIO ITURRIOZ
%
%  Esta subrotina grava dados no arquivo CONNAME.
%

fprintf(1, 'entro na wricon\n');

fprintf(fid, '\n');
fprintf(fid, '  ********************* DEM *********************  \n');
fprintf(fid, '\n');
fprintf(fid, '  Discrete Element Method  \n');
fprintf(fid, '\n');
fprintf(fid, '  All Rights Reserved  -  PPGEC / UFRGS  \n');
fprintf(fid, '\n');
fprintf(fid, '           DATA CONTROL OUTPUT           \n');
fprintf(fid, '           *******************           \n');
fprintf(fid, '\n');
fprintf(fid, '  Simulation   =======================>%12d\n', RUN);
fprintf(fid, '\n');

% Fortran FORMAT (A40,I12)  -->  left-justified 40-char label + %12d
fprintf(fid, '%-40s%12d\n', '   Test simulated...................... ', TEST);
fprintf(fid, '%-40s%12d\n', '   Truss modules in X-direction........ ', M1);
fprintf(fid, '%-40s%12d\n', '   Truss modules in Y-direction........ ', N1);
fprintf(fid, '%-40s%12d\n', '   Truss modules in Z-direction........ ', L1);
fprintf(fid, '\n');

fprintf(fid, '%-40s%12d\n', '   Principal nodes number.............. ', NNO);
fprintf(fid, '%-40s%12d\n', '   Symmetry nodes number............... ', NNS);
fprintf(fid, '%-40s%12d\n', '   Total nodes number.................. ', NNT);
fprintf(fid, '%-40s%12d\n', '   Principal bars number............... ', NBA);
fprintf(fid, '%-40s%12d\n', '   Symmetry bars number................ ', NBS);
fprintf(fid, '%-40s%12d\n', '   Total bars number................... ', NBT);
fprintf(fid, '\n');

%--------------------------------------------------------------------------
% Control node numbers (Fortran DO 10 I=1,INCO)
%--------------------------------------------------------------------------
for I = 1:INCO
    fprintf(fid, '%-40s%12d\n', '  Control node number................. ', NCON(I));
end

fprintf(fid, '\n');
fprintf(fid, '\n');

%--------------------------------------------------------------------------
% FORMAT (A40,E12.6)  -->  left-justified 40-char label + %12.6E
%--------------------------------------------------------------------------
fprintf(fid, '%-40s%12.6E\n', '   Initial damping factor.............. ', DF1);
fprintf(fid, '%-40s%12.6E\n', '   Final damping factor................ ', DF2);
fprintf(fid, '%-40s%12.6E\n', '   Time of damping change.............. ', TDAF);
fprintf(fid, '%-40s%12.6E\n', '   Stiffness proportional damping...... ', CON);
fprintf(fid, '\n');
fprintf(fid, '%-40s%12.6E\n', '   Truss module length................. ', LCO);
fprintf(fid, '%-40s%12.6E\n', '   Time increment...................... ', DT);
fprintf(fid, '%-40s%12.6E\n', '   Total time of integration........... ', TTOT);

%--------------------------------------------------------------------------
% Derived quantities
%--------------------------------------------------------------------------
KRN   = LCR / LCO;
DELTA = 9.0 * PSN / (4.0 - 8.0 * PSN);
ALFA  = (9.0 + 8.0 * DELTA) / (18.0 + 24.0 * DELTA);
MASTOT = (M1 * LCO * N1 * LCO * L1 * LCO) * ROH;

fprintf(fid, '\n');
fprintf(fid, '%-40s%12.6E\n', '   Poissons ratio...................... ', PSN);
fprintf(fid, '%-40s%12.6E\n', '   Mass density........................ ', ROH);
fprintf(fid, '%-40s%12.6E\n', '   Total mass.......................... ', MASTOT);
fprintf(fid, '%-40s%12.6E\n', '   Youngs modulus...................... ', YNG);
fprintf(fid, '%-40s%12.6E\n', '   Element normal stiffness............ ', ENR(1));
fprintf(fid, '%-40s%12.6E\n', '   Element diagonal stiffness.......... ', EDG(1));
fprintf(fid, '%-40s%12.6E\n', '   Specific fracture energy............ ', GFR);
fprintf(fid, '%-40s%12.6E\n', '   equivalent d                ........ ', DEQ);
fprintf(fid, '%-40s%12.6E\n', '   Proportionality mean strain......... ', EP(1));
fprintf(fid, '%-40s%12.6E\n', '   Critical value for Lc............... ', LCR);
fprintf(fid, '%-40s%12.6E\n', '   Kr value for normal bars............ ', KRN);
fprintf(fid, '%-40s%12.6E\n', '   Delta coefficient................... ', DELTA);
fprintf(fid, '%-40s%12.6E\n', '   Alfa coefficient.................... ', ALFA);
fprintf(fid, '\n');
fprintf(fid, '%-40s%12.6E\n', '   Maximum value for ep................ ', EPMAX);
fprintf(fid, '%-40s%12.6E\n', '   Minimum value for ep................ ', EPMIN);
fprintf(fid, '\n');

%--------------------------------------------------------------------------
% General remarks section
%--------------------------------------------------------------------------
fprintf(fid, '\n');
fprintf(fid, '             GENERAL REMARKS             \n');
fprintf(fid, '             ***************             \n');
fprintf(fid, '\n');
fprintf(fid, '%-40s%12.6E\n', '   Mean ep............................. ', MEAN);
fprintf(fid, '%-40s%12.6E\n', '   Coefficient of variation for ep..... ', COEV);
fprintf(fid, '\n');

fprintf(fid, '\n');

ini=1;
 end

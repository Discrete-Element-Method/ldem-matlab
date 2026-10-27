
function ini=BOUND()
% BOUND  Determina as condições de contorno da estrutura.
% Deve ser adaptada para cada exemplo testado.
global  INT INB U V W U0 V0 W0 BDX BDY BDZ VLX VLY VLZ 
global ACX ACY ACZ FRX FRY FRZ FX FY FZ MAS MSS CN ENR
global EDG E1 E2 LI DEQB F YNGB GFRB LCRB EPRB EP SS EM
global EN KR KR1 DSS DM FS CAF DT GFR DEQ LCR TEST EST 
global DF DF1 DF2 DMP1 DMP2 TDAF CON M N L M1 N1 L1 MNL
global NNO NNS NNT NBA NBS NBT INCO NCON STEP NSTEP NDAMF
global RUN NRUN LCO TIME TTOT PSN ROH YNG EPR EPMAX EPMIN 
global MEAN  COEV ENEX ENCN ENEL ENGD ENDP ENIN DEN DERIV 
global XB YB ZB UBAR VBAR WBAR REACAOX REACAOY REACAOZ 
global STRAIN STRESS SEED DM FS

%!  Esta subrotina determina as condições de contorno da estrutura.

%!--------------------------------------------------------------------------

 
BDX=zeros(NNT,1);
BDY=zeros(NNT,1);
BDZ=zeros(NNT,1);
%!--------------------------------------------------------------------------
%!     ADAPTAR PARA CADA EXEMPLO TESTADO
%!--------------------------------------------------------------------------
%!

  
if TEST == 101
    
    % Masks for the two conditions (operate on all elements at once)
    mask1 = (U0 < (0.51 * LCO)) & (U0 > (0.49 * LCO));
    mask2 = (U0 > (M1 - 0.51 * LCO)) & (U0 < (M1 - 0.49 * LCO));
    
    % Apply BDX=1 where either condition is true
    BDX(mask1 | mask2) = 1;
    
end

if TEST == 102
    
    % --- First block of conditions (replaces the first loop) ---
    mask1 = (V0 > (0.49 * LCO)) & (V0 < (0.51 * LCO)) & ...
            (U0 < (4.51 * LCO)) & (U0 > (4.49 * LCO));
    
    mask2 = (U0 > ((M1 - 4.51) * LCO)) & (U0 < ((M1 - 4.49) * LCO)) & ...
            (V0 < (0.51 * LCO)) & (V0 > (0.49 * LCO));
    
    % Apply the assignments
    BDX(mask1) = 1;
    BDY(mask1) = 1;
    BDY(mask2) = 1;  % Originally BDy -> unified to BDY (Fortran is case-insensitive)
    
    
    % --- S econd block of conditions (replaces the second loop) ---
    mask3 = (U0 < ((M1 - 33.49) * LCO)) & (U0 > ((M1 - 33.51) * LCO)) & ...
            (V0 < ((N1 - 0.49) * LCO)) & (V0 > ((N1 - 0.51) * LCO));
    
    mask4 = (U0 < (33.51 * LCO)) & (U0 > (33.49 * LCO)) & ...
            (V0 < ((N1 - 0.49) * LCO)) & (V0 > ((N1 - 0.51) * LCO));
    
    % Apply BDY=1 where mask3 or mask4 are true
    BDY(mask3 | mask4) = 1;
    

  ini=1;
 end

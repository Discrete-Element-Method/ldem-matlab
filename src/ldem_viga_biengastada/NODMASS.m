
function ini=NODMASS()
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

%!  Esta subrotina determina as condições de contorno da estrutura.
%
% !  Esta subrotina calcula a massa nodal, baseada no volume de influência
% !  de cada nó.
MSS=ones(1,NNT);
MSS=MSS.*(LCO*LCO*LCO*ROH/2.0D00);
MAS=ones(1,NNT);
VLX=zeros(1,NNT);

% 
%         DO I=1,NNT
%           MSS(I)=LCO*LCO*LCO*ROH/2.0D00
%         END DO
% !
    
% !--------------------------------------------------------------------------
%       DO 10 K=1,L
%       DO 10 J=1,N
%       DO 10 I=1,M
%       RED=1.0D00
%       IF ((K.EQ.1).OR.(K.EQ.L)) RED=RED/2.0D00
%       IF ((J.EQ.1).OR.(J.EQ.N)) RED=RED/2.0D00
%       IF ((I.EQ.1).OR.(I.EQ.M)) RED=RED/2.0D00
%       NO=(K-1)*M*N+(J-1)*M+I
%       MAS(NO)=RED*MSS(NO)
%    10 CONTINUE
% !
%       DO 20 K=1,L1
%       DO 20 J=1,N1
%       DO 20 I=1,M1
%       NO=MNL+(K-1)*M1*N1+(J-1)*M1+I
%       MAS(NO)=MSS(NO)
%    20 CONTINUE
% !

% Create 3D grids of indices
[I, J, K] = ndgrid(1:M, 1:N, 1:L);   % I varies fastest (first dimension)

% Count how many boundaries the point lies on
boundaryCount = (K == 1 | K == L) + (J == 1 | J == N) + (I == 1 | I == M);
RED = 2 .^ (-boundaryCount);          % RED = 1/2^count

% Linear index in column-major order (same formula)
NO = (K-1)*M*N + (J-1)*M + I;

% Assign scaled values
MAS(NO) = RED .* MSS(NO);

% Generate indices for the second region
[I, J, K] = ndgrid(1:M1, 1:N1, 1:L1);
NO = MNL + (K-1)*M1*N1 + (J-1)*M1 + I;
MAS(NO) = MSS(NO);
%      RETURN
%      END


  ini=1;
 end

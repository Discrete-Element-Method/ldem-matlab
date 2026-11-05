
function ini=RMECDI()
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
%  SUBROUTINE RMECDI
% !     =================
% !
% !  Esta subrotina é chamada pela subrotina rmec para definir as
% !  propriedades mecânicas das barras diagonais dos módulos cúbicos.
% !
% !--------------------------------------------------------------------------
%       PARAMETER (INN=1.2E6,INB=6E6,IRU=6,INCON=10)
% !--------------------------------------------------------------------------
% !     DEFINIÇÃO DE VARIÁVEIS E GRUPOS COMUNS
%       INCLUDE 'COMMON.FOR'
% !--------------------------------------------------------------------------
%       INTEGER G,I,J,K,NOI,NOF,B,ST(8),REF,NOFF
% !--------------------------------------------------------------------------
%       REF=NBA
%       ST(1)=0
%       ST(2)=1
%       ST(3)=M
%       ST(4)=M+1
%       ST(5)=N*M
%       ST(6)=N*M+1
%       ST(7)=N*M+M
%       ST(8)=N*M+M+1
% !
%       DO 20 K=1,L1
%       DO 20 J=1,N1
%       DO 20 I=1,M1
%       NOI=(K-1)*M1*N1+(J-1)*M1+I
%       NOF=(K-1)*M*N+(J-1)*M+I
%       B=REF+(NOI-1)*8
%       NOI=NOI+MNL
%       DO 10 G=1,8
%       B=B+1
%       NOFF=NOF+ST(G)
% !
%       CALL DEFEP(B,3)
% !
%    10 CONTINUE
% !
%       NBA=NBA+8
% !
%    20 CONTINUE
% !
%       RETURN
%       END
% !
% Local variables
%--------------------------------------------------------------------------
%ST = zeros(1, 8);   % 1-based indexing matches Fortran's ST(1..8)
%--------------------------------------------------------------------------
% Reference offset and ST table
%--------------------------------------------------------------------------

% MODIFICAÇÕES RODRIGO
REF = NBA;
ST = [0, 1, M, M+1, N*M, N*M+1, N*M+M, N*M+M+1];

%--------------------------------------------------------------------------
% Outer nest: K (outer), J (middle), I (inner) -- all share label 20
%--------------------------------------------------------------------------
for K = 1:L1
        for J = 1:N1
            for I = 1:M1
                NOI = (K - 1) * M1 * N1 + (J - 1) * M1 + I;
                B   = REF + (NOI - 1) * 8;
                
                for G = 1:8
                    B = B + 1;
                    E1(B) = EDG(B); % Lógica embutida do DEFEP
                end
                NBA = NBA + 8;
            end
        end
    end
    ini = 1;
end
